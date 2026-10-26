---
name: odoo-module-migration
description: Migrate an Odoo custom or OCA module to a newer version using OCA conventions
allowed-tools: Read Edit Write Grep Glob Bash WebFetch
---

Migrate an Odoo module from one version to another following OCA migration
conventions. Work through the steps autonomously; only stop to ask the user
when an input cannot be inferred, a dependency blocks the migration, or a step
explicitly requires permission.

## Inputs

Resolve these before doing anything else:

- `<module-path>` — the module to migrate. If the user gave a path or name, use
  it; otherwise locate it under the project's addons paths.
- `<source>` — source version. Default: the major version in
  `__manifest__.py` (`14.0.3.0.0` → `14.0`).
- `<target>` — target version. Default: the currently checked-out Odoo branch,
  else the highest remote version branch (e.g. `19.0`).
- Module type — determines which optional steps apply:
  - **OCA** — the module lives in (or is destined for) an OCA repository:
    fork + format-patch history port, README regeneration, `[MIG]` commit
    convention, and PR to OCA all apply.
  - **Custom** — project repository or vendored addons dir (e.g.
    `src/private-addons`): skip the fork, history port, README regeneration,
    and OCA commit/PR conventions. Everything else is identical.

## Preflight

1. **Check dependencies.** Every module in `depends` must exist for `<target>`
   (in core or in the target OCA repository). List any missing ones for the
   user before proceeding — a missing dependency will block installation at
   the verification step, so surface it now rather than late.
2. **Fetch the OCA migration guide** for `<target>`:
   `https://github.com/OCA/maintainer-tools/wiki/Migration-to-version-<target>.0`.
   If that page does not exist, use the closest lower version and note the gap
   in the final report.
3. **Fetch OpenUpgrade analyses** for data-model and ORM changes:
   `https://github.com/OCA/OpenUpgrade/tree/<target>.0/openupgrade_scripts/scripts/<module>/<module-version>/upgrade_analysis.txt`
   - Read the analysis for `<module>` itself if OpenUpgrade covers it, and for
     every core/OCA dependency module whose models the code touches (fields
     renamed there break this module).
   - If OpenUpgrade has no entry for a module, fall back to the wiki plus
     greps of this module's code against the target source for the models it
     uses.
   - When jumping more than one release (e.g. 14.0 → 19.0), repeat for every
     intermediate version (15, 16, 17, 18, 19).

## Migration steps

### 1. Prepare the working branch

Only in a git-tracked repository. If the module lives in a submodule, create
the branch in the submodule first.

- **Custom:** `git checkout -b <target>.0-mig-<module>` — or work directly on
  the module's existing single-version branch if it has one.
- **OCA:** fork the upstream repository and port the module's git history:
  ```bash
  git clone https://github.com/$user_org/$repo.git
  cd $repo
  git remote add upstream https://github.com/OCA/$repo.git
  git fetch upstream
  git checkout -b <target>.0-mig-<module> upstream/<target>.0
  git format-patch --keep-subject --stdout upstream/<target>.0..upstream/<source>.0 -- <module-path> | git am -3 --keep
  ```
  - The `-- <module-path>` filter is required: OCA version branches have
    unrelated history, so only commits touching the module can be ported.
  - Never push the migration branch to upstream OCA — always to your fork.
  - If `git am` fails, resolve conflicts and `git am --continue`, or
    `git am --abort` and copy the module files without history.
  - If the module was renamed or moved, rewrite the history to the target
    path with `git-filter-repo`.

### 2. Bump the manifest and boilerplate

- Set `version` in `__manifest__.py` to `<target>.0.1.0.0` (or preserve the
  business major/minor/patch if the project uses one).
- Ensure `installable` is `True` — OCA marks unmigrated modules
  `installable: False` on the target branch, so restore it when porting.
- Update `license`, `author`, `website`, `depends` only if the target
  conventions require it.
- OCA only: regenerate `README.rst` and `static/description/index.html` with
  `oca-gen-addon-readme`; update the root `README.md` addons table and
  `setup/_metapackage/pyproject.toml` if the repo uses them.
- These boilerplate changes go in the migration commit but are not listed in
  the commit message.

### 3. Remove previous migration scripts

Delete the module's `migrations/` folder — it contains scripts written for the
previous version jump. If this migration needs upgrade scripts, write fresh
ones for `<source>` → `<target>` under `migrations/<target>.0.1.0.0/`; do not
port old scripts forward.

### 4. Run automatic migration tooling when available

- `odoo-module-migrator` (OCA-style repos):
  ```bash
  odoo-module-migrate --directory <repo> --modules <module> --init-version-name <source> --target-version-name <target>
  ```
- `oca-port` — when the module already exists on the target branch, dry-run
  first:
  ```bash
  oca-port origin/<source>.0 origin/<target>.0 <module-path> --verbose --dry-run
  ```

### 5. Apply generic code transformations

Apply only the transformations introduced between `<source>` and `<target>` —
the version markers indicate when each became required:

- (V9+) Rename `__openerp__.py` → `__manifest__.py`; `import openerp` →
  `import odoo`; `select=True` → `index=True`.
- (V11+) Remove `# -*- encoding: utf-8 -*-` shebangs.
- Convert `<act_window>`, `<report>`, and `<record>`-based menu actions to
  their modern equivalents.
