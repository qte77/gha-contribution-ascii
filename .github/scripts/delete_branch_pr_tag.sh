#!/bin/bash
# Cleanup on bump failure: close PR and delete the feature branch.
# Args: $1 = repo (owner/name), $2 = branch name, $3 = version (without v prefix; unused, kept for caller compatibility)
#
# Reason: tag and release deletions were intentionally removed. With "Enable
# release immutability" turned on, GitHub remembers tag names forever — even
# after the ref is deleted. Deleting a tag here on every failure permanently
# burns that version number, locking out any future bump to it. Leave the
# tag/release artifacts alone; if creation half-succeeded, the operator can
# inspect and fix manually instead of being silently locked out.

close_msg="Closing PR '$2' to rollback after failure"

echo "Closing PR for branch '$2'..."
gh pr close "$2" --comment "$close_msg" 2>/dev/null || true

echo "Deleting branch '$2'..."
gh api "repos/$1/git/refs/heads/$2" -X DELETE 2>/dev/null || true
