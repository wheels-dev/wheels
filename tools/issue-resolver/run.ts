import "dotenv/config";
import Anthropic from "@anthropic-ai/sdk";
import { config } from "./lib/config.js";
import { runTurn } from "./lib/session.js";
import {
  createDraftPr,
  findExistingPrForBranch,
  getCheckRuns,
  listOpenIssues,
  markPrReadyForReview,
  postPrReview,
  summarizeChecks,
  type Issue,
  type PullRequest,
} from "./lib/github.js";

interface ReviewerVerdict {
  verdict: "approve" | "request_changes";
  comments: { path: string; line: number; body: string }[];
  general_feedback: string;
}

const client = new Anthropic({ apiKey: config.anthropicApiKey });

// Every session this run creates, so the summary can report what the run cost.
const sessionIds: string[] = [];
async function trackSession<T extends { id: string }>(p: Promise<T>): Promise<T> {
  const s = await p;
  sessionIds.push(s.id);
  return s;
}

async function main(): Promise<void> {
  const filterArg = process.argv[2];
  const filter = filterArg ? new Set(filterArg.split(",").map(Number)) : null;

  console.log("Listing open issues...");
  const allIssues = await listOpenIssues();
  const issues = filter
    ? allIssues.filter((i) => filter.has(i.number))
    : allIssues;
  console.log(
    `${issues.length} issue(s) to process${filter ? ` (filtered)` : ""}.`,
  );

  const summary: { issue: number; result: string }[] = [];

  for (const issue of issues) {
    const branch = `claude/issue-${issue.number}`;
    console.log(`\n${"━".repeat(70)}`);
    console.log(`#${issue.number}: ${issue.title}`);
    console.log(`${"━".repeat(70)}`);

    const existing = await findExistingPrForBranch(branch);
    if (existing) {
      console.log(
        `  ↳ Existing PR #${existing.number} for ${branch} — skipping to avoid stomping.`,
      );
      summary.push({
        issue: issue.number,
        result: `skipped (existing PR #${existing.number})`,
      });
      continue;
    }

    try {
      const result = await processIssue(issue, branch);
      summary.push({ issue: issue.number, result });
    } catch (err) {
      console.error(`  ✗ ${(err as Error).message}`);
      summary.push({
        issue: issue.number,
        result: `error: ${(err as Error).message}`,
      });
    }
  }

  console.log(`\n${"═".repeat(70)}\nSummary\n${"═".repeat(70)}`);
  for (const row of summary) {
    console.log(`  #${row.issue}: ${row.result}`);
  }

  // usage.list_cost.amount is an integer string in cents.
  let cents = 0;
  for (const id of sessionIds) {
    const s = (await client.beta.sessions.retrieve(id)) as {
      usage?: { list_cost?: { amount?: string } };
    };
    cents += Number(s.usage?.list_cost?.amount ?? 0);
  }
  console.log(`  List cost across ${sessionIds.length} session(s): $${(cents / 100).toFixed(2)}`);
}

