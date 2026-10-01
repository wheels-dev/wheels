# shellcheck shell=bash
# sha256 helpers for the RustCFML engine binaries, shared by run-suite.sh and
# bump-pin.sh. Source this file; don't run it.

# rustcfml_release_digests <tag>: one "<asset> <digest>" line per asset of that
# RustCFML release, as the GitHub API publishes them (needs gh + GH_TOKEN).
rustcfml_release_digests() {
  gh api "repos/RustCFML/RustCFML/releases/tags/$1" --jq '.assets[] | "\(.name) \(.digest)"'
}

# rustcfml_digest_sha256 <asset> <digests>: print the sha256 hex for <asset> from
# rustcfml_release_digests output. Fails unless there is exactly one digest for
# it and it is "sha256:<64 lowercase hex>".
rustcfml_digest_sha256() {
  local sha
  sha="$(awk -v a="$1" '$1 == a { print $2 }' <<<"$2" | sed -nE 's/^sha256:([0-9a-f]{64})$/\1/p')"
  [[ "$sha" =~ ^[0-9a-f]{64}$ ]] || return 1
  printf '%s\n' "$sha"
}

# rustcfml_pinned_sha256 <asset> <ENGINE_SHA256 file>: print the pinned sha256
# for <asset>. Fails unless the file has exactly one well-formed line for it.
rustcfml_pinned_sha256() {
  local sha
  sha="$(awk -v a="$1" '$2 == a { print $1 }' "$2")"
  [[ "$sha" =~ ^[0-9a-f]{64}$ ]] || return 1
  printf '%s\n' "$sha"
}

# rustcfml_file_sha256 <path>: print the sha256 hex of a file.
rustcfml_file_sha256() {
  local out
  if command -v sha256sum >/dev/null 2>&1; then
    out="$(sha256sum "$1")"
  else
    out="$(shasum -a 256 "$1")"
  fi
  printf '%s\n' "${out%% *}"
}
