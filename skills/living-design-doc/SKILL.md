---
name: living-design-doc
description: Create or maintain a per-feature "living design doc" — a repo-local doc that starts as spec + task list and evolves into feature documentation plus a decision record. For Odoo addon modules the doc lives in the module's readme/ fragments (DESCRIPTION, CONFIGURE, USAGE, ROADMAP). Use when designing a feature or module, making a non-trivial technical decision, or when an existing design doc needs updating.
---

# Living design docs

A living design doc is born as a spec and never thrown away. It passes
through four roles: **spec → build log → feature documentation →
decision record**. Keep it honest at whichever stage you meet it.

## When to use

- Starting a non-trivial feature, Odoo module, or technical decision →
  offer to create the doc.
- A design doc exists for the work you're touching (a `docs/*.md` file
  or a module's `readme/` fragments) → read it first, update it in the
  same commits as the work.
- Check `AGENTS.md`/project rules for doc placement and status
  conventions already in use.

## Where the doc lives

Decide by what the work is:

- **Odoo addon module exists** → the doc is the module's `readme/`
  fragments (see below). Never a `docs/` file.
- **Module still being designed, no skeleton yet** → one doc in
  `docs/<MODULE_NAME>.md`. When the module is created, split it into the
  `readme/` fragments and delete the `docs/` file.
- **Not an Odoo module** → `docs/<FEATURE_NAME>.md`.

## Single-doc skeleton (`docs/`)

SCREAMING_SNAKE filename matching existing docs. Keep it to a page or two:

```markdown
# <Feature> — design

**Status:** draft | accepted | in progress | shipped
**Date:** <YYYY-MM-DD>
**Scope:** <which repos/components this touches>
**Related:** <the docs owning adjacent scopes — so a reader always
knows which file a fact belongs in>

## Context            <- the problem, why now
## Decision           <- what we decided, in enough detail to implement
## <Contract details> <- API contract, data flow, schema — whatever the feature needs
## Alternatives considered   <- each rejected option + the reason it lost
## Tasks              <- checkbox list; the mutable work-tracking section
```

Write the spec BEFORE the code — the writing is the design. If the
decision isn't made yet, draft alternatives and ask rather than picking
silently.

## Odoo addon modules (`readme/` fragments)

Once the addon skeleton exists, split the doc into these files under
`<module>/readme/` — the canonical OCA fragment names that
`oca-gen-addon-readme` assembles into `README.rst`:

| Fragment | Holds |
|---|---|
| `DESCRIPTION.md` | What the module is, the problem it solves, the main features — born from Context + Decision |
| `CONFIGURE.md` | The vocabulary and structure the module introduces, and how to configure it — checklist style where possible |
| `USAGE.md` | Use cases: expected result and the steps to get there, one subsection per case |
| `ROADMAP.md` | The living part — status, decisions, plan, tasks |

`ROADMAP.md` skeleton — this is where the doc keeps evolving:

```markdown
**Status:** draft | accepted | in progress | shipped

## Decisions
- <decision and why>
  - Rejected: <alternative> — <reason it lost>

## Plan
- Iteration 1: <scope>
- Iteration 2: <scope>

## Tasks
- [ ] <task>
```

Other standard fragments (`INSTALL.md`, `CONTRIBUTORS.md`, `HISTORY.md`)
can be added when the module needs them.

Never hand-edit the generated `README.rst` or
`static/description/index.html` — edit the fragments and regenerate with
`oca-gen-addon-readme` (see `../odoo-module-migration/SKILL.md` for the
regeneration workflow).

## Writing style

- **Small sentences, one idea each.** If a sentence needs a semicolon
  or two em-dashes, split it.
- **Prefer lists and bullets over dense paragraphs.** Enumerate
  mechanics, invariants, and options rather than burying them in prose.
- **Avoid information overload.** One fact per bullet. If a bullet
  needs three parentheticals, it's three bullets.
- **Use examples or metaphors for abstract ideas.** "The bundle is the
  menu coders order from" beats "the bundle is the versioned projection
  of registry state consumed by downstream processes."

## Rules of the discipline

- **Status line is honest.** Update `Status:` as it moves
  (draft → accepted → in progress → shipped). It lives in the doc header,
  or in `readme/ROADMAP.md` for modules. A shipped doc that says "draft"
  is a lie that compounds.
- **Tasks tick in the same commit as the work.** The checklist is the
  build log; it must never silently diverge from reality.
- **Decisions are append-only.** Never delete a decision or a rejected
  alternative. To supersede, add a dated note
  ("*2026-11 — superseded: now using X because…*"). The record of what
  lost, and why, is a veto on re-litigating it later.
- **Annotate deviations.** When implementation diverges from spec, fix
  the doc — a spec that ossified into fiction is worse than none.
- **Rejected alternatives are vetoes.** Before proposing an approach,
  read the decisions/alternatives of any related doc. Don't re-propose a
  rejected option unless you have genuinely new evidence — and say
  what's new.
- **One doc per feature.** For a module, the `readme/` fragments together
  are that one doc. Project principles belong elsewhere (`AGENTS.md` =
  the constitution; `docs/`/`readme/` = the features).
- **After shipping, the doc graduates** — it becomes feature
  documentation plus decision record. Update status, leave the tasks
  checked, keep everything else.

## Consuming a doc (as reader)

- Treat design docs as ground truth for *why* the code looks the way it
  does — but check the Status line and recency before trusting details
  against the code.
- When asked "why is it built this way?", cite the doc's decision and
  alternatives sections rather than reconstructing intent from code.

## Anti-patterns

- Rewriting history: deleting alternatives, quietly editing old decisions.
- A second source of truth: duplicating the doc's content into comments
  or another file — link to it instead.
- Milestone-thinking: treating the doc as "done" — it is done when the
  feature is deleted.
- Doc without work or work without doc: the two must land in the same
  commits, or the doc rots.

## The one-line version

Dated, single-authored, repo-local document with a status, a decision,
kept rejections, and a task list — updated in the same commits that do
the work, treated as the contract the work is validated against.
