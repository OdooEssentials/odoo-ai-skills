---
name: odoo-module-migration
description: Migrate an Odoo custom or OCA module to a newer version using OCA conventions
argument-hint: "<module-path> <source-version> <target-version>"
allowed-tools:
  - Read
  - Edit
  - Write
  - Grep
  - Glob
  - Bash
  - WebFetch
---

Migrate an Odoo module from one version to another. Follow the OCA migration conventions and use the OCA maintainer-tools Wiki for version-specific changes.

## Before you start

1. Identify the module to migrate:
   - If the user provided `<module-path>`, use it.
   - Otherwise, find the module by name under the Odoo addons paths.

2. Determine versions:
   - Default source = the version declared in `__manifest__.py` (e.g., `14.0.3.0.0` → `14.0`).
   - Default target = the currently checked-out Odoo branch or the highest remote version branch (e.g., `19.0`).

3. Determine the module type:
   - **OCA module**: lives in (or is destined for) an OCA repository — full fork/format-patch/PR workflow applies.
   - **Custom/private module**: lives in a project repository or vendored addons dir (e.g., `src/private-addons`) — skip the OCA fork and PR steps; the rest of the migration process is identical.

4. Fetch the OCA migration guide for the target version from:

   - `https://github.com/OCA/maintainer-tools/wiki/Migration-to-version-<target>.0`
   - If the exact page does not exist, use the closest lower version and mention the gap.

5. Use OpenUpgrade `upgrade_analysis.txt` files to learn data model and ORM changes:
   - `https://github.com/OCA/OpenUpgrade/tree/<target>.0/openupgrade_scripts/scripts/<module>/` — pick the subdirectory matching the module's version on the source branch (e.g., `account/19.0.1.0/upgrade_analysis.txt`).
   - Check also successive versions if the migration jumps more than one release (e.g., 14.0 → 19.0 requires looking at 15, 16, 17, 18, and 19).

## Migration steps

1. **Prepare the working branch** (only in a git-tracked repository):
   - **OCA module** — fork the upstream repository and port the module's git history:
     - Fork the upstream OCA repository on GitHub (e.g., `https://github.com/OCA/$repo`) to your personal or organization account (`$user_org`).
     - Clone the fork locally and add the upstream remote:
       ```
       git clone https://github.com/$user_org/$repo.git
       cd $repo
       git remote add upstream https://github.com/OCA/$repo.git
       ```
     - Fetch the origin version branches from the upstream remote:
       ```
       git fetch upstream
       ```
     - Create the migration branch from the target upstream branch:
       ```
       git checkout -b <target>.0-mig-<module> upstream/<target>.0
       ```
     - Port the module's git history from the source branch using the `git format-patch` workflow from the OCA migration wiki:
       ```
       git format-patch --keep-subject --stdout upstream/<target>.0..upstream/<source>.0 -- <module-path> | git am -3 --keep
       ```
       - The `-- <module-path>` filter is required: OCA version branches have unrelated history (`git merge-base upstream/<target>.0 upstream/<source>.0` is empty), so only commits touching the module can be ported.
       - Never push the migration branch directly to the upstream OCA repository. Always push to your fork.
       If the patch application fails, resolve the conflicts manually, continue with `git am --continue`, or abort with `git am --abort` and copy the source module files without history.
     - If the module was renamed or moved from a different repository structure, use `git-filter-repo` to rewrite the history to the target module path, following the `git-filter-repo` documentation.
   - **Custom/private module** — no upstream to fork or port history from:
     ```
     git checkout -b <target>.0-mig-<module>
     ```
     Work on the project repository's own branch (or the submodule's branch, see below). If the module lives on a single-version branch, just work there directly.
   - If the module is in a submodule, handle the submodule branch first.

2. **Bump the manifest version and boilerplate**:
   - In `<module-path>/__manifest__.py` set `version` to `<target>.0.1.0.0` (or preserve the patch/major/minor business version if applicable).
   - Ensure `installable` is `True` — OCA convention marks unmigrated modules `installable: False` on the target branch, so restore it when porting.
   - Update `license`, `author`, `website`, and `depends` only if required by the target conventions.
   - OCA-style repos only: regenerate `<module-path>/README.rst` and `<module-path>/static/description/index.html` with `oca-gen-addon-readme`, and update the root `README.md` addons table and `setup/_metapackage/pyproject.toml` if the repo uses them.
   - These boilerplate changes are part of the migration commit but should not be listed in the commit message.

3. **Remove previous migration scripts**:
   - Delete the `migrations/` folder inside the module. New migration scripts should be generated from the source database, not kept from the old version.

4. **Run automatic migration tooling when available**:
   - If `odoo-module-migrator` is installed and the project is OCA-style, run:
     ```
     odoo-module-migrate --directory <repo> --modules <module> --init-version-name <source> --target-version-name <target>
     ```
   - If `oca-port` is installed and the module already exists on the target branch, run a dry-run first:
     ```
     oca-port origin/<source>.0 origin/<target>.0 <module-path> --verbose --dry-run
     ```

5. **Apply generic code transformations**:
   - Rename `__openerp__.py` to `__manifest__.py` if still present.
   - Replace `import openerp` / `from openerp` with `import odoo` / `from odoo`.
   - Remove `# -*- encoding: utf-8 -*-` shebangs (V11+).
   - Remove `select=True` in fields; use `index=True` (V9+).
   - Convert `<act_window>`, `<report>`, and `<record>`-based menu actions to the modern equivalents.
   - Replace string/XML selectors by `name` or other stable selectors.
   - Update `attrs`, `states`, `invisible`, `readonly`, and `required` attributes to use `readonly`, `required`, `invisible` with the new expression syntax where applicable.

