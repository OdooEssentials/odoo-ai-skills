---
name: agentic-testing
description: Discipline for writing and reviewing tests in agent-assisted development. Use when an agent will write or modify tests, when a feature changes behavior that tests cover, when reviewing a diff that touches test files, or whenever there is a risk of "test tampering" — tests edited to match wrong code instead of code fixed to match tests. Covers spec-first ordering, commit-level separation of test changes from implementation changes, and mechanical guards.
---

# Agentic testing

Tests are the executable specification. They change when the spec
changes — never to accommodate an implementation. When the same agent
writes code and tests, a green suite is a claim, not evidence: the agent
has graded its own work. This skill keeps the grading honest.

## When to use

- A feature or fix will add or change tests.
- Reviewing a diff where test files appear next to implementation
  changes.
- An agent reports "all tests pass" and you need to know what that
  actually proves.
- Planning work where behavior is uncertain enough that a bent test
  would hide a real bug.

Skip for throwaway prototypes and purely visual changes where the
expected result cannot be written down before seeing it.

## The one rule

A test may change in exactly two situations:

1. **The requirement it encodes changed** — the spec moved, and the
   new expectation comes from the spec (ticket, design doc, decision),
   not from what the code now returns.
2. **The test was wrong about the requirement** — a bug in the test
   itself, justified and reviewed like a spec correction.

Everything else — refactors, bug fixes, "make it pass" — must leave
tests untouched. If a test blocks the implementation, that is a signal
to stop and report, not to edit the test.

## Test tampering taxonomy

Recognize these forms in any agent-produced diff. All are legitimate
moves *in isolation*; all are suspect until classified:

| Form | What it looks like |
|---|---|
| Weakened assertion | `assertEqual` → `assertTrue`, `toEqual` → `toBeTruthy`, tolerance widened |
| Changed expected value | Literal replaced by whatever the code returns |
| Deleted coverage | Test function/file removed, parametrized list shortened, collected-test count drops |
| Skips and exclusions | `skip`/`xfail`/`@unittest.skip`/`xit`, renamed tests the runner no longer collects, `--ignore` added |
| Regenerated goldens | Snapshots/fixtures rewritten from current output without classifying the diff |
| Mocked-away subject | Mock arranged so the test checks the mock; canned response replaces the real path |
| Test-aware code | Production branches special-casing test inputs or checking for a test environment |

## Workflow

### 1. Spec first, tests derived from it

Write or confirm the spec (acceptance criteria, design doc, ticket)
before tests. Derive tests from the spec's invariants — inputs,
outputs, edge cases, side effects — not from reading the code that will
satisfy them. A test written after the code describes what the code
does and passes by construction.

### 2. Tests fail for the right reason, then commit the baseline

Have the agent write tests only — no implementation. Run them; confirm
each fails because the behavior is missing, not because of an import
error or typo. Review the tests yourself (they are the spec). Commit
them alone:

```bash
git add <test files>
git commit -m "test(<scope>): <feature> acceptance tests"
```

Note the commit hash. From here on, `git diff <baseline> -- <test paths>`
shows every test mutation.

### 3. Implement with tests out of scope

Instruct the agent: make the tests pass **without modifying any test
file, fixture, snapshot, or test-runner configuration**. A failing test
that contradicts the request or the spec gets reported, not fixed.

Enforce with scope, not trust:

- Declare the task's allowed paths; test roots are not on an
  implementation task's list.
- After the run, verify: `git diff --name-only <base>...HEAD` must
  contain no test-root paths.
- `scripts/check-test-diff.sh` automates the suspicious-pattern checks
  (see below).

### 4. Commit-level separation

Test/spec changes and implementation changes land in **separate
commits**, test changes first. This makes "did the contract move?" a
glance at the commit list instead of a diff excavation. Reject
implementation commits that touch test files.

### 5. Review test diffs first

When test files do change, review that diff **before** the
implementation diff, as its own review. For each changed expectation ask
one question: *did the task change this rule?* Yes → legitimate spec
change, verify the new value comes from the spec. No → bent test;
the code is suspect.

