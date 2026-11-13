# Organizing tests — a reference framework

How to structure a test suite so it stays a readable spec, and how to
reorganize an existing suite without weakening it. Read this when the
task is "clean up / reorganize / restructure the tests" rather than
"write tests for feature X."

## The three axes

Organize tests along three independent axes. Most messy suites fail on
at least one.

### 1. By story (the primary axis)

Files, classes, and test names describe **behavior a user or caller
cares about**, not the implementation units being exercised.

- File: `test_<feature-or-story-area>.py` — e.g. `test_sale_order_line_
  discounts.py`, not `test_sale_order.py::TestSaleOrderLineDiscountsMixin`.
- Class: one per story area or per actor perspective.
- Method: reads as a user story. `test_customer_cancels_order_23h_ahead_
  gets_refund` beats `test_cancel_1`. A docstring may carry the full
  story when the name gets long.
- Helpers translate story concepts into setup ("a confirmed order",
  "an expired token") — they are vocabulary, not internals.

If a reader must know the internal structure to find the test for a
behavior, the suite is organized by implementation and will drift every
refactor.

### 2. By scope (the pyramid heuristic)

Pin each behavior at the **narrowest scope that can show the failure**
(Google's guidance). More narrow tests, fewer broad ones — the higher
the level, the fewer tests.

| Tier | What it pins | Odoo mapping |
|---|---|---|
| Unit | Pure logic, no DB/ORM — computations, parsers, validators | Plain `unittest.TestCase` / pytest functions |
| Integration | Behavior through real collaborators — ORM, workflows, constraints | `TransactionCase` / `BaseCommon` |
| Feature/UI | The whole user journey — controllers, pages, tours | `HttpCase`, tours |

A behavior pinned only at feature level is slow and brittle; pinned
only at unit level it can be "correct" while the feature is broken.
Push each assertion down to the narrowest tier that can falsify it,
and keep a thin layer of feature tests for the journeys that matter.

Google's refinement worth stealing: classify on **two axes** — *scope*
(how much code is validated) and *size* (what it needs to run: process,
machine, network). A unit test hitting a real database is narrow scope
but not small size — worth knowing when a "unit" test is slow.

### 3. By provenance

Separate tests by *why they exist*:

- **Feature tests** — pin the spec: what the system should do.
- **Regression tests** — pin a bug that happened: dedicated file where
  the test name/docstring explains the issue found (the house rule).
  Group by issue/PR where practical; a `test_regressions.py` grab-bag
  is the fallback when issues are unrelated.
- **Characterization tests** — pin *actual* behavior of legacy code
  whose spec is unknown. Label them as such; they are a safety net,
  not a spec, and get replaced by real spec tests over time.

## Inside each test

- **Arrange-Act-Assert** (or Given-When-Then): setup → one action →
  assertions. If a test needs two acts, it is probably two tests.
- Assert **behavior and outcomes**, not implementation: field values
  after the action, emitted records, returned documents — not that a
  private method was called or a specific query ran.
- Real fixtures and data over mocks: disk-file fixtures parsed by the
  real tool beat canned responses. Reserve fakes for what cannot run
  in-process.
- One behavior per test; shared setup goes in `setUpClass`/`setUp`,
  per-story data through builders/helpers.

## Odoo layout notes

- Tests live in `<module>/tests/`, one package per module; every
  `test_*.py` must be imported from `tests/__init__.py` and the class
  *defined* in that file or it is silently skipped (see
  `../odoo-guidelines/guidelines/tests.md`).
- `TransactionCase`/`BaseCommon` for integration tier; plain
  `unittest`/`TransactionCase` for pure logic that doesn't need the
  registry.
- Tagging (`at_install`/`post_install`, custom tags) is a *selection*
  axis, orthogonal to organization — don't reorganize around tags.

## Reorganizing an existing suite

Reorganization is itself a spec-sensitive change: **the tests may move
and rename, but their assertions should not change.** A reorg diff
should look like moved code, not edited expectations. The tampering
taxonomy applies — "while I was in there" is where bent tests hide.

### Workflow

1. **Baseline.** Run the suite; it must be green (or record exactly
   which tests fail and why). For behavior nobody understands, capture
   it first — characterization/golden-master — so reorganization can't
   silently change it.
2. **Inventory and classify.** For each test file, list what it pins:
   story-area, scope tier, provenance. Flag implementation-coupled
   tests (private methods, internal field names, `assertQueryCount`
   in business tests, mocks of the unit under test).
3. **Re-pin before re-organizing.** Rewrite coupled tests against
   public behavior *first*, as their own commit. If a rewrite forces
   an expectation change, that is a spec question — stop and resolve
   it, don't bake it into a "cleanup" commit.
4. **Re-group.** Move tests into story-area files; split feature vs
   regression vs characterization; fix `tests/__init__.py` imports.
   Prefer `git mv` so history follows.
5. **Verify.** Suite green; `scripts/check-test-diff.sh` should report
   assertion *moves*, not removals (it compares the assertion multiset —
   see below). Any residual diff in expectations needs the
   "did the task change this rule?" review.

### What "clean" looks like

- A new contributor can find the test for a behavior by its name.
- Deleting an internal method breaks zero tests; changing a spec
  breaks exactly the tests named for that behavior.
- Regression tests explain their issue; characterization tests are
  visibly labeled as such.
- The suite's shape matches the pyramid: many narrow, few broad —
  without chasing percentages.
