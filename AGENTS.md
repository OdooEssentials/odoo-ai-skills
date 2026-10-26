# Agent Instructions

This repository stores reusable AI skills for Odoo work.

- Skills are located under `skills/<skill-name>/SKILL.md`.
- Each `SKILL.md` contains workflow, conventions, and tool instructions for that task.
- When a request matches a skill, read and follow the relevant `SKILL.md` before acting.

## Available skills

- `odoo-module-migration` — migrate an Odoo module to a newer version.
- `odoo-development` — local dev workflows: module install/update commands and running module tests efficiently.
- `odoo-coding-conventions` — project-specific conventions that extend the upstream skills below.
- `odoo-i18n` — export, import and manage module translations.

## Skill format

Skills in this repository must follow the
[Agent Skills specification](https://agentskills.io/specification):

- Each skill is a directory `skills/<skill-name>/` containing a `SKILL.md`.
- `SKILL.md` starts with YAML frontmatter followed by Markdown instructions.
- Frontmatter may only contain: `name`, `description` (both required),
  `license`, `compatibility`, `metadata`, `allowed-tools`.
- `name` must match the directory name — lowercase alphanumeric and hyphens
  only, no leading/trailing or consecutive hyphens, max 64 chars.
- `allowed-tools` is a space-separated string, not a YAML list
  (e.g. `allowed-tools: Read Grep Bash`).
- Non-standard fields such as `argument-hint` are not allowed.
- Keep `SKILL.md` under ~500 lines; move detailed material into referenced
  files (e.g. `references/`, `scripts/`, `assets/`).

Validate skills before committing:

```bash
uvx --from skills-ref agentskills validate skills/<skill-name>
```

## Upstream Odoo skills

The Odoo source repository ships official agent skills under `skills/`,
starting with Odoo 20 — check the `master` branch on GitHub first for the
latest version (`https://github.com/odoo/odoo/tree/master/skills/`):

- `odoo-guidelines` — house rules for addon code outside `static/` (Python/ORM,
  fields, manifest, controllers, XML, reports, access rights, performance, tests).
- `odoo-web-guidelines` — JavaScript, Owl templates and SCSS under `static/`.
- `odoo-security` — security audit patterns (sudo, raw SQL, routes, XSS, eval...).
- `odoo-review` — review process dispatching to the three skills above.
- `odoo-git` — commit message format, branch targeting, and PR hygiene for
  Odoo's own repositories (odoo/odoo, odoo/enterprise, and their forks).

## Installing both sets of skills

This repo's skills and the upstream skills are designed to be used together:
they cross-reference each other with relative paths (`../odoo-guidelines/...`),
so they must live as siblings in the same skills directory. Install **both**
sets, side by side, into one of:

- Per project: `.devin/skills/` or `.agents/skills/` at the project root.
- Globally: `~/.config/devin/skills/`.

```bash
# 1. This repo's skills
cp -r <this-repo>/skills/* ~/.config/devin/skills/

# 2. Upstream Odoo skills — from a master/20.0+ checkout...
cp -r <odoo-checkout>/skills/* ~/.config/devin/skills/

#    ...or straight from GitHub:
git clone --depth 1 --filter=blob:none --sparse https://github.com/odoo/odoo.git /tmp/odoo-master \
  && git -C /tmp/odoo-master sparse-checkout set skills \
  && cp -r /tmp/odoo-master/skills/* ~/.config/devin/skills/
```

All upstream skills must be installed together — they reference each other —
and copy them from a `master`/20.0 checkout, where they only exist. When
working on older Odoo versions, double-check any API detail against the actual
target source.

Skills in this repo defer to the upstream skills for coding rules and only add
project-specific workflows and deltas. If a rule here seems to conflict with
the upstream skills, the upstream rule wins for Odoo core code — report it so
this repo can be fixed.

## Documentation sources

The official Odoo documentation is maintained in a public GitHub repository:

- Repository: https://github.com/odoo/documentation
- Branches: one per Odoo version (e.g., `19.0`, `18.0`, `17.0`)
- Developer reference and tutorials: `https://github.com/odoo/documentation/tree/<version>/content/developer`
- Functional app documentation: `https://github.com/odoo/documentation/tree/<version>/content/applications`

Replace `<version>` with the target Odoo version. For direct access to the content, clone the repository and check out the relevant branch:

```bash
git clone https://github.com/odoo/documentation.git
cd documentation
git checkout <version>
```

The `applications` documentation also covers Enterprise features that may not be available in Odoo Community Edition.

## For Devin

Use the `skill` tool to discover and invoke skills in this repo:

- `skill search path=skills keywords=<topic>` — find a skill by topic
- `skill list path=skills` — list skills (if supported)
- `skill invoke skill=<skill-name>` — activate a skill by name

## For Other Agents (Cursor, Claude, Cline, Roo Code, etc.)

Treat `skills/<skill-name>/SKILL.md` as project-specific instructions.
Read the matching skill file for the task at hand and apply its guidance.
