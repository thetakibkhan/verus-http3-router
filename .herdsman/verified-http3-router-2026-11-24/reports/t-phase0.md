STATUS: complete — Phase 0 acceptance evidence passed and independently reviewed
needs: nothing for Phase 0 acceptance; P1–P8 remain later-phase work.
branch: `local/t-phase0-spike`
worktree: Phase 0 worktree
base commit: `967f685edf69c358a21bea7e9f329d7e6800b06b`
replay source commit: `e757847dfced9dab426e13f39d25d2a766033b16`
head commit at this edit: `6ce6889d0bbc49a5478d618176e266db1b90ebfa`
clean-container evidence (prior log): `.herdsman/verified-http3-router-2026-11-24/reports/t-phase0-logs/clean-container-e757847.log`; provenance: `.herdsman/verified-http3-router-2026-11-24/reports/t-phase0-logs/clean-container-e757847-provenance.log`
changed files: `.gitignore`, `Cargo.toml`, `Cargo.lock`, `rust-toolchain.toml`, `README.md`, `.github/workflows/phase0-proof.yml`
- `crates/verified-router/{Cargo.toml,src/lib.rs}`, `crates/tquic-adapter/{Cargo.toml,src/lib.rs}`, `examples/http3-server/{Cargo.toml,src/main.rs,probe.py}`
- `proofs/toolchain-smoke.rs`, `scripts/{install-verus.sh,check-proof.sh,check-proof-ci.sh,check-http3-demo.sh}`
- Local evidence under `.herdsman/verified-http3-router-2026-11-24/reports/t-phase0-logs/` and this report. The concurrent `00-route.md` change is outside this patch.

## Verification evidence

- Local checks ran serially through `W=.herdsman/verified-http3-router-2026-11-24/run-check.sh`, invoked as `bash "$W" <command>`. Below, `L=.herdsman/verified-http3-router-2026-11-24/reports/t-phase0-logs`.
- Ubuntu 24.04.3 LTS x86-64. Rust `1.100.0 (0ef1bc386 2026-11-09)`, Cargo `1.100.0 (3acc79c0c 2026-11-05)`, Verus `0.2026.11.22.1ce6a59` at `1ce6a59bd72713cf486a7660097fe5ac57519617`, Z3 `4.16.0` 64-bit.
- `cargo tree --locked -p http3-server --depth 1` exit 0. TQUIC `1.6.0` is published from `d87a9a072475e381e64bfeb5732f2f505c2c28b7` per package VCS metadata. `Cargo.lock` SHA-256 `d2dcb76d3d2e788aef46dca4e2b66433c9b04bfaca7c09f8cd41dfc653af38d6`. See `cargo-tree.log` and `versions-platform.log`.
- CMake `3.31.10`, GCC `13.3.0`, OpenSSL `3.0.13`, Python `3.12.3`, aioquic `1.3.0`. `bash scripts/install-verus.sh .phase0-tools/fresh-verus` downloaded and verified its archive, exit 0.
- `cargo +stable test --ignore-rust-version --offline -j 1 -p http3-server` before implementation, exit 101 with missing `render_headers`. Bootstrap `cargo +stable build --ignore-rust-version -j 1` exit 0, used to generate the lockfile and check compilation.
- `cargo build --workspace --locked -j 1` twice with pinned Rust, exit 0 both times, 54 compile entries and all three workspace packages in each run. The second run started with empty `CARGO_HOME=.phase0-tools/clean-cargo` and `CARGO_TARGET_DIR=target/phase0-repro`. See `cargo-build.log` and `clean-cargo-build.log`.
- `cargo test --workspace --locked --offline -j 1 -- --test-threads=1` twice, exit 0 each, 1 passed and 0 failed each. Both scaffold libraries have zero unit and doc tests. See `cargo-test.log` and `clean-cargo-test.log`.
- `bash scripts/check-proof.sh valid` exit 0, 1 verified and 0 errors. `bash scripts/check-proof.sh invalid` exit 1, 0 verified and 1 failed postcondition. Both invoke `verus --crate-type lib --num-threads 1` on their respective sources.
- `bash scripts/check-proof-ci.sh "$L/proof"` and `bash scripts/check-proof-ci.sh "$L/fresh-proof"` each exited 0 with the positive/negative counts above. The second used the fresh archive via `VERUS_DIR`. Logs include verifier version, Rust/Z3 versions, worktree base revision and proof SHA-256. Workflow YAML parsed with its proof and artifact steps present, exit 0.
- `bash scripts/check-http3-demo.sh "$L/demo"` and `bash scripts/check-http3-demo.sh "$L/clean-demo"` each exited 0 with one HTTP/3 204 and one TQUIC `Headers` event on stream 0, `fin=true`. Both matched all seven fields in byte order, including `x-repeat: first`, `x-marker: ff` and `x-repeat: last`.
- `cargo fmt --all`, `cargo fmt --all -- --check`, `bash -n` on each of the four added shell scripts and `git diff --check` exited 0.

