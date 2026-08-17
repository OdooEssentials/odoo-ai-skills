# Odoo Translation

Add or update translations for an Odoo module.

## When to use

- A module has new user-visible strings in Python or XML.
- Translating an Odoo module to a new language.
- Reviewing or refreshing existing `.po` files.

## Instructions

1. Keep source terms in English in the code and XML.
2. In Python, import `_` from `odoo` and wrap all user-visible strings:
   ```python
   from odoo import _
   _('Hello %(name)s') % {'name': name}
   ```
3. Do **not** use f-strings inside `_()`. Use `%(name)s` placeholders and `%` formatting.
4. In XML, `string="..."`, `help="..."`, and similar attributes are extracted automatically when the module is exported.
5. Create or update `i18n/<module>.pot` (template) and `i18n/<lang>.po` files.
6. Generate the `.pot` via Odoo:
   - Use the UI at *Settings > Translations > Export Translations*.
   - Or use the CLI tooling provided by the active environment (`odoo-bin` / `osh odoo`).
7. Copy the `.pot` to `i18n/<lang>.po` for each target language and fill in `msgstr`.
8. When source strings change, re-export the `.pot` and merge or update the `.po` files.
9. For HTML-rich fields, use `html_translate` as the `translate` attribute; for plain text, use `translate=True`.
10. Place `.po` and `.pot` files under `i18n/`; Odoo loads them automatically from there.

## Output

A summary of translation files created or updated, and any source strings that still need translation.
