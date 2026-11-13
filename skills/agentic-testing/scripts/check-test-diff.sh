#!/usr/bin/env bash
# check-test-diff.sh — flag suspicious test changes in a diff.
#
# Tests are the executable spec: they change only when the spec changes.
# This script makes test tampering visible by failing when a diff since
# BASE modifies or deletes test files, removes assertion lines, or adds
# skip markers. Added test files are allowed (reported as info).
#
# Usage:
#   check-test-diff.sh BASE [--head REF] [--path PATH]...
#
#   BASE        ref to diff against (e.g. origin/main, HEAD~1)
#   --head REF  ref for the "new" side (default: HEAD)
#   --path P    restrict the diff to PATH (repeatable)
#
# Exit codes: 0 = clean or only allowed changes, 1 = suspicious changes.
# Escape hatch for legitimate spec changes: ALLOW_TEST_CHANGES=1 — but
# prefer landing spec/test changes in their own commit instead.
#
# Test-file detection covers common layouts: tests/ dirs, test_*.py,
# *_test.*, *.test.*, *.spec.*. Extend TEST_GLOBS if needed.

set -euo pipefail

BASE=""
HEAD_REF="HEAD"
PATHS=()

while [ $# -gt 0 ]; do
    case "$1" in
        --head) HEAD_REF="$2"; shift 2 ;;
        --path) PATHS+=("$2"); shift 2 ;;
        -h|--help) sed -n '2,30p' "$0"; exit 0 ;;
        -*) echo "unknown option: $1" >&2; exit 2 ;;
        *) BASE="$1"; shift ;;
    esac
done

[ -n "$BASE" ] || { echo "usage: $0 BASE [--head REF] [--path PATH]..." >&2; exit 2; }

is_test_file() {
    # $1 = path. Match test dirs and common test file naming.
    case "$1" in
        */tests/*|tests/*|test/*|*/test/*) return 0 ;;
        test_*.py|*_test.py|test_*.rb|*_test.rb|*_test.go|*_test.java) return 0 ;;
        *.test.*|*.spec.*|*_test.*) return 0 ;;
    esac
    return 1
}

range="${BASE}...${HEAD_REF}"
diff_args=(diff --name-status -U0 "$range")
[ ${#PATHS[@]} -gt 0 ] && diff_args+=("--" "${PATHS[@]}")

fail=0
modified_tests=()
deleted_tests=()
added_tests=()
assertion_removals=()
skip_additions=()
test_fn_removed=0
test_fn_added=0

while IFS=$'\t' read -r status file1 file2; do
    path="${file2:-$file1}"
    is_test_file "$path" || continue
    case "$status" in
        M*) modified_tests+=("$path") ;;
        D*) deleted_tests+=("$path") ;;
        A*|\?*) added_tests+=("$path") ;;
    esac
done < <(git "${diff_args[@]}")

# Scan changed lines in modified test files for removed assertions,
# added skips, and test-function count changes.
for f in "${modified_tests[@]}" "${deleted_tests[@]}"; do
    [ -f "$f" ] || continue
    while IFS= read -r line; do
        case "$line" in
            -\?*) ;;  # diff metadata, skip
            -*)
                content="${line:1}"
                case "$content" in
                    *assert*|*expect\(*|*should.*|*verify\(*|*t.Fatal*|*require.*)
                        assertion_removals+=("$f: ${content:0:80}") ;;
                esac
                case "$content" in
                    *"def test_"*|*"it("*|*"test("*|*"describe("*)
                        test_fn_removed=$((test_fn_removed+1)) ;;
                esac
                ;;
            +*)
                content="${line:1}"
                case "$content" in
                    *skip*|*xfail*|*unittest.skip*|*@Disabled*|*.only\(*|*fit\(*|*fdescribe*|*--ignore*)
                        skip_additions+=("$f: ${content:0:80}") ;;
                esac
                case "$content" in
                    *"def test_"*|*"it("*|*"test("*|*"describe("*)
                        test_fn_added=$((test_fn_added+1)) ;;
                esac
                ;;
        esac
    done < <(git diff -U0 "$range" -- "$f" 2>/dev/null | grep -E '^[+-]' | grep -vE '^\+\+\+|^---' || true)
done

report() {
    echo "check-test-diff: $1" >&2
}

if [ ${#deleted_tests[@]} -gt 0 ]; then
    report "FAIL — test files deleted:"
    printf '  %s\n' "${deleted_tests[@]}" >&2
    fail=1
fi

if [ ${#modified_tests[@]} -gt 0 ]; then
    report "FAIL — test files modified (spec changes belong in their own commit):"
    printf '  %s\n' "${modified_tests[@]}" >&2
    fail=1
fi

if [ ${#assertion_removals[@]} -gt 0 ]; then
    report "FAIL — assertion lines removed:"
    printf '  %s\n' "${assertion_removals[@]:0:20}" >&2
    [ ${#assertion_removals[@]} -gt 20 ] && echo "  ... and $(( ${#assertion_removals[@]} - 20 )) more" >&2
    fail=1
fi

if [ ${#skip_additions[@]} -gt 0 ]; then
    report "FAIL — skip markers added:"
    printf '  %s\n' "${skip_additions[@]:0:20}" >&2
    [ ${#skip_additions[@]} -gt 20 ] && echo "  ... and $(( ${#skip_additions[@]} - 20 )) more" >&2
    fail=1
fi

if [ $test_fn_removed -gt $test_fn_added ]; then
    report "WARN — test functions removed ($test_fn_removed) exceed added ($test_fn_added); verify coverage wasn't dropped"
fi

if [ ${#added_tests[@]} -gt 0 ]; then
    report "info — new test files added (ok if this is the spec/tests commit):"
    printf '  %s\n' "${added_tests[@]:0:10}" >&2
fi

if [ "$fail" -eq 0 ]; then
    echo "check-test-diff: clean — no suspicious test changes in ${range}"
    exit 0
fi

if [ "${ALLOW_TEST_CHANGES:-0}" = "1" ]; then
    echo "check-test-diff: ALLOW_TEST_CHANGES=1 set — reporting only" >&2
    exit 0
fi

echo "check-test-diff: failed. If these are legitimate spec changes," >&2
echo "land them in their own commit and re-run against that commit's parent." >&2
exit 1