## Suggested atomic Conventional Commit groups

1. `feat: scaffold the Rust workspace and demonstrate HTTP/3 headers` (US-001, US-002, US-004) — `.gitignore`, `Cargo.toml`, `Cargo.lock`, `rust-toolchain.toml`, both `crates/` scaffolds, `examples/http3-server/`, `scripts/check-http3-demo.sh`.
2. `ci: verify the pinned Verus smoke proof and reject its invalid variant` (US-002, US-003) — `.github/workflows/phase0-proof.yml`, `proofs/toolchain-smoke.rs`, `scripts/{install-verus.sh,check-proof.sh,check-proof-ci.sh}`.
3. `docs: document Phase 0 setup and reproduction` (US-001 through US-005) — `README.md`.

decisions: The standalone Verus release verifies the bounded increment without a Cargo proof dependency. TQUIC comes from the checksummed crates.io release. The server records the ordered `Vec<Header>` through byte-slice accessors. Kernel and adapter are scaffolds. P1–P8 remain open.

handoff: Review the unstaged worktree and retained logs. README contains setup and replay commands. GitHub Actions is configured to publish version and proof logs keyed by the checked SHA. Clean-container evidence is now recorded below; obtain the hosted artifact before signing off US-005.

gaps:
- US-001 and US-004 acceptance checks passed locally. US-002 has pins and a fresh-cache replay on the existing Ubuntu host. **Clean-machine/container gap closed (US-002 AC3)** by the Ubuntu 24.04 replay below; evidence in `.herdsman/verified-http3-router-2026-11-24/reports/t-phase0-logs/clean-container-e757847.log` and the provenance correction below. The launch-time bwrap limitation was: `bash "$W" bwrap --unshare-user --unshare-pid --ro-bind / / --dev /dev --proc /proc -- /bin/true` exited 1 with “No permissions to create new namespace.”
- With workspace-local `RUSTUP_HOME` and `CARGO_HOME`, `rustup toolchain install 1.100.0 --profile minimal --component rustfmt` installed the toolchain then exited 1 on the self-update probe at read-only `/usr/bin/updtest2tMMi5`. Adding `--no-self-update` exited 0, including installation into a fresh Rustup home with checksum-verified component downloads.
- `python3 -m pip install --no-cache-dir --only-binary=:all: --target .phase0-tools/repro-cmake cmake==3.31.10` exited 1 after PyPI index timeouts. The README uses the direct SHA-256-checked wheel. Extraction exited 0 and `cmp` confirmed the CMake binary matches the one used for the builds.
- At the time of the local run, US-003 had real proof pass/fail evidence from the local CI script; hosted workflow execution and artifact publication were pending under the local-only constraint. The hosted run was later authorized and is recorded below.

## Audit rerun (2026-11-24, additive)

Static audit found no P0/P1 code defect in the Phase 0 tree. Corrected one integrity defect: `TCB.md` still said no code existed and that no build/test/Verus run had been performed; it now records the Phase 0 baseline and keeps P1–P8 open. No trust claim or exemption changed.

