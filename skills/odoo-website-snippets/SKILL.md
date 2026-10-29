---
name: odoo-website-snippets
description: Create or modify Odoo website building blocks (snippets) — static vs dynamic content, Blocks-panel registration, builder options, drop rules, and translation. Use when adding, editing, or reviewing Website Builder snippets in an Odoo addon.
---

# Odoo website snippets

Build or extend drag-and-drop blocks for the Website Builder. Baseline is the
`html_editor`-based builder (Odoo 19+): options are OWL components bound by
CSS selector and registered through builder plugins. On ≤18 the editor uses
the legacy wysiwyg/`options.js` API — the concepts map but the JS differs, so
verify every API detail against the actual target source.

Apply the upstream `odoo-guidelines` / `odoo-web-guidelines` skills for the
general coding rules (manifest, XML, assets, JS/SCSS conventions). This skill
only covers the snippet machinery.

## When to use

- Adding a new building block to a module or theme.
- Wiring block options, record-driven (dynamic) content, or drop rules.
- Debugging a block that won't render, drop, or translate.

## Vocabulary

- **Building block** — what the user sees in the Blocks panel; **snippet** —
  its implementation: a QWeb template + registry entry.
- **Structure block** — a `<section>` dropped as a whole row; lives in a
  category (Intro, Columns, Content, …).
- **Inner content block** — any tag dropped *inside* another block.
- **Option** — a control in the right-hand panel; JS + OWL, bound by CSS
  selector. Never part of the snippet markup itself.
- **Custom snippet** — a block a *user* saved via the editor; stored as an
  `ir.ui.view`, never module code.
- **Static vs dynamic** — markup copied into the page at drop time vs a live
  placeholder re-rendered from records on every page load.

## File layout

```
my_module/
├── views/snippets/
│   ├── snippets.xml          # registration in website.snippets
│   └── s_<name>.xml          # the snippet template(s)
└── static/src/
    ├── snippets/s_<name>/    # frontend: 000.scss, 000.xml, <name>.js, <name>.edit.js
    └── website_builder/      # editor: <name>_option.js/xml + _plugin.js
```

- Frontend assets → `web.assets_frontend` (or per-snippet `<asset>` templates
  inside the snippet XML, used for versioned files like `000.scss`).
- Editor-only code → `website.website_builder_assets`
  (`static/src/website_builder/**/*` in the manifest `assets` key).

**Manifest wiring** — the usual cause of "my snippet doesn't show up":

- `depends` must include `website` (for `website.snippets`, filters,
  builder assets).
- Every snippet XML file must be in `data` — `views/snippets/snippets.xml`
  and `views/snippets/s_*.xml`; order doesn't matter.
- Dynamic snippets also need their data file (filters/server actions) in
  `data`.

## Create a static snippet

1. **Template** — `views/snippets/s_<name>.xml`:

   ```xml
   <template id="s_offer_card" name="Offer Card">
       <section class="s_offer_card pt64 pb64 o_cc o_cc1">
           <div class="container s_allow_columns">
               <h2>Special offer</h2>
               <p>Write your pitch here.</p>
           </div>
       </section>
   </template>
   ```

   Structure blocks use `<section>`; inner content can be any tag. Opt into
   builder features via marker classes — they are not just styling:

   | Class | Effect |
   |---|---|
   | `o_cc o_cc*` | background color-palette option |
   | `pt*`/`pb*` | padding handlers (steps of 8, max 256) |
   | `s_allow_columns` | column-count option on the container |
   | `s_nb_column_fixed`, `s_col_no_resize` | disable column count / resize |
   | `o_not_editable`, `oe_unremovable` | protect a region |
   | `o_grid_mode` + `data-row-count` | grid layout |
   | `oe_img_bg` + inline `background-image` | editable background image |
   | `data-vcss`/`data-vxml`/`data-vjs` | versioned asset files (`001.scss`…) |

   Rules: Bootstrap classes first; prefix custom classes (`x_` for themes);
   no `id` attributes (a block can be dropped multiple times); never nest
   `<section>` inside `<section>` — options fire twice, use inner content.

