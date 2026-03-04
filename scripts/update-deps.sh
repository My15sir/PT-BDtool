#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LOCK_FILE="${LOCK_FILE:-$SCRIPT_DIR/deps.env}"
DRY_RUN=1
[[ "${1:-}" == "--apply" ]] && DRY_RUN=0

sha256_file() {
  if command -v sha256sum >/dev/null 2>&1; then
    sha256sum "$1" | awk '{print $1}'
  else
    shasum -a 256 "$1" | awk '{print $1}'
  fi
}

tmp_file="$(mktemp)"
trap 'rm -f "$tmp_file" "$tmp_file.new"' EXIT

cp -f "$LOCK_FILE" "$tmp_file"
: > "$tmp_file.new"

while IFS='|' read -r name version url sha256 target; do
  if [[ -z "${name:-}" || "$name" =~ ^# ]]; then
    printf '%s\n' "${name}${version:+|$version}${url:+|$url}${sha256:+|$sha256}${target:+|$target}" >> "$tmp_file.new"
    continue
  fi

  if [[ "$url" == system://* ]]; then
    printf '%s|%s|%s|%s|%s\n' "$name" "$version" "$url" "$sha256" "$target" >> "$tmp_file.new"
    continue
  fi

  tmp_dl="$(mktemp)"
  if command -v curl >/dev/null 2>&1; then
    curl -fL --connect-timeout 10 -o "$tmp_dl" "$url"
  else
    wget -O "$tmp_dl" "$url"
  fi
  new_sha="$(sha256_file "$tmp_dl")"
  rm -f "$tmp_dl"

  if [[ "$new_sha" != "$sha256" ]]; then
    printf '[update-deps] %s sha update: %s -> %s\n' "$name" "$sha256" "$new_sha"
  fi
  printf '%s|%s|%s|%s|%s\n' "$name" "$version" "$url" "$new_sha" "$target" >> "$tmp_file.new"
done < "$tmp_file"

if [[ "$DRY_RUN" == "1" ]]; then
  echo "[update-deps] dry-run complete; no file written"
else
  cp -f "$tmp_file.new" "$LOCK_FILE"
  echo "[update-deps] applied to $LOCK_FILE"
fi
