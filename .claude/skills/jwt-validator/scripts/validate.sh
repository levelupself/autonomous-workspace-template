#!/usr/bin/env bash
# .claude/skills/jwt-validator/scripts/validate.sh
# Validates a JWT RS256 token using only openssl (no node/python deps)
# Usage: ./validate.sh <jwt-token> <public-key.pem>
# Exit 0 = valid, Exit 1 = invalid/expired, Exit 2 = usage error

set -euo pipefail

if [[ $# -lt 2 ]]; then
  echo "Usage: validate.sh <jwt-token> <public-key.pem>" >&2
  exit 2
fi

JWT="$1"
PUBKEY="$2"

if [[ ! -f "$PUBKEY" ]]; then
  echo "ERROR: Public key not found: $PUBKEY" >&2
  exit 2
fi

# ── Base64url decode helper ───────────────────────────────────────────────────
b64url_decode() {
  local input="$1"
  # Add padding
  local rem=$(( ${#input} % 4 ))
  if [[ $rem -eq 2 ]]; then input="${input}=="; fi
  if [[ $rem -eq 3 ]]; then input="${input}="; fi
  # Replace URL-safe chars and decode
  echo "$input" | tr '_-' '/+' | base64 -d 2>/dev/null
}

# ── Split JWT ─────────────────────────────────────────────────────────────────
IFS='.' read -r HEADER_B64 PAYLOAD_B64 SIG_B64 <<< "$JWT"

if [[ -z "$HEADER_B64" ]] || [[ -z "$PAYLOAD_B64" ]] || [[ -z "$SIG_B64" ]]; then
  echo "ERROR: malformed JWT — expected 3 dot-separated segments" >&2
  exit 1
fi

# ── Decode header ─────────────────────────────────────────────────────────────
HEADER=$(b64url_decode "$HEADER_B64")
ALG=$(echo "$HEADER" | grep -oP '"alg"\s*:\s*"\K[^"]+' 2>/dev/null || echo "")

if [[ "$ALG" != "RS256" ]]; then
  echo "ERROR: expected RS256 algorithm, got: $ALG" >&2
  exit 1
fi

# ── Decode payload ────────────────────────────────────────────────────────────
PAYLOAD=$(b64url_decode "$PAYLOAD_B64")

# Check expiry if exp claim present
EXP=$(echo "$PAYLOAD" | grep -oP '"exp"\s*:\s*\K[0-9]+' 2>/dev/null || echo "")
if [[ -n "$EXP" ]]; then
  NOW=$(date +%s)
  if (( NOW > EXP )); then
    echo "ERROR: token expired at $(date -d @$EXP 2>/dev/null || date -r $EXP)" >&2
    exit 1
  fi
fi

# ── Verify signature ──────────────────────────────────────────────────────────
SIGNING_INPUT="${HEADER_B64}.${PAYLOAD_B64}"
SIG_DER=$(b64url_decode "$SIG_B64" | xxd -p | tr -d '\n' 2>/dev/null || echo "")

# Write signature to temp file
TMP_SIG=$(mktemp)
TMP_MSG=$(mktemp)
trap 'rm -f "$TMP_SIG" "$TMP_MSG"' EXIT

b64url_decode "$SIG_B64" > "$TMP_SIG"
echo -n "$SIGNING_INPUT" > "$TMP_MSG"

# Verify with openssl
if openssl dgst -sha256 -verify "$PUBKEY" -signature "$TMP_SIG" "$TMP_MSG" > /dev/null 2>&1; then
  # Print decoded payload on success
  echo "$PAYLOAD"
  exit 0
else
  echo "ERROR: signature verification failed" >&2
  exit 1
fi
