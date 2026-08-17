# Odoo i18n

Export, import and manage translations for an Odoo module.

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
6. Export the translation template (`.pot`) for one or more modules:
   ```bash
   odoo-bin i18n export -d <database> <module> [<module> ...]
   ```
   - The default language is `pot`, which writes `i18n/<module>.pot` for each module.
7. Export a `.po` file for a specific language:
   ```bash
   odoo-bin i18n export -d <database> -l pt_PT <module>
   ```
   - This writes `i18n/pt_PT.po` inside the module.
8. Install the target language in the database before translating if it is not yet active:
   ```bash
   odoo-bin i18n loadlang -d <database> -l pt_PT
   ```
9. Import a translated `.po` file:
   ```bash
   odoo-bin i18n import -d <database> -l pt_PT -w i18n/pt_PT.po
   ```
   - Use `-w` (`--overwrite`) to update existing terms.
10. When source strings change, re-export the `.pot` and merge or update the `.po` files.
11. For HTML-rich fields, use `html_translate` as the `translate` attribute; for plain text, use `translate=True`.
12. Place `.po` and `.pot` files under `i18n/`; Odoo loads them automatically from there.

## Output

A summary of translation files created or updated, and any source strings that still need translation.
