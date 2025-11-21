#!/usr/bin/env bash
set -euo pipefail

# Upload release artifacts from dist/ to a selected git tag using GitHub CLI.

if ! command -v gh >/dev/null 2>&1; then
  echo "error: gh CLI is required" >&2
  exit 1
fi

if [ ! -d dist ] || [ -z "$(ls -A dist 2>/dev/null)" ]; then
  echo "error: dist/ is missing or empty. Run 'make build' first." >&2
  exit 1
fi

tags=$(git tag --sort=-creatordate)
if [ -z "$tags" ]; then
  echo "error: no git tags found. Create a tag first (e.g., v0.2.0)." >&2
  exit 1
fi

mapfile -t TAGS <<<"$tags"
echo "Select a tag to upload artifacts to (Ctrl+C to cancel):"
select TAG in "${TAGS[@]}"; do
  if [ -n "$TAG" ]; then
    break
  fi
  echo "Invalid selection"
done

echo "Uploading dist/* to release $TAG ..."
set -x
gh release upload "$TAG" dist/* --clobber
