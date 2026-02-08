#!/bin/bash
set -euo pipefail

# Start tailscaled in background (userspace networking, no TUN device needed)
tailscaled --tun=userspace-networking --statedir=/var/lib/tailscale &

# Wait for tailscaled socket to be ready
for i in $(seq 1 30); do
  if tailscale status >/dev/null 2>&1; then break; fi
  sleep 1
done

# Authenticate (only if TS_AUTHKEY is set; no-op if already logged in from persisted state)
if [ -n "${TS_AUTHKEY:-}" ]; then
  tailscale up --authkey="$TS_AUTHKEY" --hostname="${TS_HOSTNAME:-openclaw-docker}"
elif ! tailscale status >/dev/null 2>&1; then
  echo "ERROR: Not logged in and no TS_AUTHKEY provided" >&2
  exit 1
fi

echo "Tailscale up: $(tailscale ip -4)"

# Start the gateway (exec replaces this shell so node becomes PID 1)
exec node dist/index.js gateway --allow-unconfigured --tailscale serve
