#!/usr/bin/env bash
set -euo pipefail

verus_dir=${VERUS_DIR:-.phase0-tools/verus-x86-linux}
proof=proofs/toolchain-smoke.rs
verus_revision=1ce6a59bd72713cf486a7660097fe5ac57519617
export VERUS_Z3_PATH="$verus_dir/z3"

verify() {
    "$verus_dir/verus" --crate-type lib --num-threads 1 "$1"
}

case "${1:-}" in
    valid)
        verify "$proof"
        ;;
    invalid)
        # Change one postcondition and preserve the executable body.
        mkdir -p target
        temp=$(mktemp -d target/invalid-proof.XXXXXX)
        trap 'rm -rf "$temp"' EXIT
        sed 's/result == value + 1/result == value + 2/' "$proof" > "$temp/invalid.rs"
        if cmp -s "$proof" "$temp/invalid.rs"; then
            echo 'Could not create the invalid proof' >&2
            exit 1
        fi
        verify "$temp/invalid.rs"
        ;;
    versions)
        if [[ -n "${GITHUB_SHA:-}" ]]; then
            printf 'Checked repository revision: %s\n' "$GITHUB_SHA"
        else
            printf 'Local worktree base revision: %s\n' "$(git rev-parse HEAD)"
        fi
        sha256sum "$proof"
        printf 'Pinned Verus revision: %s\n' "$verus_revision"
        rustc --version --verbose
        cargo --version
        "$verus_dir/verus" --version
        "$VERUS_Z3_PATH" --version
        ;;
    *)
        echo 'usage: check-proof.sh valid|invalid|versions' >&2
        exit 2
        ;;
esac