2. **Register** — `views/snippets/snippets.xml`, inheriting
   `website.snippets`:

   ```xml
   <template id="snippets" inherit_id="website.snippets" name="My Snippets">
       <!-- optional: a new category -->
       <xpath expr="//snippets[@id='snippet_groups']/*[1]" position="before">
           <t snippet-group="offers" t-snippet="website.s_snippet_group"
              string="Offers"
              t-thumbnail="/my_module/static/src/img/snippets_thumbs/offers.svg"/>
       </xpath>
       <!-- structure block -->
       <xpath expr="//snippets[@id='snippet_structure']" position="inside">
           <t t-snippet="my_module.s_offer_card" string="Offer Card"
              group="offers"
              t-image-preview="/my_module/static/src/img/snippets_previews/s_offer_card.webp">
               <keywords>offer, promo, deal, discount, banner</keywords>
           </t>
       </xpath>
   </template>
   ```

   Inner-content blocks go in `//snippets[@id='snippet_content']` instead —
   no `group`, a `t-thumbnail` icon, optional `t-grid-column-span`. Inner
   content **also needs** the `so_content_addition_selectors` plugin resource
   (see *Add options*) or it can't be dropped inside other blocks. Useful
   `<t t-snippet>` attributes: `string` (panel name), `label` (disambiguates
   same-named entries), `t-image-preview`/`t-drag-image-preview` (large
   previews), `t-forbid-sanitize` (lets `form`/raw HTML survive the
   sanitizer), `t-install` (install-on-demand: appears in the panel and
   installs the module on drop — hook into `website.external_snippets`).

