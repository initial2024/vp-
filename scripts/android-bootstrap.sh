#!/usr/bin/env bash
# Android Termux only: check config and copy it to public Download.
# No SSH password, token or host address is saved here.
set -euo pipefail
if ! command -v pkg >/dev/null 2>&1 || ! command -v termux-setup-storage >/dev/null 2>&1; then
  echo "ERROR: Run this in Android Termux, not the Altare web Console." >&2
  exit 2
fi
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
echo "[1/4] Install dependencies ..."
pkg install -y git openssh curl python
echo "[2/4] Validate JSON ..."
python3 "$ROOT/scripts/validate-config.py"
echo "[3/4] Request Android storage access if needed ..."
if [[ ! -d "$HOME/storage/downloads" ]]; then
  termux-setup-storage
fi
if [[ ! -d "$HOME/storage/downloads" ]]; then
  echo "Storage permission missing. Allow Termux files access and rerun." >&2
  exit 3
fi
mkdir -p "$HOME/storage/downloads/vp-"
cp -f "$ROOT/configs/AL-SSH-TCP-DNS-fixed.json" "$HOME/storage/downloads/vp-/AL-SSH-TCP-DNS-fixed.json"
echo "[4/4] DONE: Download/vp-/AL-SSH-TCP-DNS-fixed.json"
echo "NEXT: bash scripts/start-tunnel.sh root YOUR_ALTARE_SSH_HOST YOUR_ALTARE_SSH_PORT"
