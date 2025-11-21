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

# Ensure tag exists on origin; push if missing.
if ! git ls-remote --tags origin "$TAG" >/dev/null 2>&1; then
  echo "Tag $TAG not found on origin. Pushing tag..."
  git push origin "$TAG"
fi

echo "Publishing artifacts for $TAG ..."
if gh release view "$TAG" >/dev/null 2>&1; then
  set -x
  gh release upload "$TAG" dist/* --clobber
else
  echo "Release not found. Creating it with assets..."
  set -x
  gh release create "$TAG" dist/* --notes "Automated release for $TAG"
fi
