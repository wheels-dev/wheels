# /auto-close-stale-triage

Close issues that the bot triaged but couldn't reproduce, when nobody has
followed up after a grace period. Mirrors Bun's
`auto-close-duplicates.yml` pattern.

## Rails

Read `.claude/commands/_shared-rails.md` first. Highlights:

- This command runs on a cron — no per-issue invocation. Be conservative.
- Use `gh` only.
- Output: zero-or-more issue closures, each with a polite comment.

## Steps

1. **Find candidates.** Issues that ALL of:
   - Are still open
   - Have a comment from `wheels-bot[bot]` containing
     `<!-- wheels-bot:triage:` (any class)
   - Have the `cannot-reproduce` label
   - Have NO human comment (i.e., from a non-bot account) since the triage
     comment was posted
   - Were triaged at least 14 days ago

   ```bash
   gh issue list \
     --state open \
     --label cannot-reproduce \
     --json number,createdAt,updatedAt,comments,author \
     --jq '<filter>'
   ```

2. **For each candidate:**

   a. Sanity check: re-read the issue, confirm there has been no human
      activity since the triage comment.

   b. Idempotency: skip if a comment with marker
      `<!-- wheels-bot:auto-close:<issue-number> -->` already exists.

   c. Post the closure comment:

      ```
      ## Wheels Bot — Auto-close

      This issue was triaged on <date> with classification `cannot-reproduce`
      and has had no follow-up in 14 days. Closing as stale.

      If you have a fresh reproduction or new context, please reopen with
      the additional information.

      <!-- wheels-bot:auto-close:<issue-number> -->
      ```

   d. Close the issue: `gh issue close <issue-number> --reason "not planned"`.

3. **Summary.** Log a one-line summary to stdout for each closure (so the
   workflow run log is auditable).

## Safety

- Never close an issue that has any human comment newer than the triage
  comment.
- Never close an issue without the `cannot-reproduce` label, even if it
  was triaged.
- Never close an issue authored by `wheels-bot[bot]` (it shouldn't happen,
  but guard anyway).
- If anything looks weird (e.g., the triage comment is older than the
  issue, suggesting tampering), skip and log a warning.
