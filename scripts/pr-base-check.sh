#!/usr/bin/env bash
# Fails a pull request whose base branch is a dead end.
#
# A merged PR only proves it landed in its BASE branch. If the base is a feature branch that has
# already merged to a mainline branch, the new commits are stranded: the PR shows "merged" but the
# work never reaches dev (this happened to TD-7928 morph, api#2890 / tiled-mono#608).
#
# Inputs (env): GH_TOKEN, REPO, BASE, PR_LABELS (comma-separated), ALLOWED_BASES (regex)
set -euo pipefail

: "${REPO:?}" "${BASE:?}" "${ALLOWED_BASES:?}"
PR_LABELS="${PR_LABELS:-}"
OVERRIDE_LABEL="${OVERRIDE_LABEL:-stacked-pr}"

if [[ "$BASE" =~ $ALLOWED_BASES ]]; then
  echo "Base '$BASE' is a mainline branch. OK."
  exit 0
fi

if [[ ",$PR_LABELS," == *",$OVERRIDE_LABEL,"* ]]; then
  echo "::notice::Base '$BASE' is not a mainline branch, but the '$OVERRIDE_LABEL' label was applied. Skipping."
  exit 0
fi

# PRs whose HEAD is the base branch, i.e. how that branch travels onward.
prs_json=$(gh pr list --repo "$REPO" --head "$BASE" --state all --limit 100 --json number,state,baseRefName,mergedAt)

merged_into_mainline=$(jq -r --arg re "$ALLOWED_BASES" \
  '[.[] | select(.state == "MERGED" and (.baseRefName | test($re)))] | map("#\(.number) -> \(.baseRefName)") | join(", ")' <<<"$prs_json")
open_into_mainline=$(jq -r --arg re "$ALLOWED_BASES" \
  '[.[] | select(.state == "OPEN" and (.baseRefName | test($re)))] | map("#\(.number) -> \(.baseRefName)") | join(", ")' <<<"$prs_json")

if [[ -n "$merged_into_mainline" ]]; then
  echo "::error title=Base branch already merged::Base '$BASE' already merged to a mainline branch ($merged_into_mainline). A PR merged into '$BASE' now will NOT reach it. Retarget this PR to dev, or add the '$OVERRIDE_LABEL' label if this is deliberate."
  exit 1
fi

if [[ -n "$open_into_mainline" ]]; then
  echo "::notice::Stacked PR: '$BASE' is still headed to a mainline branch via $open_into_mainline. OK."
  exit 0
fi

echo "::error title=Base branch has no route to dev::Base '$BASE' is not a mainline branch and has no open PR into one, so work merged into it may never reach dev. Retarget this PR to dev, or add the '$OVERRIDE_LABEL' label if this is deliberate."
exit 1
