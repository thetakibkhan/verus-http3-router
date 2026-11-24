#!/usr/bin/env bash
set -euo pipefail

logs=${1:-target/phase0-demo}
mkdir -p "$logs" target
temp=$(mktemp -d target/phase0-tls.XXXXXX)
server_pid=
cleanup() {
    if [[ -n "$server_pid" ]]; then
        kill "$server_pid" 2>/dev/null || true
        wait "$server_pid" 2>/dev/null || true
    fi
    rm -rf "$temp"
}
trap cleanup EXIT

openssl req -x509 -newkey rsa:2048 -nodes -days 1 -subj '/CN=127.0.0.1' \
    -addext 'subjectAltName=IP:127.0.0.1' -keyout "$temp/key.pem" -out "$temp/cert.pem" \
    > "$logs/certificate.log" 2>&1
"${CARGO_TARGET_DIR:-target}/debug/http3-server" "$temp/cert.pem" "$temp/key.pem" \
    > "$logs/server.log" 2> "$logs/server.stderr.log" &
server_pid=$!

port=
for ((attempt=0; attempt<100; attempt++)); do
    port=$(sed -n 's/^Listening on 127\.0\.0\.1:\([0-9][0-9]*\)$/\1/p' "$logs/server.log")
    [[ -z "$port" ]] || break
    if ! kill -0 "$server_pid" 2>/dev/null; then
        cat "$logs/server.stderr.log" >&2
        exit 1
    fi
    sleep 0.05
done
if [[ -z "$port" ]]; then
    echo 'HTTP/3 server did not announce its loopback port' >&2
    exit 1
fi

python3 examples/http3-server/probe.py "$port" "$temp/cert.pem" "$logs/server.log" \
    2>&1 | tee "$logs/client.log"
cat "$logs/server.log"
