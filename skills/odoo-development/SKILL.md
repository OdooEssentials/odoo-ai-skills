---
name: odoo-development
description: Day-to-day Odoo development workflows — running module tests efficiently, updating modules, and verifying changes on local databases
---

# Odoo Development

Local development workflows for Odoo addons: module update/install commands and
how to run tests without paying for the full core suite.

Commands below are shown with `odoo-bin`; substitute the project's wrapper when
one exists (e.g. `osh odoo` inside an osh-managed environment, or a
docker-compose `exec`).

## Running tests on a new database — install first, test second

`--test-enable` runs the tests of **every module loaded during the run**. On a
database that does not exist yet, `odoo -i <module> --test-enable` initializes
the DB *and* installs the module's whole dependency tree — so the test suite of
`base`, `web`, `bus`, `mail`, `stock`, and every other dependency also runs.
That can take tens of minutes before the target module's tests even start.

Instead, split it into two runs:

```bash
# 1. Create/initialize the database and install the module + dependencies.
#    No tests run.
odoo-bin -d <db> -i <module> --stop-after-init

# 2. Now update only the target module with tests enabled.
#    Only that module's tests run; dependencies are already loaded.
odoo-bin -d <db> -u <module> --test-enable --stop-after-init
```

With `osh`, the equivalent is `osh odoo -i <module> --stop` then
`osh odoo -u <module> --test-enable --stop`.

The same applies to an existing database: `-u <module> --test-enable` only runs
the tests of the module being updated, so keep runs scoped to the module under
test.

## Filtering further with --test-tags

When even the module's own suite is too broad, `--test-tags` selects a subset:

- `/<module>` — all tests of a module
- `/<module>:<ClassName>` / `/<module>:<ClassName>.<test_method>` — one class or
  one test
- `<tag>` — tests tagged with `@tagged('tag')`

Example:

```bash
odoo-bin -d <db> -u <module> --test-enable \
    --test-tags /yok_edi_magistor:TestMagistorPickingFiles --stop-after-init
```

`--test-tags` can be combined with `-u`; the update still happens, only the test
selection narrows.

## Verifying changes without tests

- Schema/model changes (new fields, models) require `-u <module>` to take
  effect — a service restart alone is not enough.
- Python code changes in existing files only need a restart (`--dev=reload` or
  `odoo-bin -u` is not required).
- XML/data/view changes require `-u <module>` unless `--dev=xml` is active, in
  which case view `arch` is re-read from files at request time.

## RED–fix–GREEN for bug fixes

1. Write the failing test first and run it against the unfixed code — confirm it
   fails for the right reason (RED).
2. Apply the minimal fix.
3. Re-run the same test and confirm it passes (GREEN).

Keep both runs' log excerpts (the failing assertion and the passing result) as
evidence — paste them into the commit message or PR description when relevant.

## Commit guidelines

- Only commit when explicitly requested.
- Structure: `topic: user-facing release-note style title`. For Odoo addon
  changes, the topic is the module name — e.g. `sale_order: add confirmation
  email on delivery`. Focus the message on *why*, not *what*.
- One commit per logical change. Changes in different modules go in separate
  commits.
- The human is the commit author. The only attribution trailer allowed is
  `Assisted-by: AGENT:MODEL` (one line per model used) — never
  `Co-Authored-By`, `Generated-by`, or `Signed-off-by`.
- Before committing a non-trivial change, do a review pass on the full diff:
  check for bugs, scope creep, and unintended file inclusions.

### Squash iterative fixes before publishing

Test fixes, lint fixes, and CI fixups are part of the feature commit — the
published branch must not contain `fix test`, `fix CI`, or `fixup` commits.

- Fix the most recent commit: `git commit --amend`.
- Fix an earlier commit: soft reset and recommit, or `git rebase --onto`.
  Interactive `git rebase -i` is not available to non-interactive agents — do
  not use it.

## Pre-commit etiquette (OCA-style repos)

1. Never hand-edit generated files (`README.rst`,
   `static/description/index.html`, the root `README.md` addons table,
   `requirements.txt`): run `pre-commit run -a` and let the hooks regenerate
   them, then include the result in the commit.
2. Commit related changes before running `pre-commit run -a`. Hooks stash
   unstaged changes; when unstaged edits overlap files the hooks rewrite
   (e.g. generated READMEs), the stash restore can silently drop your edits.
3. Do not "fix" intermediate commits to satisfy the hooks. When replaying a
   module's history (cherry-pick / `git am`), older commits legitimately carry
   versions or syntax that the current branch's hooks reject (e.g.
   pylint-odoo's manifest-version check). Bypass hooks for those replayed
   commits (`git -c core.hooksPath=/dev/null ...`) and let the final state
   pass the full hook suite.
4. Review hook auto-fixes before committing them; re-run `pre-commit run -a`
   until it is fully green before pushing.