- Replace string/XML selectors with `name` or other stable selectors.
- Migrate `attrs`/`states` to the inline `invisible`/`readonly`/`required`
  expression syntax.

### 6. Apply target-version changes from the wiki and OpenUpgrade

- For each breaking change in the target wiki page, grep the module for the
  affected pattern and update it.
- For field/method renames found in `upgrade_analysis.txt`, grep the module's
  Python, XML, and test files for the old names — test data dictionaries are a
  common breakage point (e.g. `product_uom` → `product_uom_id` in 19.0).
- Consult the official Odoo skills (`odoo-guidelines`, `odoo-web-guidelines`,
  `odoo-security`) for current code idioms — read them from the `master`
  branch on GitHub (`https://github.com/odoo/odoo/tree/master/skills/`); they
  only exist starting with Odoo 20.
- Pay special attention to:
  - ORM method renames/removals (`_auto`, `env.ref`, `_compute_` patterns,
    `unlink`, `write` constraints).
  - Field renames on `sale.order.line` and `purchase.order.line`
    (`product_uom`, `product_uom_qty`, `price_unit` changes across versions).
  - View architecture changes (`kanban`, `list`/`tree`, `form`, `search`,
    `widget` changes).
  - Security changes (`ir.model.access.csv`, record rules, group names).
  - Report/QWeb changes.

### 7. Check Python and XML compatibility

- Grep for deprecated API calls: `api.one`, `api.returns`, `api.cr_uid`,
  `api.cr_uid_ids`, `browse_ref`, `self.env['ir.values']`, `sudo()` with raw
  `env.cr`, etc.
- In `logging` calls, do not use f-strings — use `%`-style interpolation with
  values as extra args so messages stay lazy and aggregation-friendly:
  ```python
  _logger.info("Processed %s records for partner %s", len(records), partner.name)
  ```
- Verify every `external_id` reference still exists in target core/OCA
  modules.
- Update `noupdate` flags if defaults changed.

### 8. Run pre-commit

- `pre-commit run -a` in the module directory or repository root.
- If `.pre-commit-config.yaml` pins a Python version that is not installed,
  create a temporary copy with a matching version and run
  `pre-commit -c <temp-config> run -a`; revert the temp config afterwards.
- Fix formatting, lint, and license/copyright headers. Review auto-generated
  fixes before committing them.

### 9. Verify: install and run tests

- Preferred: install on a real target-version environment
  (`osh odoo -i <module> --stop`, `odoo-bin -i <module> --stop`, or the
  project's `pytest` setup), then run the module's tests.
- If no Odoo environment is available, still run a minimum sanity check —
  compile the Python and parse every XML file:
  ```bash
  python -m compileall -q <module-path>
  find <module-path> -name '*.xml' -exec xmllint --noout {} +
  ```
  and state clearly in the report that install/test verification was skipped.
- On any failure, trace the root cause, fix it, amend the migration commit,
  and retry.

### 10. Commit

- OCA convention:
  ```
  [MIG] <module>: Migration to <target>.0

  Port <module> from <source>.0 to <target>.0.

  <One or two real migration changes, e.g. a field rename or API change.>

  Assisted-by: HARNESS:MODEL
  ```
- Custom modules: use the project's convention — typically
  `<module>: migrate to <target>.0` (module name as topic, release-note style
  title). Same `Assisted-by: HARNESS:MODEL` trailer.
- Do not list obvious changes (manifest bump, README/index regeneration,
  metapackage updates) in the message — those files stay in the commit, but
  the message focuses on non-obvious code changes.
- Amend fixes into the migration commit (`git commit --amend`); do not stack
  fixup commits. If an earlier commit needs changing, use `git rebase --onto`
  or a soft reset — interactive `git rebase -i` is unavailable to
  non-interactive agents.
- The human must be the commit author. Verify `git log -1` has no unwanted
  `Co-Authored-By` trailer (remove it if a git wrapper injected one); use only
  `Assisted-by: HARNESS:MODEL`, substituting the real harness and model.

### 11. Open a pull request — ask the user for permission first

- OCA: push to the fork (`git push -u origin <target>.0-mig-<module>`) and
  open a PR to `OCA/$repo:<target>.0` titled
  `[MIG] <module>: Migration to <target>.0`. The description summarizes the
  non-obvious changes, references the OCA wiki page, and lists TODOs/warnings.
  - Include a dependency checklist: any `depends` modules not yet migrated to
    `<target>` are unchecked items.
  - If `gh`/PR creation fails on token scope, do not push to OCA. Give the
    user a compare URL
    (`https://github.com/OCA/$repo/compare/<target>.0...$user:$repo:<target>.0-mig-<module>?expand=1`)
    and a ready-to-copy title/description.
- Custom: push to the project repository and open a PR against its main/target
  branch if the team reviews that way; otherwise follow the project workflow.

## Output

Provide a concise report including:

- The module path and the `<source>` → `<target>` migration performed.
- The OCA wiki page(s) and OpenUpgrade analyses consulted (or their absence).
- Key code or view changes made.
- Verification performed — install/tests, or degraded-mode checks only.
- Remaining TODOs, warnings, or manual checks for the user.
- The final manifest version.