6. **Address target-version changes from the OCA wiki and OpenUpgrade**:
   - For each breaking change listed in the target wiki page, grep the module for affected patterns and update them.
   - Check the OpenUpgrade `upgrade_analysis.txt` for the target version (and any intermediate versions when jumping more than one release) for field renames and ORM changes. Grep the module's Python and test files for the old field names.
   - Consult the official Odoo skills (`odoo-guidelines`, `odoo-web-guidelines`, `odoo-security`) for current code idioms — read them from the `master` branch on GitHub: `https://github.com/odoo/odoo/tree/master/skills/` (they only exist starting with Odoo 20, so a local Odoo checkout has them only if it is a master/20.0+ checkout).
   - Example of the kind of change to look for: in Odoo 19.0, `sale.order.line.product_uom` was renamed to `product_uom_id` (apply in both model code and test data dictionaries). Check the wiki/analysis for *your* target version — do not assume a specific rename applies to other versions.
   - Pay special attention to:
     - ORM method renames/removals (`_auto`, `env.ref`, `_compute_` patterns, `unlink`, `write` constraints).
     - Field renames on `sale.order.line` and `purchase.order.line` (e.g., `product_uom`, `product_uom_qty`, `price_unit` changes across versions).
     - View architecture changes (`kanban`, `tree`, `form`, `search` templates, `widget` changes).
     - Security changes (`ir.model.access.csv`, record rules, group names).
     - Report/QWeb changes.

7. **Check Python and XML compatibility**:
   - Use `grep` to find deprecated API calls (e.g., `api.one`, `api.returns`, `api.cr_uid`, `api.cr_uid_ids`, `sudo()` with `env.cr` patterns, `browse_ref`, `self.env['ir.values']`, etc.).
   - In `logging` calls, do **not** use f-strings. Use `%`-style string interpolation with values passed as extra `*args`, e.g.:
     ```python
     _logger.info("Processed %s records for partner %s", len(records), partner.name)
     ```
     This keeps log messages lazy-evaluated and friendly to log aggregation/Sentry.
   - Verify `external_id` references still exist in target core/OCA modules.
   - Update `noupdate` flags if defaults changed.

8. **Run pre-commit**:
   - `pre-commit run -a` in the module directory (or repository root).
   - If the repo's `.pre-commit-config.yaml` references a Python version that is not installed (e.g., `python: python3.12` while only `python3.10` is available), create a temporary copy with a matching Python version and run `pre-commit -c <temp-config> run -a`. Revert the temporary config when done.
   - Fix formatting, lint, and any license/copyright headers reported.
   - Do not commit auto-generated fixes until you have reviewed them.

9. **Test installation and run the module tests**:
   - Try to install the module with the target Odoo version, using the local tooling available (`osh odoo -i <module> --stop` or `odoo-bin -i <module> --stop` or `pytest` if the project has tests).
   - Run the module's tests; test data dictionaries are a common place for renamed fields (e.g., `product_uom` vs `product_uom_id`) to break.
   - If installation or tests fail, trace the error to the root cause, fix it, amend the migration commit, and retry.

10. **Commit**:
    - OCA-style repository, use the OCA migration commit convention:
      ```
      [MIG] <module>: Migration to <target>.0
      
      Port <module> from <source>.0 to <target>.0.
      
      <One or two real migration changes, e.g. a field rename or API change.>
      
      Assisted-by: HARNESS:MODEL
      ```
    - Custom/private module: use the project's commit convention — typically `<module>: migrate to <target>.0` (module name as topic, release-note style title). The same `Assisted-by: HARNESS:MODEL` trailer applies.
    - Do **not** list obvious changes such as manifest version bumps, `README.rst`/index regeneration, or root README/metapackage updates in the commit message. Those files are still part of the migration commit, but the message should focus on the non-obvious code changes.
    - Any fixes discovered during migration should be amended into this migration commit (`git commit --amend`), not added as new commits. If an earlier commit needs changing, use `git rebase --onto` or a soft reset — interactive `git rebase -i` is not available to non-interactive agents.
    - The human (e.g., the user) must be the commit author. Verify `git log -1` does not contain an unwanted `Co-Authored-By` trailer; remove it if it was auto-injected by a git wrapper. Only use `Assisted-by: HARNESS:MODEL` to disclose AI assistance, replacing `HARNESS:MODEL` with the actual harness and model identifier.

11. **Open a pull request** — ask the user for permission first:
    - OCA module: push the migration branch to the fork (`git push -u origin <target>.0-mig-<module>`) and open a PR to `OCA/$repo:<target>.0` with the title `[MIG] <module>: Migration to <target>.0`. The description summarizes the non-obvious migration changes, references the OCA wiki page, and lists any TODOs or warnings.
      - Include a dependency checklist in the PR description. If any module dependencies have not yet been migrated to the target version, list them as unchecked checklist items; otherwise mark them complete.
      - If `git_create_pr`/`gh` fails due to token scope (`Resource not accessible by personal access token`), do not push to OCA. Provide the user with a compare URL (`https://github.com/OCA/$repo/compare/<target>.0...$user:$repo:<target>.0-mig-<module>?expand=1`) and ready-to-copy title/description so they can open the PR manually.
    - Custom/private module: push to the project repository and open a PR against its main/target branch if the team reviews that way; otherwise follow the project's own workflow.

## Output

Provide a concise report that includes:
- The module path and version migration performed.
- The OCA wiki page(s) consulted.
- Key code or view changes made.
- Any remaining TODOs, warnings, or manual checks the user should handle.
- The final manifest version.
