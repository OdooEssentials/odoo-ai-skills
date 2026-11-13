#!/usr/bin/env bash
# check-test-diff.sh — enforce test/spec separation in a commit range.
#
# Tests are the executable spec: they change only when the spec changes,
# and test changes must not ride along with implementation changes.
# This script checks each commit in BASE..HEAD:
#
#   - a commit touching BOTH test files and implementation files
#     FAILS (mixed commit — separate them);
#   - a commit touching ONLY test/doc files is a spec-change commit:
#     its diff is scanned for bent tests. Assertion lines removed with
#     NO assertions added at all FAIL (coverage dropped); assertion
#     lines changed to different content WARN — a changed expectation
#     is either a spec change or a bent test, and only review can tell
#     ("did the task change this rule?"). Added skip markers FAIL.
#     Pure moves — same assertions, new location — are info, which is
#     what a legitimate reorganization looks like;
#   - a commit touching only implementation/doc files is clean.
#
# Usage:
#   check-test-diff.sh BASE [--head REF] [--strict]
#
#   BASE        ref to start from (e.g. origin/main, main, HEAD~5)
#   --head REF  end ref (default: HEAD)
#   --strict    treat REVIEW findings (changed expectations) as failures
#
# Exit codes: 0 = clean, 1 = violations found, 2 = usage error.
# Escape hatch for legitimate mixed changes: ALLOW_TEST_CHANGES=1 —
# but prefer landing spec/test changes in their own commit.
#
# Test-file detection covers common layouts: tests/, test/, __tests__/
# dirs, test_*.py / *_test.* / *.test.* / *.spec.* filenames, and test
# runner config (conftest.*, pytest.ini, tox.ini). Doc files (*.md,
# *.rst) are exempt from the "implementation" classification so
# spec+tests commits pass.
#
# Known blind spots (review still required): multiline assertions whose
# expected value sits on a continuation line carry no assertion keyword
# and evade the line scan; fixture/data files outside test roots are
# classified as implementation; project config files that embed test
# settings (e.g. pyproject.toml) are implementation.

set -euo pipefail

BASE=""
HEAD_REF="HEAD"
STRICT=0

while [ $# -gt 0 ]; do
    case "$1" in
        --head) HEAD_REF="$2"; shift 2 ;;
        --strict) STRICT=1; shift ;;
        -h|--help) sed -n '2,38p' "$0"; exit 0 ;;
        -*) echo "unknown option: $1" >&2; exit 2 ;;
        *) BASE="$1"; shift ;;
    esac
done

[ -n "$BASE" ] || { echo "usage: $0 BASE [--head REF]" >&2; exit 2; }

is_test_file() {
    case "$1" in
        */tests/*|tests/*|test/*|*/test/*|*__tests__*) return 0 ;;
        test_*.py|*/test_*.py|*_test.py|test_*.rb|*/test_*.rb|*_test.rb|test_*.go|*/test_*.go|*_test.go|test_*.java|*/test_*.java|*_test.java) return 0 ;;
        *.test.*|*.spec.*|*_test.*) return 0 ;;
        conftest.*|pytest.ini|tox.ini|.coveragerc) return 0 ;;
    esac
    return 1
}

is_doc_file() {
    case "$1" in
        *.md|*.rst|*.txt|LICENSE*|CHANGELOG*) return 0 ;;
    esac
    return 1
}

norm() { sed 's/^[[:space:]]*//; s/[[:space:]]*$//; s/[[:space:]][[:space:]]*/ /g'; }

fail=0
range_note="${BASE}...${HEAD_REF}"

