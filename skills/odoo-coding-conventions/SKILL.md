# Odoo Coding Conventions

Apply these conventions when writing or reviewing Odoo custom or OCA module code.

## When to use

- Writing new Python, XML, or data files for an Odoo module.
- Reviewing or refactoring an existing Odoo module.
- Cleaning up code before a commit.

## Instructions

1. **Top-down ordering**: define the current function or class before the helper functions it uses.
2. **Prefer Odoo `models.AbstractModel` mixins** over Python `ABC` or `dataclasses` for reusable/abstract APIs.
3. **Do not use Python `dataclasses`**; use standard Odoo models and plain dictionaries when a simple data structure is needed.
4. Use `__manifest__.py`, never `__openerp__.py`.
5. Import from `odoo`, not `openerp`.
6. Do not use `api.one`; use `api.depends`, `api.model`, `api.onchange`, or `api.multi` as appropriate.
7. Do not use `select=True` on fields; use `index=True` instead.
8. Always add `security/ir.model.access.csv` for new non-abstract models.
9. Wrap user-visible strings with `from odoo import _` and `_('...')`; do not use f-strings inside `_()`.
10. Keep XML `id` attributes stable; use `name` attributes for selectors when possible.
11. Avoid breaking changes in public model methods; prefer additive changes and clear deprecation.
12. Do not add docstrings to model method extensions that call `super()`. Explain the extension with a regular code comment instead of replacing or adding a docstring.

## Output

A concise report of the changes made, or a confirmation that the code already follows these conventions.
