#!/usr/bin/env bash
# Decides whether readme.txt may go to WordPress.org without a release: only if, compared with the
# tag of its Stable tag, nothing changed but the compatibility headers (Tested up to, Requires at
# least, Requires PHP). Anything else (the description, the changelog, a new Stable tag) waits for
# the next release, so the plugin page never describes code that is not released yet.
# Prints publish=true or publish=false, and writes it to $GITHUB_OUTPUT in a workflow.
set -euo pipefail
cd "$(dirname "$0")/../.."

stable=$(sed -n 's/^Stable tag: *//p' readme.txt)
publish=false

if ! git rev-parse -q --verify "refs/tags/$stable" >/dev/null; then
	echo "::notice::Tag $stable does not exist yet; readme.txt goes out with that release."
elif git diff --quiet "$stable" HEAD -- readme.txt; then
	echo "::notice::readme.txt has not changed since $stable."
else
	changes=$(git diff --unified=0 "$stable" HEAD -- readme.txt | grep -E '^[+-]' | grep -vE '^(--- a/|\+\+\+ b/)readme\.txt$')
	other=$(printf '%s\n' "$changes" | grep -vE '^[+-](Tested up to|Requires at least|Requires PHP): ' || true)
	if [ -n "$other" ]; then
		echo "::notice::readme.txt has more changes than the compatibility headers since $stable; they go out with the next release."
		printf '%s\n' "$other"
	else
		publish=true
		echo "Only the compatibility headers changed since $stable:"
		printf '%s\n' "$changes"
	fi
fi

echo "publish=$publish"
if [ -n "${GITHUB_OUTPUT:-}" ]; then
	echo "publish=$publish" >>"$GITHUB_OUTPUT"
fi
