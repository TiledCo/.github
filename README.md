# .github
## PR base check (reusable workflow)

`.github/workflows/pr-base-check.yml` fails a pull request whose **base branch is a dead end**, i.e. a feature
branch that already merged to dev (or has no route to it). A merged PR only proves it landed in its *base*; if that
base already merged to dev, the work never reaches dev (TD-7928 morph, api#2890 / tiled-mono#608).

Add it to a repo with a caller workflow:

```yaml
name: PR base check
on:
  pull_request:
    types: [opened, edited, reopened, synchronize, labeled, unlabeled]
permissions:
  contents: read
  pull-requests: read
jobs:
  base-check:
    uses: TiledCo/.github/.github/workflows/pr-base-check.yml@master
```

- Mainline bases always pass: `dev`, `master`, `main`, `pre-production`, `release/*`, `hotfix/*`, `env<N>`
  (override with the `allowed-bases` input).
- A non-mainline base passes only while it still has an **open** PR into a mainline branch (a stacked PR).
- Deliberate exceptions: add the `stacked-pr` label to the PR.
- It only blocks merging once `PR base check / base-check` is a **required** status check on the target branch.