### 6. Independent evidence

CI on the pushed commit is the evidence; the agent's "tests pass" is a
claim. Never let the same agent write the tests and certify them —
where it matters, a second pass (different session or model) checks
the tests against the spec.

## Reorganizing existing tests

Test reorganization follows the same rule: tests may **move and
rename, but their assertions should not change**. A cleanup diff should
look like moved code, not edited expectations — "while I was in there"
is where bent tests hide.

When the task is restructuring a suite (renaming files, regrouping by
feature, splitting regression tests, fixing collection pitfalls), read
`references/test-organization.md` first — it defines the framework
(organize by story, by scope, by provenance) and the reorganization
workflow (baseline → classify → re-pin coupled tests → re-group →
verify). Re-pinning an implementation-coupled test is a spec-sensitive
change and gets its own commit and review.

## Risk tiers

| Change | Required separation |
|---|---|
| Routine fix, refactor, small feature | Commit-level separation (steps 2–5) |
| New business logic, changed calculations, financial rules, anything a bent test could hide | **Phase separation**: spec+tests committed in one session, implementation in a fresh session that cannot see the test-authoring context; tests verified against spec by a reviewer before implementation starts |
| Legacy code with no known spec | Characterization tests first: capture current behavior as golden master; every master diff is classified (intended change vs accidental regression) before regenerating |

## Odoo specifics

- Test roots per module: `tests/` directories and `test_*.py` files.
- Run module tests via the `odoo-development` skill — never let the
  implementation agent change test files to make `odoo-bin` go green.
- Odoo test style rules (TransactionCase, tagged tests, etc.) live in
  the upstream `odoo-guidelines` skill — this skill governs *whether*
  tests may change, not how they're written.
- Data-file/fixture changes that alter test inputs count as test
  changes for separation purposes.

## Mechanical guard

`scripts/check-test-diff.sh <base-ref>` checks **each commit** in the
range and enforces the separation mechanically:

- a commit touching both test files and implementation files **fails**
  (mixed commit — split it),
- a test-only (or test+docs) commit is scanned for bent tests:
  assertions removed with none added **fail** (coverage dropped),
  assertions changed to different content get a **REVIEW** flag —
  a changed expectation is either a spec change or a bent test, and
  only the "did the task change this rule?" question can tell —
  added skip markers **fail**, and pure assertion *moves* are info,
  which is what a legitimate reorganization looks like,
- implementation-only commits are clean.

`--strict` turns REVIEW findings into failures for CI on repos where
every expectation change must be justified. Known blind spots the
script documents itself: multiline assertions (expected value on a
continuation line), fixture files outside test roots, and test settings
embedded in project config — review still covers those.

Run it in CI as a required check, and locally before pushing. It does
not replace review — it makes tampering visible and blocks the lazy
paths. See `scripts/check-test-diff.sh --help`.

## Anti-patterns

- Implementation and test changes in the same commit "because they're
  related" — relatedness is exactly what must be proven, not assumed.
- "Updating the tests" as the fix for a red suite without identifying
  which side is wrong.
- Regenerating snapshots/goldens to match new output, then reviewing
  the code — review the fixture diff first, classify each hunk.
- Weakening a test "temporarily" and meaning to restore it.
- Trusting the agent's summary of test results over the CI run.
- Holding out so many checks that the agent can't succeed — a thin
  holdout slice gives a tamper-proof signal without tanking
  performance.

## References

- `references/test-organization.md` — framework for organizing test
  suites (by story, scope, provenance) and the reorganization workflow.
- Research writeup (test tampering taxonomy, prior art, defense
  model): `notebook` repo, `research/tests-as-spec-agentic-workflows.md`
- Skill spec and roadmap: `notebook` repo, `projects/agentic-testing-skill.md`
- Upstream test-writing rules: `../odoo-guidelines/` (tests section),
  `../odoo-development/` (running module tests)
