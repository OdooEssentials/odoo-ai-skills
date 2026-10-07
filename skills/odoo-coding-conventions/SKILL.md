---
name: odoo-coding-conventions
description: Project-specific Odoo coding conventions that extend the official odoo-guidelines and odoo-web-guidelines skills. Use when writing or reviewing Odoo addon code.
---

# Odoo Coding Conventions

Project-specific conventions for Odoo module code. These **extend** the official
Odoo skills — they do not replace them:

- `odoo-guidelines` — module structure, manifest, Python/ORM, fields, controllers,
  XML, reports, security, performance, tests (everything outside `static/`).
- `odoo-web-guidelines` — JavaScript, Owl templates and SCSS under `static/`.

Apply the official guidelines first (they ship with the Odoo checkout under
`skills/` and are version-matched to it). This skill only adds the conventions
they don't cover. If a rule here seems to conflict with the official guidelines,
the official skill wins — report it so this file can be fixed.

## When to use

- Writing new Python, XML, or data files for an Odoo module.
- Reviewing or refactoring an existing Odoo module.
- Cleaning up code before a commit.

## Project conventions

1. **Top-down ordering**: define the current function or class before the helper
   functions it uses.
2. **Prefer Odoo `models.AbstractModel` mixins** over Python `ABC` or
   `dataclasses` for reusable/abstract APIs and adapters.
3. **Do not use Python `dataclasses`**; use standard Odoo models and plain
   dictionaries when a simple data structure is needed.
4. Always add `security/ir.model.access.csv` for new non-abstract models.
5. Avoid breaking changes in public model methods; prefer additive changes and
   clear deprecation.
6. Do not add docstrings to model method extensions that call `super()`. Explain
   the extension with a regular code comment instead of replacing or adding a
   docstring.

## Output

A concise report of the changes made, or a confirmation that the code already
follows these conventions.
