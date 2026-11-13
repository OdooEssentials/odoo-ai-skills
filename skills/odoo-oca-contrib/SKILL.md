---
name: odoo-oca-contrib
description: Contribute changes to OCA addon repositories (e.g. OCA/e-commerce) — fork/PR workflow, module scaffolding, readme fragments, generated files, pre-commit setup, and version conventions. Use when opening or preparing a PR against an OCA repo. Commit message format is covered by the odoo-git skill.
---

# OCA contribution workflow

How to prepare and submit changes to OCA addon repositories such as
`OCA/e-commerce`, `OCA/stock-logistics-workflow`, etc. For commit message
format, branch naming and PR hygiene see the `odoo-git` skill — OCA uses
the same `[TAG] scope: summary` conventions.

## Repository setup

- **Never push to the OCA organization remote.** Work on a personal fork
  (`<user>/<repo>`), push branches there, and open PRs fork → upstream
  (`OCA/<repo>:<version-branch>`).
- Add both remotes in the working clone:

  ```bash
  git remote add upstream https://github.com/OCA/<repo>.git   # fetch/PR target only
  git remote add fork     https://github.com/<user>/<repo>.git
  ```

- OCA repos are large monorepos of addons. Create a git worktree per PR in
  a sibling directory (`<repo>-<topic>`) rather than switching the main
  checkout, which may be a live dev environment:

  ```bash
  git worktree add ../<repo>-<topic> -b <version>-<topic> upstream/<version>
  ```

  Branch names follow `<target>-<topic>` (e.g. `19.0-fix-module-readme`).

## pre-commit on new clones and worktrees

OCA repos ship a `.pre-commit-config.yaml` that reviewers expect to pass.

- **Fresh clone:** run `pre-commit install` once so hooks run on commit.
- **New worktree:** hooks are shared through the common git dir, but the
  hook environments are per-checkout cache — run
  `pre-commit install --install-hooks` (or just `pre-commit run --all-files`
  once) in the worktree to populate them.
- The config typically includes `oca-gen-addon-readme` (regenerates
  `README.rst` and `static/description/index.html` from `readme/`
  fragments), `whool` checks, prettier for XML, and ruff/pylint for
  Python.

## Module scaffolding

- New modules are scaffolded with `whool-init` (from `oca-addons-repo-template`),
  which generates `__manifest__.py`, `__init__.py`, readme fragments,
  `pyproject.toml`, and `static/description/` assets. Do not hand-write
  these files.
- `auto_install` modules (e.g. bridge modules that activate when two
  dependencies coexist) need no extra wiring beyond the manifest flag.

## Readme fragments — the only docs you edit

Module documentation lives in `readme/` fragments (`DESCRIPTION.md`,
`CONFIGURE.md`, `USAGE.md`, `CONTRIBUTORS.md`, `ROADMAP.md`,
`CREDITS.md`). The rendered `README.rst` and `static/description/index.html`
are **generated** — never edit them directly.

- Edit only the fragments; the `oca-gen-addon-readme` pre-commit hook
  regenerates the outputs. Commit the regenerated files together with the
  fragment changes.
- Before pushing, verify the generated files are in sync:
  `pre-commit run --files <module>/` should report no modifications.

## Version and metadata conventions

- **Do not bump `__manifest__.py` `version`** — the ocabot bumps versions
  at merge time. The only exception is when the change ships migration
  scripts (`migrations/<version>/`), which require the target version to
  be declared.
- Keep module metadata accurate: `summary`, `author`,
  `development_status`, `category`, `depends`, `auto_install`.
- New external dependencies go through the module's `external_dependencies`
  or documented requirements — never vendored into the module.

## Pull request expectations

- Title: `[<version>][<TAG>] <module>: <summary>`
  (e.g. `[19.0][IMP] website_sale_x: add portal card`).
- Body: `## Summary` bullets describing the why, plus a
  `#### Test plan` checklist. Reference the task/issue when one exists.
- One logical change per commit; changes to different modules go in
  separate commits. Squash review fixups into the commit they fix before
  pushing — the PR must not contain "address review" commits.
- Every commit message ends with an `Assisted-by: <tool>:<model>` trailer
  naming the AI assistant and model (one line per model used). This is a
  house rule applied to all commits, and it is required on OCA PRs.
- Sign the OCA CLA once per contributor account when prompted by the bot.
- External contributors push to their fork; OCA maintainers merge.
  `[BOT] post-merge updates` commits afterwards are normal — do not
  replicate them manually.
- Do not add files the task did not ask for (no extra `ROADMAP.md`,
  screenshots, or restructuring) unless the module template requires
  them.

## Verification before pushing

1. `python -m compileall -q <module>` or the repo's lint hooks.
2. `pre-commit run --files <changed paths>` — must pass with no
   modifications left unstaged.
3. Run the module's tests if an Odoo environment is available
   (see the `odoo-development` / `osh` skills); otherwise say so in the
   PR test plan rather than claiming they pass.
4. Review the full diff for scope creep before committing.
