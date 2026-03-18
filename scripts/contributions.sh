#!/usr/bin/env bash
# Query existing GitHub contributions and compute compensation.

set -euo pipefail

# query_contributions: Fetch contribution calendar via GraphQL.
# Args: $1 = GitHub token, $2 = username, $3 = from_date (YYYY-MM-DD), $4 = to_date (YYYY-MM-DD)
# Output: JSON array of {date, contributionCount} objects
query_contributions() {
    local token="${1}" username="${2}" from_date="${3}" to_date="${4}"

    local query
    query=$(cat <<GRAPHQL
{
  user(login: "$username") {
    contributionsCollection(from: "${from_date}T00:00:00Z", to: "${to_date}T23:59:59Z") {
      contributionCalendar {
        weeks {
          contributionDays {
            date
            contributionCount
          }
        }
      }
    }
  }
}
GRAPHQL
    )

    local response
    response=$(gh api graphql -f query="$query" 2>/dev/null) || {
        echo "ERROR: GraphQL query failed" >&2
        return 1
    }

    echo "$response" | jq -r '
        [.data.user.contributionsCollection.contributionCalendar.weeks[]
         .contributionDays[] | {date, contributionCount}]'
}

# get_contribution_count: Get existing contribution count for a specific date.
# Args: $1 = contributions_json (from query_contributions), $2 = date (YYYY-MM-DD)
# Output: integer count
get_contribution_count() {
    local contributions_json="${1}" target_date="${2}"
    echo "$contributions_json" | jq -r \
        --arg d "$target_date" \
        '[.[] | select(.date == $d) | .contributionCount] | first // 0'
}

# compute_intensity_thresholds: Estimate quartile thresholds from contribution data.
# Args: $1 = contributions_json
# Output: 5 lines: threshold for level 0, 1, 2, 3, 4
compute_intensity_thresholds() {
    local contributions_json="${1}"

    # Get max contribution count
    local max_count
    max_count=$(echo "$contributions_json" | jq '[.[].contributionCount] | max // 0')

    if [[ "$max_count" -eq 0 ]]; then
        # No contributions: any commit will show
        echo "0"  # level 0: 0 commits (gray)
        echo "1"  # level 1
        echo "2"  # level 2
        echo "3"  # level 3
        echo "4"  # level 4
    else
        # GitHub uses quartiles of the max
        # Level 0: 0 commits
        # Level 1: 1 to ~25% of max
        # Level 2: ~25% to ~50%
        # Level 3: ~50% to ~75%
        # Level 4: ~75% to max
        local q1=$(( (max_count + 3) / 4 ))
        local q2=$(( (max_count + 1) / 2 ))
        local q3=$(( (max_count * 3 + 3) / 4 ))

        echo "0"
        echo "${q1}"
        echo "${q2}"
        echo "${q3}"
        echo "${max_count}"
    fi
}

# compute_needed_commits: Calculate commits needed for a target intensity level.
# Args: $1 = target_level (0-4), $2 = existing_count, $3 = thresholds (newline-separated)
# Output: number of commits needed, or "CONFLICT" if impossible
compute_needed_commits() {
    local target_level="${1}" existing_count="${2}" thresholds="${3}"

    # Get target threshold
    local target_count
    target_count=$(echo "$thresholds" | sed -n "$((target_level + 1))p")

    if [[ "$target_level" -eq 0 ]]; then
        if [[ "$existing_count" -gt 0 ]]; then
            echo "CONFLICT"
        else
            echo "0"
        fi
        return
    fi

    local needed=$(( target_count - existing_count ))
    if [[ $needed -lt 0 ]]; then
        needed=0
    fi
    echo "$needed"
}
