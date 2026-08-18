# Agent Instructions

This repository stores reusable AI skills for Odoo work.

- Skills are located under `skills/<skill-name>/SKILL.md`.
- Each `SKILL.md` contains workflow, conventions, and tool instructions for that task.
- When a request matches a skill, read and follow the relevant `SKILL.md` before acting.

## Available skills

- `odoo-module-migration` — migrate an Odoo module to a newer version.
- `odoo-coding-conventions` — apply Odoo Python/XML/data conventions.
- `odoo-i18n` — export, import and manage module translations.
- `odoo-documentation` — locate and use the official Odoo functional and technical documentation.

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
