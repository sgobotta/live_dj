---
name: open-pr
description: Use when opening a pull request for this repo — creating a PR, "open a PR", "raise a PR", or pushing a branch up for review. Ensures the PR targets dev and uses the repo's PULL_REQUEST_TEMPLATE.md.
---

# Open a Pull Request

Create PRs for this repo with a consistent base branch and body. Uses the GitHub CLI (`gh`).

## Non-negotiables

- **Base branch is always `dev`.** Never target `main`/`master` or any other branch. (`gh pr create --base dev`)
- **Body is always built from `.github/PULL_REQUEST_TEMPLATE.md`.** Start from that file, then fill it in — never invent a different structure.

## Steps

1. **Check the branch.** You must be on a feature branch, not `dev`. If on `dev`, stop and create a branch first (`git checkout -b feature/<summary>`). Never open a PR from `dev` into `dev`.
2. **Commit and push.** Ensure all work is committed and the branch is pushed: `git push -u origin HEAD`.
3. **Build the body** from the template (see below) into a temp file.
4. **Create the PR:** `gh pr create --base dev --title "<concise summary>" --body-file <tmpfile> --assignee @me`
5. **Report** the PR URL back to the user.

## Filling the template body

Copy `.github/PULL_REQUEST_TEMPLATE.md`, then edit it — the raw file is NOT a valid body as-is:

- **Strip the YAML frontmatter** — delete everything from the opening `---` through the closing `---` (it's an issue-template leftover and renders as literal text in a PR).
- **Remove HTML comments and the example bullets** (`<!-- ... -->`) — replace them with real content.
- **Description:** write a real summary, then a `**This PR provides:**` bullet list of the actual changes.
- **`Closes #issue-number`:** if there's a related issue, reference it; otherwise delete the line.
- **Type of change:** keep only the applicable line(s) and check them (`- [x]`); delete the rest.
- **How Has This Been Tested?:** give real reproduction/verification steps (e.g. `make test`, manual checks), not the placeholder text.
- **Checklist:** check the boxes that are genuinely true. The **bold** items are required for approval — confirm they hold before checking.
- **Append the attribution footer** as the last line of the body:
  `🤖 Generated with [Claude Code](https://claude.com/claude-code)`

## Notes

- Title: a concise, imperative summary of the change (no trailing period).
- Opening a PR is outward-facing — after filling the body, show the user the title/base/body and get a quick confirm before running `gh pr create`, unless they've told you to just go.
- If `gh` isn't authenticated, tell the user to run `gh auth login` (suggest `! gh auth login`).
