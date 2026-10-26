---
name: odoo-i18n
description: Export, translate, and import Odoo module translations (.pot/.po files, i18n workflow)
---

# Odoo i18n

Export, translate, and import translations for an Odoo module.

## When to use

- A module has new user-visible strings in Python or XML.
- Translating an Odoo module to a new language.
- Reviewing or refreshing existing `.po` files.

## Marking source strings in code

- Keep source terms in English in Python and XML.
- Wrap every user-visible string:
  - Inside models, prefer `self.env._('...')` — it carries the record's
    language context.
  - Elsewhere, `from odoo import _`.
  - For module-level constants, use `odoo.tools.translate._lt` (lazy
    translation) — plain `_` resolves at import time, before any language
    context exists.
- Never use f-strings inside `_()`. Use `%(name)s` placeholders and `%`
  formatting:
  ```python
  _('Hello %(name)s') % {'name': name}
  ```
- In XML, `string="..."`, `help="..."`, `placeholder="..."`, and similar
  attributes are extracted automatically at export — no marker needed.
- On field declarations: `translate=True` for plain text, `html_translate`
  for HTML-rich fields.
- Do not mark technical strings (model names, `_name`, `_description` values
  used for lookup, XML ids, domain strings that are not user-facing).

## File layout

- `i18n/<module>.pot` — the template, committed to the repo.
- `i18n/<lang>.po` — one file per language. The file name must exactly match
  the language's `iso_code` in `res_lang` (e.g. `pt.po`, `pt_PT.po`) — Odoo
  only loads a `.po` whose name matches an installed language. List valid
  codes with:
  ```bash
  psql -d <db> -c "SELECT iso_code FROM res_lang ORDER BY iso_code"
  ```

## CLI syntax by version

The `i18n` subcommand exists from **Odoo 19** on. Older versions use the
`--i18n-*` flags instead:

| Action | Odoo 19+ (`i18n` subcommand) | Odoo ≤18 (flags) |
| - | - | - |
| Load language | `odoo-bin i18n loadlang -d <db> -l pt_PT` | `odoo-bin -d <db> --load-language=pt_PT` |
| Export `.pot` | `odoo-bin i18n export -d <db> <module>` | `odoo-bin -d <db> --modules=<module> --i18n-export=<path>/<module>.pot` |
| Export `.po` | `odoo-bin i18n export -d <db> -l pt_PT <module>` | `odoo-bin -d <db> --modules=<module> -l pt_PT --i18n-export=<path>/pt_PT.po` |
| Import `.po` | `odoo-bin i18n import -d <db> -l pt_PT [-w] i18n/pt_PT.po` | `odoo-bin -d <db> -l pt_PT --i18n-import=i18n/pt_PT.po [--i18n-overwrite]` |

Notes:

- All commands exit when done — no `--stop-after-init` needed.
- Without `-w`/`--i18n-overwrite`, an import only fills **empty** translations;
  existing `msgstr` values are kept. Use overwrite to replace them.
- On ≤18, `--i18n-export` writes to the path you pass it — write directly to
  `i18n/` or move the file there.
- On 19+, `export -o <file>` merges all modules into one file instead of one
  file per module.

## Workflow: translate a module to a new language

1. Update the module in the database — exports only collect terms from
   installed, up-to-date modules:
   ```bash
   odoo-bin -d <db> -u <module> --stop-after-init
   ```
2. Load the language if it is not yet active (see table above).
3. Export `i18n/<module>.pot` (see table above).
4. Create `i18n/<lang>.po` — either export it (gets Odoo's proper header) or
   copy the `.pot` and set `Language:` in the header.
5. **Translate**: fill in every `msgstr` in the `.po` file. Keep `msgid`
   untouched; reuse the same `%(name)s` placeholders:
   ```po
   #: model:ir.model.fields,field_description:my_module.field_my_module__partner_id
   msgid "Partner"
   msgstr "Cliente"
   ```
   Leave `msgstr ""` only for terms that stay identical to English.
6. Import the `.po` (see table above) — with overwrite if refreshing an
   existing translation.
7. Commit `i18n/<module>.pot` and `i18n/<lang>.po` together with the source
   changes that introduced the terms.

## Updating translations when source strings change

1. Re-export the `.pot`.
2. Merge the new template into each `.po` with gettext's `msgmerge` — do not
   merge by hand:
   ```bash
   msgmerge -U i18n/pt_PT.po i18n/<module>.pot
   ```
   New terms get empty `msgstr`s; changed terms are marked `fuzzy` — review
   those, fix or confirm them, and remove the `fuzzy` marker.
3. Fill any empty `msgstr`s and re-import.

## Output

A summary of translation files created or updated, and any source strings
that still need translation (empty `msgstr` count per file).
