# Agent Instructions

This repository stores reusable AI skills for Odoo work.

- Skills are located under `skills/<skill-name>/SKILL.md`.
- Each `SKILL.md` contains workflow, conventions, and tool instructions for that task.
- When a request matches a skill, read and follow the relevant `SKILL.md` before acting.

## Available skills

- `odoo-module-migration` — migrate an Odoo module to a newer version.
- `odoo-coding-conventions` — apply Odoo Python/XML/data conventions.
- `odoo-translation` — add or update module translations.

## For Devin

Use the `skill` tool to discover and invoke skills in this repo:

- `skill search path=skills keywords=<topic>` — find a skill by topic
- `skill list path=skills` — list skills (if supported)
- `skill invoke skill=<skill-name>` — activate a skill by name

## For Other Agents (Cursor, Claude, Cline, Roo Code, etc.)

Treat `skills/<skill-name>/SKILL.md` as project-specific instructions.
Read the matching skill file for the task at hand and apply its guidance.