async function processIssue(issue: Issue, branch: string): Promise<string> {
  // 1. Create fixer session with develop checked out, memory attached.
  const fixerSession = await trackSession(client.beta.sessions.create({
    agent: config.fixerAgentId,
    environment_id: config.environmentId,
    title: `Fix issue #${issue.number}`,
    resources: [
      {
        type: "github_repository",
        url: `https://github.com/${config.githubOwner}/${config.githubRepo}`,
        authorization_token: config.githubToken,
        checkout: { type: "branch", name: config.baseBranch },
      },
      {
        type: "memory_store",
        memory_store_id: config.memoryStoreId,
        access: "read_write",
        instructions:
          "Cross-issue knowledge. Read /conventions.md and /gotchas.md before starting. After completing the fix, append to /issues-completed.md (issue, branch, files, learning). If you discover anything tricky, add it to /gotchas.md.",
      },
    ],
  }));
  console.log(`  fixer session: ${fixerSession.id}`);

  // 2. Initial fix turn.
  const issueBody = (issue.body || "").trim() || "(no body)";
  const fixKickoff = `Resolve issue #${issue.number}.

Title: ${issue.title}

Body:
${issueBody}

Branch to use: ${branch}

Working directory: /workspace/wheels (already on ${config.baseBranch}).

Steps:
1. Read /workspace/wheels/CLAUDE.md if you haven't already.
2. Investigate the issue, find affected files.
3. Create branch \`${branch}\` from ${config.baseBranch}.
4. Make the smallest change that resolves the issue.
5. Commit with conventional format and push the branch.
6. Output a final summary: branch, commit SHA(s), files changed, what you did.

If too complex (multi-day, design needed, spans many subsystems), output a final message starting with "SKIP:" and explain.`;

  console.log("  → fixer working...");
  const initial = await runTurn(client, fixerSession.id, fixKickoff, {
    onText: (t) => process.stdout.write(t),
  });
  process.stdout.write("\n");

  if (initial.status === "terminated") {
    return `failed (fixer session terminated: ${initial.stopReason || "unknown"})`;
  }

  if (initial.finalText.trimStart().startsWith("SKIP:")) {
    console.log(`  ↳ Fixer skipped this issue.`);
    return `skipped by fixer`;
  }

  // 3. Confirm the branch was pushed.
  await new Promise((r) => setTimeout(r, 3000)); // brief grace for GitHub indexing
  const branchCheck = await fetch(
    `https://api.github.com/repos/${config.githubOwner}/${config.githubRepo}/branches/${branch}`,
    {
      headers: {
        Authorization: `Bearer ${config.githubToken}`,
        Accept: "application/vnd.github+json",
        "User-Agent": "wheels-issue-resolver",
      },
    },
  );
  if (!branchCheck.ok) {
    return `fixer ran but branch ${branch} not found on origin (status ${branchCheck.status})`;
  }

  // 4. Create the draft PR.
  console.log(`  → creating draft PR...`);
  const pr = await createDraftPr({
    title: `Fix #${issue.number}: ${issue.title}`,
    head: branch,
    body: buildPrBody(issue, initial.finalText),
  });
  console.log(`  ↳ PR #${pr.number}: ${pr.html_url}`);

  // 5. Review cycle.
  let reviewVerdict: ReviewerVerdict | null = null;
  for (let cycle = 1; cycle <= config.maxReviewCycles; cycle++) {
    console.log(`  → review cycle ${cycle}/${config.maxReviewCycles}...`);
    const verdict = await reviewPr(pr, branch);

    if (verdict.verdict === "approve") {
      await postPrReview({
        prNumber: pr.number,
        event: "APPROVE",
        body: `Automated review (cycle ${cycle}): ${verdict.general_feedback}`,
      });
      reviewVerdict = verdict;
      console.log(`  ↳ approved on cycle ${cycle}.`);
      break;
    }

    await postPrReview({
      prNumber: pr.number,
      event: "REQUEST_CHANGES",
      body: `Automated review (cycle ${cycle}): ${verdict.general_feedback}`,
      comments: verdict.comments,
    });

    if (cycle === config.maxReviewCycles) {
      console.log(
        `  ↳ review cycles exhausted; leaving PR for human attention.`,
      );
      return `review exhausted (PR #${pr.number} left as draft with REQUEST_CHANGES)`;
    }

    // Send feedback to fixer session for revision.
    const reviewMsg = `The reviewer requested changes. General feedback:

${verdict.general_feedback}

Specific comments:
${verdict.comments
  .map((c) => `- ${c.path}:${c.line} — ${c.body}`)
  .join("\n")}

Please address these and push another commit. Output a final summary of what you changed.`;

    console.log(`  → fixer addressing feedback...`);
    const revision = await runTurn(client, fixerSession.id, reviewMsg, {
      onText: (t) => process.stdout.write(t),
    });
    process.stdout.write("\n");

    if (revision.status === "terminated") {
      return `failed (fixer terminated during review cycle ${cycle})`;
    }
  }

  if (!reviewVerdict) {
    return `review cycle ended without approval`;
  }

  // 6. Wait for CI.
  console.log(`  → polling CI...`);
  const ciOk = await waitForCiAndFix(pr, fixerSession.id);

  if (!ciOk) {
    return `CI fix attempts exhausted (PR #${pr.number} left as draft)`;
  }

  // 7. Mark ready for review.
  console.log(`  → marking PR ready for review...`);
  await markPrReadyForReview(pr.node_id);

  return `ready for human merge (PR #${pr.number})`;
}