- Reproduced with repo-local roots only: `RUSTUP_HOME=.phase0-tools/rustup`, `CARGO_HOME=.phase0-tools/cargo`, `CARGO_TARGET_DIR=target/phase0-audit`, toolchain `1.100.0` on `PATH`; dependencies offline from the provisioned registry. No user-home toolchain state was used.
- `cargo build --workspace --locked --offline -j 1` exit 0 from an empty target (50.52s). `cargo test --workspace --locked --offline -j 1 -- --test-threads=1` exit 0, 1 passed / 0 failed.
- `bash scripts/check-proof.sh versions` exit 0: Rust `1.100.0`, Verus `0.2026.11.22.1ce6a59`, Z3 `4.16.0`, proof SHA-256 `cd36e39c297f2b1ade6b9215de392de1a96330669013138625c26f556933af13`. `valid` exit 0, `1 verified, 0 errors`; `invalid` exit 1, `0 verified, 1 errors`, postcondition failure.
- `bash scripts/check-proof-ci.sh <audit>/ci` exit 0 with `PASS: valid proof verified and invalid proof rejected`; this is the same negative-control path the workflow invokes.
- `bash scripts/check-http3-demo.sh` exit 0 against the fresh target: aioquic `1.3.0`, HTTP/3 204, one `Headers` event, 7 fields in exact byte order including `x-repeat`/`x-marker`/`x-repeat`.
- `cargo fmt --all -- --check`, `git diff --check`, `bash -n` on all four scripts, workflow YAML parse, and `py_compile` exit 0. No `assume`/`external_body`/`assume_specification` in the tree.
- Logs: `.herdsman/verified-http3-router-2026-11-24/reports/t-phase0-logs/audit-2026-11-24/`. Audit delta: `TCB.md` status/assumption log plus these additive logs; the code tree is unchanged.
- Still open at audit time: hosted GitHub Actions execution/artifact and an independent clean Ubuntu 24.04 machine/container replay. The clean-container part is now closed by the replay section below; hosted CI remains open. `docker` CLI and daemon are present, but a genuine clean replay needs network provisioning outside the worktree, so it was not run under this audit's no-download constraint.

## Clean-container replay (closing evidence, commit e757847)

Independent clean-machine/container acceptance is now satisfied locally; hosted CI/artifact publication remains the only Phase 0 acceptance blocker. P1–P8 remain unclaimed.

- Image `ubuntu:24.04`, digest `sha256:562111b88caa79c71391c0c4d3c2114a7d5c35915c20561fd893cb1e07929e6b`; prior tar-based working-tree snapshot hash `d7f01b9cf7e06b71a048e1c0bf19f8559247813bc74335cc0333dc9fc5e91b7e` (superseded by the canonical manifest in the provenance correction below), excluding `.git`, `.phase0-tools`, `target`, `.herdsman`, `.commandcode`.
- Isolation: snapshot mounted read-only at `/src` and copied to ephemeral `/work`; no host-home mount, no `.git` mount, no Docker socket; `--rm` container verified removed.
- Bootstrap: Ubuntu 24.04 apt prerequisites, Rust `1.100.0` + rustfmt, Verus `0.2026.11.22.1ce6a59`, Z3 `4.16.0`, CMake `3.31.10` wheel, aioquic `1.3.0`, crates.io dependencies.
- Outcomes: `cargo build --workspace --locked -j 1` exit 0; `cargo test --workspace --locked --offline -j 1 -- --test-threads=1` exit 0, 1 passed / 0 failed; Verus `valid` exit 0, `1 verified, 0 errors`; `invalid` exit 1, `0 verified, 1 errors`, postcondition failure; `check-proof-ci.sh` exit 0, `PASS: valid proof verified and invalid proof rejected`; `check-http3-demo.sh` exit 0, aioquic `1.3.0`, HTTP/3 204, one `Headers` event, 7 fields in exact byte order; `cargo fmt --all -- --check` exit 0.
- Evidence (prior run): `.herdsman/verified-http3-router-2026-11-24/reports/t-phase0-logs/clean-container-e757847.log` (950 lines). Its `Checked repository revision: e757847...` came from the host-supplied `GITHUB_SHA` in a `.git`-free container and is not provenance by itself; see the provenance correction below.
- At the time of this clean-container replay, hosted GitHub Actions execution/artifact publication remained open. That item was later completed by the run recorded below; US-003/US-005 completion awaits independent review of the hosted run and artifact.

## Provenance correction (2026-11-24)

The prior log's revision label was a host-supplied environment value and its source hash was a tar-based working-tree hash; neither establishes commit provenance. Provenance is now established independently, and the replay was rerun from the commit tree.

