#!/bin/bash
# 1 repo, 2 target ref

branch_del_api_call="repos/$1/git/refs/heads/$2"
del_msg="'$2' force deletion attempted."
close_msg="Closing PR '$2' to rollback after failure"

echo "PR for $del_msg"
gh pr close "$2" --comment "$close_msg" 2>/dev/null || true
echo "Branch $del_msg"
gh api "$branch_del_api_call" -X DELETE && \
  echo "Branch without error return deleted."
