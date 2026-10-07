# Agent Instructions

This repository stores reusable AI skills for Odoo work.

- Skills are located under `skills/<skill-name>/SKILL.md`.
- Each `SKILL.md` contains workflow, conventions, and tool instructions for that task.
- When a request matches a skill, read and follow the relevant `SKILL.md` before acting.

## Available skills

- `odoo-module-migration` — migrate an Odoo module to a newer version.
- `odoo-coding-conventions` — project-specific conventions that extend the upstream skills below.
- `odoo-i18n` — export, import and manage module translations.
- `odoo-documentation` — locate and use the official Odoo functional and technical documentation.

## Upstream Odoo skills

The Odoo source repository ships official agent skills under `skills/`,
starting with Odoo 20 — check the `master` branch on GitHub first for the
latest version (`https://github.com/odoo/odoo/tree/master/skills/`):

- `odoo-guidelines` — house rules for addon code outside `static/` (Python/ORM,
  fields, manifest, controllers, XML, reports, access rights, performance, tests).
- `odoo-web-guidelines` — JavaScript, Owl templates and SCSS under `static/`.
- `odoo-security` — security audit patterns (sudo, raw SQL, routes, XSS, eval...).
- `odoo-review` — review process dispatching to the three skills above.

Install them alongside this repo's skills — per project into `.devin/skills/` or
`.agents/skills/`, or globally into `~/.config/devin/skills/`:

```bash
cp -r <odoo-checkout>/skills/* ~/.config/devin/skills/   # from a master/20.0+ checkout
# or straight from GitHub:
git clone --depth 1 --filter=blob:none --sparse https://github.com/odoo/odoo.git /tmp/odoo-master \
  && git -C /tmp/odoo-master sparse-checkout set skills \
  && cp -r /tmp/odoo-master/skills/* ~/.config/devin/skills/
```

Copy them from a `master`/20.0 checkout — they only exist there, so when working
on older Odoo versions double-check any API detail against the actual target
source. All upstream skills must be installed together — they reference each
other. Skills in this repo defer to them for coding rules and only add
project-specific workflows and deltas.

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