# For each commit, classify touched files and, for test-only commits,
# scan the diff for bent assertions and added skips.
while IFS= read -r commit; do
    short="${commit:0:8}"
    parent="${commit}^"
    if ! git rev-parse --verify --quiet "$parent" >/dev/null; then
        # root commit: diff against the empty tree
        name_status=$(git diff-tree --root --no-commit-id --name-status -r --no-renames "$commit")
        diff_range=("4b825dc642cb6eb9a060e54bf8d69288fbee4904" "$commit")
    else
        name_status=$(git diff --name-status --no-renames "$parent" "$commit")
        diff_range=("$parent" "$commit")
    fi

    has_test=0; has_impl=0; has_doc=0
    test_files=()
    while IFS=$'\t' read -r status path _; do
        [ -z "${path:-}" ] && continue
        is_test_file "$path" && { has_test=1; test_files+=("$path"); continue; }
        is_doc_file "$path" && { has_doc=1; continue; }
        has_impl=1
    done <<< "$name_status"

    if [ "$has_test" -eq 1 ] && [ "$has_impl" -eq 1 ]; then
        echo "check-test-diff: FAIL $short — commit mixes test and implementation changes:" >&2
        while IFS=$'\t' read -r status path _; do
            [ -n "${path:-}" ] && printf '  %s %s\n' "$status" "$path" >&2
        done <<< "$name_status"
        fail=1
        continue
    fi

    [ "$has_test" -eq 1 ] || continue  # impl/doc-only commit: clean

    # Test-only (or test+doc) commit: scan for bent tests.
    removed_asserts=(); added_asserts=(); removed_skips=(); added_skips=()
    test_fn_removed=0; test_fn_added=0

    for tf in "${test_files[@]}"; do
        while IFS= read -r line; do
            case "$line" in
                -\?*) ;;
                -*)
                    content="$(printf '%s' "${line:1}" | norm)"
                    case "$content" in
                        *assert*|*expect\(*|*should.*|*verify\(*|*t.Fatal*|*require.*)
                            removed_asserts+=("$content") ;;
                    esac
                    case "$content" in
                        *[Ss]kip*|*[Xx]fail*|*unittest.skip*|*@Disabled*|*.only\(*|*fit\(*|*fdescribe*|*--ignore*)
                            removed_skips+=("$content") ;;
                    esac
                    case "$content" in
                        *"def test_"*|*"it("*|*"test("*|*"describe("*)
                            test_fn_removed=$((test_fn_removed+1)) ;;
                    esac
                    ;;
                +*)
                    content="$(printf '%s' "${line:1}" | norm)"
                    case "$content" in
                        *assert*|*expect\(*|*should.*|*verify\(*|*t.Fatal*|*require.*)
                            added_asserts+=("$content") ;;
                    esac
                    case "$content" in
                        *[Ss]kip*|*[Xx]fail*|*unittest.skip*|*@Disabled*|*.only\(*|*fit\(*|*fdescribe*|*--ignore*)
                            added_skips+=("$content") ;;
                    esac
                    case "$content" in
                        *"def test_"*|*"it("*|*"test("*|*"describe("*)
                            test_fn_added=$((test_fn_added+1)) ;;
                    esac
                    ;;
            esac
        done < <(git diff -U0 "${diff_range[@]}" -- "$tf" 2>/dev/null \
                 | grep -E '^[+-]' | grep -vE '^\+\+\+|^---' || true)
    done

    # Multiset comparison: removed assertion contents with no added
    # counterpart are genuinely dropped/weakened; matched ones are moves.
    unmatched_removed=$(comm -23 \
        <(printf '%s\n' "${removed_asserts[@]}" | sort) \
        <(printf '%s\n' "${added_asserts[@]}" | sort) | sed '/^$/d' || true)
    unmatched_added_skips=$(comm -23 \
        <(printf '%s\n' "${added_skips[@]}" | sort) \
        <(printf '%s\n' "${removed_skips[@]}" | sort) | sed '/^$/d' || true)

    commit_fail=0
    if [ -n "$unmatched_removed" ]; then
        if [ "${#added_asserts[@]}" -eq 0 ]; then
            echo "check-test-diff: FAIL $short — assertion lines removed and none added (coverage dropped?):" >&2
            printf '%s\n' "$unmatched_removed" | head -20 | sed 's/^/  /' >&2
            commit_fail=1
        else
            n_unmatched=$(printf '%s\n' "$unmatched_removed" | sed '/^$/d' | wc -l)
            echo "check-test-diff: REVIEW $short — $n_unmatched assertion line(s) changed; verify each is a spec change ('did the task change this rule?'):" >&2
            printf '%s\n' "$unmatched_removed" | head -20 | sed 's/^/  /' >&2
            [ "$STRICT" -eq 1 ] && commit_fail=1
        fi
    fi
    if [ -n "$unmatched_added_skips" ]; then
        echo "check-test-diff: FAIL $short — skip markers added:" >&2
        printf '%s\n' "$unmatched_added_skips" | head -20 | sed 's/^/  /' >&2
        commit_fail=1
    fi
    if [ "$test_fn_removed" -gt "$test_fn_added" ]; then
        echo "check-test-diff: WARN $short — test functions removed ($test_fn_removed) exceed added ($test_fn_added)" >&2
    fi

    moved=$(( ${#removed_asserts[@]} - $(printf '%s\n' "$unmatched_removed" | sed '/^$/d' | wc -l) ))
    [ "$moved" -gt 0 ] && \
        echo "check-test-diff: info $short — $moved assertion line(s) moved (reorganization, not weakening)" >&2

    [ "$commit_fail" -eq 1 ] && fail=1
done < <(git rev-list --reverse --no-merges "${BASE}..${HEAD_REF}")

if [ "$fail" -eq 0 ]; then
    echo "check-test-diff: clean — no suspicious test changes in ${range_note}"
    exit 0
fi

if [ "${ALLOW_TEST_CHANGES:-0}" = "1" ]; then
    echo "check-test-diff: ALLOW_TEST_CHANGES=1 set — reporting only" >&2
    exit 0
fi

echo "check-test-diff: failed. Test changes belong in their own commit;" >&2
echo "spec changes should be reviewable as spec changes, not implementation." >&2
exit 1