3. **Mark embedded markup.** On drop, the builder stamps `data-snippet`
   (the template id's local part, e.g. `s_offer_card`) and `data-name`
   (the template's `name`) on the section. When the same markup is
   *hard-coded* into a theme page or a `website.page`, write both
   attributes yourself — otherwise the builder won't recognize the block
   and upgrades can break.

4. **Options** — see below.

## Add options

An option = a `BaseOptionComponent` OWL component + a plugin registering it:

```js
// static/src/website_builder/offer_card_option_plugin.js
import { BaseOptionComponent } from "@html_builder/core/utils";
import { Plugin } from "@html_editor/plugin";
import { registry } from "@web/core/registry";

export class OfferCardOption extends BaseOptionComponent {
    static template = "my_module.OfferCardOption";
    static selector = ".s_offer_card";   // + applyTo / exclude when needed
}

export class OfferCardOptionPlugin extends Plugin {
    static id = "offerCardOption";
    resources = { builder_options: [OfferCardOption] };
}
registry.category("website-plugins")
    .add(OfferCardOptionPlugin.id, OfferCardOptionPlugin);
```

The OWL template composes `BuilderRow` (labels via `label.translate`),
`BuilderSelect`/`BuilderSelectItem`, `BuilderButtonGroup`/`BuilderButton`,
`BuilderCheckbox`, `BuilderRange`, `BuilderNumberInput`. Most options just
toggle a class via `classAction`; custom behavior goes in a `BuilderAction`
registered under `builder_actions`.

Other plugin resources that matter for snippets:

- `dropzone_selector` — `{selector, dropIn, dropNear, exclude,
  excludeNearParent}` drop rules.
- `so_content_addition_selectors` — **required** so an inner-content block
  is droppable inside other blocks. (Official docs show the singular
  `so_content_addition_selector` — a typo; the real key is plural.)
- Lifecycle hooks: `on_snippet_dropped_handlers`, `on_cloned_handlers`,
  `on_will_remove_handlers`, `clean_for_save_handlers`,
  `before_save_handlers`, `after_save_handlers`.

## Create a dynamic snippet

Dynamic = the saved page holds a configured placeholder; the `DynamicSnippet`
interaction fetches records per request and injects server-rendered HTML.
Use for "latest posts/products"-style blocks the user configures, not edits.

1. **Data source** — `website.snippet.filter` records: exactly one of
   `filter_id` (an `ir.filters` with model + domain + sort) or
   `action_server_id` (an `ir.actions.server` returning record dicts); plus
   `field_names` (comma-separated fields exposed to the template) and
   `limit` (1–16). The engine auto-adds `website_id`, `company_id` and
   `is_published` conditions when the model has them, and refuses models
   that have no filter — the endpoint can't be used to query arbitrary
   models.

   ```xml
   <!-- global ir.filters (user_ids=False) powering the snippet filter -->
   <record id="latest_posts_ir_filter" model="ir.filters">
       <field name="name">Latest Posts</field>
       <field name="model_id">blog.post</field>
       <field name="user_ids" eval="False"/>
       <field name="domain">[('published_date', '&lt;=', 'now')]</field>
       <field name="sort">["published_date desc"]</field>
       <field name="action_id" ref="website.action_website"/>
   </record>
   <record id="latest_posts_snippet_filter" model="website.snippet.filter">
       <field name="name">Latest posts</field>
       <field name="filter_id" ref="latest_posts_ir_filter"/>
       <field name="field_names">name,teaser,subtitle</field>
       <field name="limit" eval="16"/>
   </record>
   ```

   For arbitrary data logic use `action_server_id` pointing to a `code`
   server action that builds the dicts itself (`response = ...`).

2. **Block template** — call the wrapper instead of writing your own shell:

   ```xml
   <template id="s_latest_posts" name="Latest Posts">
       <t t-call="website.s_dynamic_snippet_template"
           snippet_name.f="s_latest_posts"
           main_page_url.f="/blog"
           snippet_classes="'s_latest_posts'"
           custom_template_data.f='{"show_author":true}'
           snippet_title.f="Latest Stories"/>
   </template>
   ```

   (For a carousel, add `o_dynamic_carousel_snippet` to `snippet_classes` —
   see `website_blog.s_blog_posts_carousel`.) The
   wrapper emits the `<section data-snippet>` shell, loading placeholder,
   header (title/description/"see all"), and the empty
   `.dynamic_snippet_template` container. `custom_template_data` is a JSON
   blob forwarded to the item template — good for feature toggles. For a
   single-record block, `t-set="is_single_record" t-value="True"` before the
   call (the editor then prompts for one record instead of a filter).

3. **Item template** — server-side QWeb named by convention
   `my_module.dynamic_filter_template_<model>_<variant>` (the model name in
   the key is what binds a filter to a template). Receives `records` —
   dicts of the declared `field_names` plus `_record` (the real record) and
   `call_to_action_url` — and `is_sample`. `data-*` attributes on the
   template root (`data-column-classes`, `data-number-of-elements`,
   `data-extra-snippet-classes`, `data-container-classes`) become defaults
   on the dropped section. The selected template lives on the section as
   `data-template-key` — set automatically at drop by the option plugin, but
   required when the markup is hand-written. `data-number-of-records="1"`
   without `filter_id` gives single-record mode (`data-snippet-model`/
   `data-snippet-res-id`).

4. **Editor wiring** — an option plugin whose `on_snippet_dropped_handlers`
   calls `setOptionsDefaultValues(snippetEl, "your.model")` on the shared
   `dynamicSnippetOption`/`dynamicSnippetCarouselOption` plugin so a fresh
   block pre-selects the right filter — copy `website_blog`'s
   `dynamic_snippet_blog_posts_option_plugin.js`. Ship a
   `*_preview_data` template (`.s_dialog_preview` markup) so the block
   chooser shows realistic content without live data.

Middle ground: **interactive-but-static** snippets — saved markup + a plain
frontend `Interaction` (countdown, map, form). No filter machinery; JS just
animates what the editor saved.

## Modify an existing block

- **Markup**: inherit the snippet template (`inherit_id="website.s_x"`) and
  xpath into it — the registry entry keeps pointing at the same template, so
  all drops (existing panel entry included) get your version. To add a block
  to an *existing* group or hook, xpath into `website.snippets` the same way
  `website_blog`/`website_sale` do.
- **Options**: register a new `BaseOptionComponent` whose `selector` matches
  the standard block — multiple option components can target one selector;
  yours just joins the panel. Use `applyTo`/`exclude` to narrow it.
- **Pages already dropped** contain a *copy* of the old markup — template
  changes do not migrate them. If a redesign must reach existing pages,
  rename nothing (keep the `s_*` class and `data-snippet` value) and handle
  structure differences in SCSS/JS, or accept old pages keeping the old
  look.

## Translation rules

Three surfaces translate differently — mixing them up is the main source of
"untranslatable" snippets:

1. **Module defaults.** Template text and panel metadata (`string`,
   `<keywords>`) are normal translatable view terms — export/translate via
   the module `.pot`/`.po` (see the `odoo-i18n` skill). Translate keywords
   or panel search only works in English.
2. **Dropped content.** Lives in `ir.ui.view.arch_db`
   (`translate=xml_translate`), translated per website/language in the
   frontend **Translate** mode. Keep user-facing copy in text nodes or
   `TRANSLATED_ATTRS` attributes (`alt`, `title`, `aria-label`,
   `placeholder`, `label`, `data-tooltip`) — never in `data-*` config
   attributes or `data-custom-template-data` JSON.
3. **Dynamic content.** Rendered server-side per request — `t-field` over
   record fields resolves `translate=True` fields in the visitor's language.
   Always use `t-field` (not `t-out="data['name']"`) so field widgets and
   translations apply. `website.snippet.filter.name` is translatable;
   domains and `field_names` are not (correctly so).

Edge cases:

- User-saved custom snippets carry their own view translations; Odoo copies
  them into consuming pages via `_copy_custom_snippet_translations` —
  translating the saved block once propagates to every use.
- Strings produced in JS need `_t` from `@web/core/l10n/translation`;
  anything injected bypassing `_t` is untranslatable.
- `data-name` (the stamped block label) is *not* translatable — the
  translated name comes from `string` in the registry.
- Gate `is_sample` markers (`t-if="is_sample"`) so "Sample" ribbons never
  reach real visitors.

## Gotchas

- Panel shows nothing after `-u`: registration lives in a *view*, so it
  needs a module update — and the Blocks panel caches; hard-reload or
  reopen the editor.
- Keywords, thumbnails, and `t-if="debug"` visibility are all evaluated in
  `website.snippets`, not per-snippet.
- `t-forbid-sanitize` markup can break HTML-field sanitization on save —
  only use it when the block genuinely needs forms/scripts.
- The dynamic-snippet RPC enforces a hard cap of 16 records and only serves
  models that have a `website.snippet.filter` — don't try to bypass it for
  "private" data; the filter and publication flags are the security model.
- `<section>` inside `<section>`, missing `data-name`/`data-snippet` on
  theme pages, and HTML `id`s are the top three "weird editor behavior"
  causes.

## Verify

1. `odoo-bin -d <db> -u <module> --stop-after-init` (registration is a view).
2. Edit a page → Blocks tab: the block appears in its group (structure) or
   the inner-content grid; search finds it by `<keywords>`.
3. Drop it: options appear in the right panel and apply correctly;
   dynamic blocks fetch and render records (watch `/website/snippet/filters`
   in the network tab).
4. In Translate mode, confirm the dropped text is translatable; check a
   second language for dynamic blocks' record fields.
5. With demo data installed, `/website/demo/snippets` renders standard
   snippets for comparison.

## Sources

- `odoo/addons/website/views/snippets/snippets.xml` — the registry
- `odoo/addons/website/models/website_snippet_filter.py` — dynamic data source
- `odoo/addons/website/static/src/snippets/s_dynamic_snippet/` — client side
- `odoo/addons/website_blog/` — complete dynamic-snippet example
- https://www.odoo.com/documentation/<version>/developer/howtos/website_themes/building_blocks.html