- Source commit: `e757847dfced9dab426e13f39d25d2a766033b16`. Extraction: `git -c tar.umask=0022 archive --format=tar <commit> | tar -x -p -C <snap>`, then `rm -rf <snap>/.herdsman`. The container had no `.git`; no Git metadata was mounted.
- Sanitization: excluded `.git/**` (absent), `.phase0-tools/**`, `target/**`, `.herdsman/**`, `.commandcode/**`; included 22 regular files.
- Manifest algorithm: `LC_ALL=C; find . -type f -printf '%P\0' | sort -z`; SHA-256 each file; emit `<sha256>  <path>`; SHA-256 the resulting manifest. Per-file manifest: `.herdsman/verified-http3-router-2026-11-24/reports/t-phase0-logs/clean-container-e757847.manifest.txt`.
- Manifest SHA-256: `87721388b91464a82b4ef117ddf9a84935c09c18098d1d2498631015e2ebba70`. Cross-check: byte-identical to a manifest computed from `git cat-file blob e757847:<path>` for every included path; all 22 file modes also match `git ls-tree` (`100644`).
- Replay: image `ubuntu:24.04@sha256:562111b88caa79c71391c0c4d3c2114a7d5c35915c20561fd893cb1e07929e6b`; the container's `GITHUB_SHA` was `source-manifest-sha256:87721388...` as a label only, not a Git revision claim. Exit 0: build, test (1 passed / 0 failed), Verus valid (`1 verified, 0 errors`), invalid (`0 verified, 1 errors`), proof-CI PASS, HTTP/3 demo PASS, fmt PASS.
- Evidence: `.herdsman/verified-http3-router-2026-11-24/reports/t-phase0-logs/clean-container-e757847-provenance.log` (host preamble plus full replay output); prior log `.herdsman/verified-http3-router-2026-11-24/reports/t-phase0-logs/clean-container-e757847.log` preserved.
- At the time of the provenance correction, hosted GitHub Actions execution/artifact publication remained open. The hosted workflow and artifact were later completed as recorded below; final independent review is pending. P1–P8 remain unclaimed.

## Hosted GitHub Actions run and artifact (2026-11-25)

- User authorized pushing only `local/t-phase0-spike` to the supplied repository to trigger the hosted proof workflow; no PR or Phase 1 push was made.
- Workflow: `Verus smoke proof`; run [45646863052](https://github.com/thetakibkhan/verus-http3-router/actions/runs/45646863052), triggered by push on `local/t-phase0-spike`, checked SHA `eedcc026b4b3c450fe247df95e812e620473ee82`; conclusion **success**.
- Steps passed: pinned Rust/Verus install; valid/invalid proof check; evidence artifact upload. The only annotation was GitHub's Node.js 20 deprecation notice for the pinned checkout/upload actions; it did not fail the run.
- Published artifact: `phase0-proof-eedcc026b4b3c450fe247df95e812e620473ee82`. Downloaded and preserved under `.herdsman/verified-http3-router-2026-11-24/reports/t-phase0-logs/hosted-run-45646863052/`: `versions.log`, `valid.log`, `invalid.log`.
- Artifact evidence: `valid.log` records `1 verified, 0 errors`, `valid_exit=0`; `invalid.log` records the expected postcondition failure, `0 verified, 1 errors`, `invalid_exit=1`; `versions.log` records the checked SHA, proof SHA-256, Rust/Cargo 1.100.0, Verus `0.2026.11.22.1ce6a59`, and Z3 4.16.0.
- SHA-256: `versions.log` `9a5b1d51a5ab15b22937ceeecf64ae92097f2cac5c47267a03a693b800ecf7d5`; `valid.log` `b2cb50f59eadc24330571d87a1fc0ff925021755ab683fbbcbc829d9a8dfdff1`; `invalid.log` `f92742c65bc68120c410651042a6a343accaabb112041fa4657566b989d60c6e`.
- The remote branch was absent before this push and now points at the checked SHA. The local Phase 0 worktree is clean. No force push, PR, or other branch push occurred.
- Independent review `review-hosted-phase0-1.md` returned **VERDICT: pass**, no P0/P1. It matched the checked SHA to the artifact name and versions log, confirmed the valid proof pass and invalid proof rejection, verified all three artifact hashes, and found the Node.js deprecation notice nonblocking.
- US-001..US-005 Phase 0 acceptance is complete: local workspace/toolchain/demo checks, clean-container replay, and hosted proof workflow/artifact all have passing evidence. P1–P8 remain unclaimed for later phases. The separate Phase 1/E02 gates are unchanged.
