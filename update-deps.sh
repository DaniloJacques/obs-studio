#!/bin/bash
# update-deps.sh — Fetch latest Tiger Lake deps from DaniloJacques/obs-deps fork
# and update CMakePresets.json with correct version and SHA256 hashes.
#
# Usage: ./update-deps.sh [VERSION]
#   VERSION: optional, defaults to latest release (e.g. 2026-02-10)
#
# Requirements: curl, jq, sha256sum

set -euo pipefail

REPO="DaniloJacques/obs-deps"
API="https://api.github.com/repos/${REPO}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PRESETS_FILE="${SCRIPT_DIR}/CMakePresets.json"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

log()  { echo -e "${GREEN}[✓]${NC} $*"; }
warn() { echo -e "${YELLOW}[!]${NC} $*"; }
err()  { echo -e "${RED}[✗]${NC} $*" >&2; }

# Check dependencies
for cmd in curl jq sha256sum; do
  if ! command -v "$cmd" &>/dev/null; then
    err "Required command '$cmd' not found. Install it first."
    exit 1
  fi
done

# Get version (latest release or user-specified)
if [ $# -ge 1 ]; then
  VERSION="$1"
  log "Using specified version: ${VERSION}"
else
  log "Fetching latest release from ${REPO}..."
  VERSION=$(curl -s "${API}/releases/latest" | jq -r '.tag_name')
  if [ -z "$VERSION" ] || [ "$VERSION" = "null" ]; then
    # Fallback: get first release from list
    VERSION=$(curl -s "${API}/releases?per_page=1" | jq -r '.[0].tag_name')
  fi
  if [ -z "$VERSION" ] || [ "$VERSION" = "null" ]; then
    err "No releases found in ${REPO}"
    exit 1
  fi
  log "Latest release: ${VERSION}"
fi

echo -e "\n${CYAN}=== Downloading release assets ===${NC}\n"

TMPDIR=$(mktemp -d)
trap "rm -rf $TMPDIR" EXIT

declare -A HASHES
BASE_URL="https://github.com/${REPO}/releases/download/${VERSION}"

for arch in x64 x86 arm64; do
  FILENAME="windows-deps-${VERSION}-${arch}.zip"
  URL="${BASE_URL}/${FILENAME}"

  echo -ne "  ${FILENAME}... "
  HTTP_CODE=$(curl -sL -o "${TMPDIR}/${FILENAME}" -w "%{http_code}" "${URL}")

  if [ "$HTTP_CODE" = "200" ]; then
    HASH=$(sha256sum "${TMPDIR}/${FILENAME}" | cut -d ' ' -f 1)
    HASHES["windows-${arch}"]="$HASH"
    echo -e "${GREEN}${HASH:0:16}...${NC}"
  else
    warn "Not found (HTTP ${HTTP_CODE}, skipping ${arch})"
    rm -f "${TMPDIR}/${FILENAME}"
  fi
done

# Check we got at least x64
if [ -z "${HASHES[windows-x64]:-}" ]; then
  err "Could not download windows-x64 deps. Aborting."
  err "Check if the release exists: ${BASE_URL}"
  exit 1
fi

echo -e "\n${CYAN}=== Updating CMakePresets.json ===${NC}\n"

# Backup
cp "$PRESETS_FILE" "${PRESETS_FILE}.bak"
log "Backup saved: CMakePresets.json.bak"

# Update using jq
UPDATED=$(jq --arg version "$VERSION" \
  --arg base_url "https://github.com/${REPO}/releases/download" \
  --arg hash_x64 "${HASHES[windows-x64]:-}" \
  --arg hash_x86 "${HASHES[windows-x86]:-}" \
  --arg hash_arm64 "${HASHES[windows-arm64]:-}" \
  '
  (.configurePresets[] | select(.name == "dependencies")
    .vendor."obsproject.com/obs-studio".dependencies.prebuilt) |=
    (
      .version = $version |
      .baseUrl = $base_url |
      if $hash_x64 != "" then .hashes."windows-x64" = $hash_x64 else . end |
      if $hash_x86 != "" then .hashes."windows-x86" = $hash_x86 else . end |
      if $hash_arm64 != "" then .hashes."windows-arm64" = $hash_arm64 else . end
    )
  ' "$PRESETS_FILE")

echo "$UPDATED" > "$PRESETS_FILE"

log "Updated prebuilt deps version: ${VERSION}"
log "Updated baseUrl: https://github.com/${REPO}/releases/download"

echo -e "\n${CYAN}=== Updated hashes ===${NC}\n"
for key in "${!HASHES[@]}"; do
  echo -e "  ${key}: ${GREEN}${HASHES[$key]}${NC}"
done

echo -e "\n${GREEN}Done!${NC} CMakePresets.json updated."
echo -e "Commit and push to trigger CI build with Tiger Lake deps."
echo -e "\nNote: Qt6 and CEF still point to official obsproject/obs-deps releases."
