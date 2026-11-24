# Verified HTTP/3 Router

This workspace contains the Phase 0 toolchain proof and loopback HTTP/3 demo.

| Package | Responsibility | Verification status |
| --- | --- | --- |
| `verified-router` | Synchronous routing kernel scaffold | Kernel proofs are pending |
| `tquic-adapter` | TQUIC-to-kernel integration scaffold | Outside the verification boundary |
| `http3-server` | Loopback QUIC/TLS server that records incoming HTTP/3 headers | Covered by the header-log test and demo probe |

The standalone Verus smoke proof verifies one bounded increment. P1–P8 remain open.

## Linux x86-64 setup

Use Ubuntu 24.04 with Rustup, GCC/G++, GNU Make, Git, curl, unzip, OpenSSL,
Python 3.12 and pip. For an existing Ubuntu runner, all project tooling can
live under the checkout. From its root, run these commands in one shell.

```bash
mkdir -p .phase0-tools
export RUSTUP_HOME="$PWD/.phase0-tools/rustup"
export CARGO_HOME="$PWD/.phase0-tools/cargo"
rustup toolchain install 1.100.0 --profile minimal --component rustfmt --no-self-update
bash scripts/install-verus.sh
curl --fail --location --retry 3 --output .phase0-tools/cmake.whl \
  'https://files.pythonhosted.org/packages/f4/2e/cefc60143950ca1a8dda26d4c8484e6fc406db16e7ca098ebae549de35f9/cmake-3.31.10-py3-none-manylinux_2_17_x86_64.manylinux2014_x86_64.whl'
printf '%s  %s\n' 2f766bb46367e5e0559fa33184653754bce044583a06014dcaebf8e6dff8a1f1 \
  .phase0-tools/cmake.whl | sha256sum --check - && \
  unzip -oq .phase0-tools/cmake.whl -d .phase0-tools/cmake
export CMAKE="$PWD/.phase0-tools/cmake/cmake/data/bin/cmake"
export CMAKE_BUILD_PARALLEL_LEVEL=1
```

`--no-self-update` keeps Rustup from writing to the executable's installation
directory. CMake builds TQUIC's bundled BoringSSL, so its executable must be available before
the first Cargo build. Rustup, GitHub Releases, PyPI and the Cargo registry supply setup artifacts.

| Component | Pin |
| --- | --- |
| Rust | `1.100.0-x86_64-unknown-linux-gnu`, selected by `rust-toolchain.toml` |
| Verus | `0.2026.11.22.1ce6a59` at `1ce6a59bd72713cf486a7660097fe5ac57519617`, SHA-256 checked by the install script |
| Z3 | `4.16.0`, from the same checked Verus archive |
| TQUIC | crates.io `1.6.0` at `d87a9a072475e381e64bfeb5732f2f505c2c28b7`, checksum and dependency graph in `Cargo.lock` |

Version checks and verification from the root:

```bash
bash scripts/check-proof.sh versions
"$CMAKE" --version
cargo tree --locked -p http3-server --depth 1
cargo build --workspace --locked -j 1
cargo test --workspace --locked --offline -j 1 -- --test-threads=1
bash scripts/check-proof-ci.sh
```

To check the exact TQUIC source revision on disk, run the following after the Cargo build.
The package's VCS metadata contains the full commit recorded above.

```bash
find "$CARGO_HOME/registry/src" -path '*/tquic-1.6.0/.cargo_vcs_info.json' -exec cat {} \;
```

The proof CI script writes versions plus positive and negative verifier logs in
`target/phase0-proof/`. The negative control changes only the postcondition.
The raw invalid invocation, `bash scripts/check-proof.sh invalid`, must exit
1 with a postcondition diagnostic. CI also fails if the positive proof fails
or the negative control yields an unexpected outcome.

## Reproduce the HTTP/3 Headers event

After the build, install the demo client and run the loopback probe:

```bash
python3 -m pip install --no-cache-dir --only-binary=:all: \
  --target .phase0-tools/aioquic 'aioquic==1.3.0'
export PYTHONPATH="$PWD/.phase0-tools/aioquic${PYTHONPATH:+:$PYTHONPATH}"
bash scripts/check-http3-demo.sh
```

The script generates a temporary loopback certificate, starts the demo on an
ephemeral UDP port, and uses an aioquic 1.3.0 client to send a bodyless GET for
`/phase0?probe=1`. The client trusts the generated certificate, requires HTTP
204, and compares the server's entire `Headers` event against the seven fields
it sent. The log shows the repeated `x-repeat` fields separated by `x-marker`
with value byte `ff`. Logs are saved in `target/phase0-demo/`, and the script
cleans up the server and private key on exit.

At TQUIC 1.6.0, `Http3Connection::poll` returns the stream ID and
`Http3Event::Headers { headers: Vec<Header>, fin }`. `NameValue::name` and
`NameValue::value` expose byte slices borrowed from each field. Feed them to
the future kernel in event order, keeping duplicates and bytes intact. An
adapter must keep the event alive while borrowing, or copy into an owned
ordered list if the data must outlive the event. TQUIC owns HTTP/3 framing and
QPACK decoding and leaves header semantics to the application. The demo reads
the list directly and renders each pair in hexadecimal for inspection.
[TQUIC 1.6.0 Headers API](https://docs.rs/tquic/1.6.0/tquic/h3/enum.Http3Event.html)
