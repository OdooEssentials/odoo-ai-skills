---
name: living-design-doc
description: Create or maintain per-feature "living specs" — one Markdown file per feature under a specs/ directory, starting as spec + task list and evolving into a decision record, kept separate from end-user documentation. For Odoo addon modules specs live in <module>/specs/ while readme/ fragments stay end-user-facing. Use when designing a feature or module, making a non-trivial technical decision, or when an existing design doc needs updating.
---

# Living specs

A living spec is born as a spec and never thrown away. It passes
through three roles: **spec → build log → decision record**. Keep it
honest at whichever stage you meet it.

The spec is the contract the work is validated against — including by
tests (see *Specs and tests* below). It is agent-facing, not
user-facing: it never ships inside generated user docs.

## When to use

- Starting a non-trivial feature, Odoo module, or technical decision →
  offer to create the spec.
- A spec exists for the work you're touching → read it first, update it
  in the same commits as the work.
- Check `AGENTS.md`/project rules for doc placement and status
  conventions already in use.

## Where specs live

Specs get their own `specs/` directory — one file per feature — kept
separate from user docs (`docs/`, `README.rst`, `readme/` fragments):

- **Not an Odoo module** → `specs/<feature>.md` at the repo root.
- **Odoo addon module exists** → `<module>/specs/<feature>.md`, inside
  the module next to the code it describes. Specs are deliberately
  *not* `readme/` fragments — the `oca-gen-addon-readme` generator only
  assembles the known fragment names, so specs stay repo-local and out
  of `README.rst`.
- **Module still being designed, no skeleton yet** →
  `specs/<module>.md` at the repo root. When the module is created,
  move it to `<module>/specs/`.
- Add an index line for each spec where readers look — a `specs/`
  README or a bullet list in `AGENTS.md` — so specs stay discoverable
  as the directory grows.

## Spec skeleton

One file per feature, lowercase-hyphen name (`specs/import-csv.md`).
Keep it to a page or two:

```markdown
# <Feature> — spec

**Status:** draft | accepted | in progress | shipped
**Date:** <YYYY-MM-DD>
**Scope:** <which repos/components this touches>
**Related:** <the other spec files this one depends on or borders —
paths under specs/ — so a reader always knows which file a fact
belongs in>

## Context            <- the problem, why now
## Spec               <- requirements and acceptance criteria, in enough
                        detail to implement and to test against
## <Contract details> <- API contract, data flow, schema — whatever the feature needs
## Alternatives considered   <- each rejected option + the reason it lost
## Tasks              <- checkbox list; the mutable work-tracking section
```

Write the spec BEFORE the code — the writing is the design. If the
decision isn't made yet, draft alternatives and ask rather than picking
silently.

The **Spec** section is the part tests derive from: state inputs,
outputs, edge cases and side effects as checkable expectations, not
prose aspirations. When a requirement changes, edit the spec *first* —
the test change that follows cites it.

## Odoo addon modules: spec vs end-user docs

Once the addon skeleton exists, the documentation splits in two:

**`<module>/specs/`** — the living specs (skeleton above), one file per
feature. They hold status, decisions, rejected alternatives, plan and
tasks. Agent-facing; excluded from `README.rst`.

**`readme/` fragments** — end-user documentation only, the canonical
OCA fragment names that `oca-gen-addon-readme` assembles into
`README.rst`:

| Fragment | Holds |
|---|---|
| `DESCRIPTION.md` | What the module is, the problem it solves, the main features |
| `CONFIGURE.md` | The vocabulary and structure the module introduces, and how to configure it — checklist style where possible |
| `USAGE.md` | Use cases: expected result and the steps to get there, one subsection per case |

There is no `ROADMAP.md` fragment — roadmap, decisions and tasks live
in the specs where they belong. Other standard fragments (`INSTALL.md`,
`CONTRIBUTORS.md`, `HISTORY.md`) can be added when the module needs
them.

Never hand-edit the generated `README.rst` or
`static/description/index.html` — edit the fragments and regenerate with
`oca-gen-addon-readme` (see `../odoo-module-migration/SKILL.md` for the
regeneration workflow).

## Specs and tests

The spec and the test suite are two views of the same contract:

- **Spec first.** Acceptance criteria in the Spec section are written
  before implementation; tests are derived from them, not from the
  code that satisfies them.
- **Test changes cite spec changes.** Per the `agentic-testing` skill,
  a test may only change when the requirement it encodes changed — and
  the requirement lives in the spec. A test diff without a spec diff is
  a red flag; a spec diff without a test diff means the new behavior is
  unverified.
- **Tasks tick in the same commit as the work**, including spec
  amendments — the checklist must never silently diverge from reality.

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
  (draft → accepted → in progress → shipped). A shipped spec that says
  "draft" is a lie that compounds.
- **Decisions are append-only.** Never delete a decision or a rejected
  alternative. To supersede, add a dated note
  ("*2026-11 — superseded: now using X because…*"). The record of what
  lost, and why, is a veto on re-litigating it later.
- **Annotate deviations.** When implementation diverges from spec, fix
  the spec — a spec that ossified into fiction is worse than none.
- **Rejected alternatives are vetoes.** Before proposing an approach,
  read the decisions/alternatives of any related spec. Don't re-propose
  a rejected option unless you have genuinely new evidence — and say
  what's new.
- **One spec per feature.** Each feature gets its own file under
  `specs/`; the end-user docs are its public face. Project principles
  belong elsewhere (`AGENTS.md` = the constitution; `specs/` = the
  features).
- **After shipping, the spec graduates** — it becomes the decision
  record. Update status, leave the tasks checked, keep everything else.
  End-user docs (fragments, `docs/`) are updated to match shipped
  behavior; the spec keeps the *why*.

## Consuming a spec (as reader)

- Treat specs as ground truth for *why* the code looks the way it does
  — but check the Status line and recency before trusting details
  against the code.
- When asked "why is it built this way?", cite the spec's decision and
  alternatives sections rather than reconstructing intent from code.
- When writing or changing tests, read the Spec section first — the
  acceptance criteria are the test oracle.

## Anti-patterns

- Rewriting history: deleting alternatives, quietly editing old decisions.
- A second source of truth: duplicating the spec's content into comments
  or end-user docs — link to it instead. Conversely, never paste
  roadmap/tasks/decisions into `README.rst` fragments — that's what
  `specs/` is for.
- Milestone-thinking: treating the spec as "done" — it is done when the
  feature is deleted.
- Spec without work or work without spec: the two must land in the same
  commits, or the spec rots.
- Specs written after the code "to document what we did" — that's a
  changelog, not a spec; the acceptance criteria must precede the tests.

## The one-line version

Dated, single-authored, per-feature files under `specs/` — each with a
status, a specification precise enough to test against, kept rejections,
and a task list — separate from end-user docs, updated in the same
commits that do the work.
