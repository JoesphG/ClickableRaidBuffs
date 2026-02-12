#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

fail() {
  echo "release-check: ERROR: $*" >&2
  exit 1
}

warn() {
  echo "release-check: WARN: $*" >&2
}

require_file() {
  local f="$1"
  [[ -f "$f" ]] || fail "missing required file: $f"
}

require_file "ClickableRaidBuffs.toc"
require_file "RELEASE_NOTES.md"
require_file "CHANGELOG.txt"

VERSION="$(sed -n 's/^## Version:[[:space:]]*//p' ClickableRaidBuffs.toc | head -n1 | tr -d '\r' | xargs)"
[[ -n "$VERSION" ]] || fail "could not parse version from ClickableRaidBuffs.toc"
TAG="v${VERSION}"

echo "release-check: version from .toc = ${VERSION}"

grep -q "^# ClickableRaidBuffs ${TAG} Release Notes$" RELEASE_NOTES.md \
  || fail "RELEASE_NOTES.md title must be '# ClickableRaidBuffs ${TAG} Release Notes'"

CHANGELOG_CUR="$(awk '
  BEGIN { in_current = 0 }
  /CURRENT PATCH NOTES/ { in_current = 1; next }
  in_current && /^\*\*v?[0-9]+\.[0-9]+\.[0-9]+/ { gsub(/\*\*/, "", $0); print $0; exit }
' CHANGELOG.txt)"
[[ -n "$CHANGELOG_CUR" ]] || fail "could not parse current patch version from CHANGELOG.txt"
if [[ "$CHANGELOG_CUR" != v* ]]; then
  CHANGELOG_CUR="v${CHANGELOG_CUR}"
fi
[[ "$CHANGELOG_CUR" == "$TAG" ]] || fail "CHANGELOG current patch is '${CHANGELOG_CUR}', expected '${TAG}'"

RN_BODY="$(tail -n +2 RELEASE_NOTES.md)"

if grep -Eqi 'https?://|www\.' <<<"$RN_BODY"; then
  fail "RELEASE_NOTES.md body must not include links"
fi

while IFS= read -r line; do
  [[ -z "$line" ]] && continue
  [[ "$line" =~ ^-\  ]] || fail "RELEASE_NOTES.md body must be bullet-only; invalid line: $line"
done <<<"$RN_BODY"

echo "release-check: release notes format OK (functional bullet points only, no links)"

echo "release-check: required GitHub secrets reminder:"
echo "  - WAGO_API_TOKEN"
echo "  - DISCORD_WEBHOOK_URL"

if command -v gh >/dev/null 2>&1; then
  if SECRETS="$(gh secret list 2>/dev/null)"; then
    if ! grep -q '^WAGO_API_TOKEN[[:space:]]' <<<"$SECRETS"; then
      warn "GitHub secret missing: WAGO_API_TOKEN"
    fi
    if ! grep -q '^DISCORD_WEBHOOK_URL[[:space:]]' <<<"$SECRETS"; then
      warn "GitHub secret missing: DISCORD_WEBHOOK_URL"
    fi
  else
    warn "unable to query GitHub secrets via gh; verify secrets manually"
  fi
else
  warn "gh CLI not found; verify secrets manually"
fi

echo "release-check: OK"