async function reviewPr(
  pr: PullRequest,
  branch: string,
): Promise<ReviewerVerdict> {
  // Fresh reviewer session, scoped to this PR.
  const reviewSession = await trackSession(client.beta.sessions.create({
    agent: config.reviewerAgentId,
    environment_id: config.environmentId,
    title: `Review PR #${pr.number}`,
    resources: [
      {
        type: "github_repository",
        url: `https://github.com/${config.githubOwner}/${config.githubRepo}`,
        authorization_token: config.githubToken,
        checkout: { type: "branch", name: branch },
      },
      {
        type: "memory_store",
        memory_store_id: config.memoryStoreId,
        access: "read_write",
        instructions:
          "Cross-PR review knowledge. Read /review-patterns.md and /gotchas.md before reviewing. Append any new patterns you notice to /review-patterns.md.",
      },
    ],
  }));

  const reviewMsg = `Review PR #${pr.number} (branch ${branch}, base ${pr.base.ref}).

The branch is checked out at /workspace/wheels.

Run \`git diff ${pr.base.ref}...HEAD\` to see the changes. Read affected files in full for context.

Apply the review checklist from your system prompt, then call submit_review.`;

  const captured: { verdict: ReviewerVerdict | null } = { verdict: null };
  await runTurn(client, reviewSession.id, reviewMsg, {
    onText: (t) => process.stdout.write(t),
    customTools: {
      submit_review: async (input) => {
        const v = input as Partial<ReviewerVerdict>;
        if (
          (v.verdict !== "approve" && v.verdict !== "request_changes") ||
          !Array.isArray(v.comments) ||
          typeof v.general_feedback !== "string"
        ) {
          return {
            text: "Invalid submit_review input; call it again with verdict, comments[], and general_feedback.",
            isError: true,
          };
        }
        captured.verdict = v as ReviewerVerdict;
        return { text: "Review recorded." };
      },
    },
  });
  process.stdout.write("\n");

  if (!captured.verdict) {
    console.warn(`  ⚠ reviewer ended without calling submit_review — treating as request_changes.`);
    return {
      verdict: "request_changes",
      comments: [],
      general_feedback: "The automated reviewer did not submit a verdict; this PR needs a human look.",
    };
  }
  return captured.verdict;
}

async function waitForCiAndFix(
  pr: PullRequest,
  fixerSessionId: string,
): Promise<boolean> {
  let headSha = pr.head.sha;

  for (let attempt = 0; attempt <= config.maxCiFixAttempts; attempt++) {
    const status = await pollCiUntilDone(headSha);
    if (status.state === "success") {
      console.log(`  ↳ CI green (attempt ${attempt}).`);
      return true;
    }
    if (status.state !== "failure") {
      console.log(`  ↳ CI ${status.state} — bailing.`);
      return false;
    }
    if (attempt === config.maxCiFixAttempts) {
      console.log(`  ↳ CI fix attempts exhausted.`);
      return false;
    }

    const failedSummary = status.failed
      .map(
        (c) =>
          `- ${c.name} (${c.conclusion})${c.details_url ? ` — ${c.details_url}` : ""}`,
      )
      .join("\n");

    console.log(`  → fixer addressing CI failures (attempt ${attempt + 1})...`);
    const ciMsg = `CI is failing on the PR. Failed checks:

${failedSummary}

Please:
1. Investigate the failures (read CI logs if accessible, otherwise reason from check names).
2. Make the smallest fix that resolves the failures.
3. Commit and push to the same branch.
4. Output a summary of what you fixed.

If the failure is transient infrastructure rather than code, make no changes and say so in your summary.`;

    const fixTurn = await runTurn(client, fixerSessionId, ciMsg, {
      onText: (t) => process.stdout.write(t),
    });
    process.stdout.write("\n");

    if (fixTurn.status === "terminated") {
      console.log(`  ↳ fixer terminated during CI fix.`);
      return false;
    }

    // Refetch the PR to get the new head SHA after the push.
    await new Promise((r) => setTimeout(r, 5000));
    const refreshed = await fetch(
      `https://api.github.com/repos/${config.githubOwner}/${config.githubRepo}/pulls/${pr.number}`,
      {
        headers: {
          Authorization: `Bearer ${config.githubToken}`,
          Accept: "application/vnd.github+json",
          "User-Agent": "wheels-issue-resolver",
        },
      },
    );
    if (!refreshed.ok) {
      console.warn(`  ⚠ couldn't refetch PR; staying on old SHA.`);
      continue;
    }
    const json = (await refreshed.json()) as { head: { sha: string } };
    headSha = json.head.sha;
  }
  return false;
}

async function pollCiUntilDone(sha: string): Promise<ReturnType<typeof summarizeChecks>> {
  const deadline = Date.now() + config.ciPollTimeoutSec * 1000;
  while (Date.now() < deadline) {
    const checks = await getCheckRuns(sha);
    if (checks.length === 0) {
      // Checks not yet posted; wait briefly.
      await new Promise((r) => setTimeout(r, config.ciPollIntervalSec * 1000));
      continue;
    }
    const status = summarizeChecks(checks);
    if (status.state !== "pending") return status;
    process.stdout.write(
      `    ⏳ ${status.inProgress.length} checks in progress…\r`,
    );
    await new Promise((r) => setTimeout(r, config.ciPollIntervalSec * 1000));
  }
  return { state: "failure", failed: [], inProgress: [] };
}

function buildPrBody(issue: Issue, fixerSummary: string): string {
  return [
    `Resolves #${issue.number}.`,
    "",
    "## Fixer summary",
    "",
    fixerSummary.trim(),
    "",
    "---",
    "",
    "_This PR was opened by the issue-resolver orchestrator. It will go through automated review and CI checks before being marked ready for review._",
  ].join("\n");
}

main().catch((err) => {
  console.error("Run failed:", err);
  process.exit(1);
});
