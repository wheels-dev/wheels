import { config } from "./config.js";

const BASE = "https://api.github.com";

async function gh<T>(path: string, init?: RequestInit): Promise<T> {
  const res = await fetch(`${BASE}${path}`, {
    ...init,
    headers: {
      Accept: "application/vnd.github+json",
      Authorization: `Bearer ${config.githubToken}`,
      "X-GitHub-Api-Version": "2022-11-28",
      "User-Agent": "wheels-issue-resolver",
      ...(init?.headers || {}),
    },
  });
  if (!res.ok) {
    const text = await res.text();
    throw new Error(`GitHub ${init?.method || "GET"} ${path} → ${res.status}: ${text}`);
  }
  if (res.status === 204) return undefined as T;
  return res.json() as Promise<T>;
}

const repoPath = `/repos/${config.githubOwner}/${config.githubRepo}`;

export interface Issue {
  number: number;
  title: string;
  body: string | null;
  labels: { name: string }[];
  state: string;
}

export interface PullRequest {
  number: number;
  html_url: string;
  state: string;
  draft: boolean;
  head: { sha: string; ref: string };
  base: { ref: string };
  node_id: string;
}

export interface CheckRun {
  name: string;
  status: "queued" | "in_progress" | "completed";
  conclusion:
    | "success"
    | "failure"
    | "neutral"
    | "cancelled"
    | "skipped"
    | "timed_out"
    | "action_required"
    | null;
  details_url: string;
}

export async function listOpenIssues(): Promise<Issue[]> {
  const issues = await gh<Issue[]>(
    `${repoPath}/issues?state=open&per_page=100`,
  );
  // GitHub returns PRs in /issues — filter them out via the pull_request property.
  return issues.filter(
    (i) => !(i as Issue & { pull_request?: unknown }).pull_request,
  );
}

export async function findExistingPrForBranch(
  branch: string,
): Promise<PullRequest | null> {
  const prs = await gh<PullRequest[]>(
    `${repoPath}/pulls?head=${config.githubOwner}:${branch}&state=open`,
  );
  return prs[0] ?? null;
}

export async function createDraftPr(args: {
  title: string;
  head: string;
  body: string;
}): Promise<PullRequest> {
  return gh<PullRequest>(`${repoPath}/pulls`, {
    method: "POST",
    body: JSON.stringify({
      title: args.title,
      head: args.head,
      base: config.baseBranch,
      body: args.body,
      draft: true,
    }),
  });
}

export async function postPrReview(args: {
  prNumber: number;
  event: "APPROVE" | "REQUEST_CHANGES" | "COMMENT";
  body: string;
  comments?: { path: string; line: number; body: string }[];
}): Promise<void> {
  await gh(`${repoPath}/pulls/${args.prNumber}/reviews`, {
    method: "POST",
    body: JSON.stringify({
      event: args.event,
      body: args.body,
      comments: args.comments,
    }),
  });
}

export async function markPrReadyForReview(prNodeId: string): Promise<void> {
  // GraphQL — REST has no first-class "ready for review" endpoint.
  const query = `
    mutation($prId: ID!) {
      markPullRequestReadyForReview(input: { pullRequestId: $prId }) {
        pullRequest { id }
      }
    }
  `;
  const res = await fetch(`${BASE}/graphql`, {
    method: "POST",
    headers: {
      Authorization: `Bearer ${config.githubToken}`,
      "Content-Type": "application/json",
      "User-Agent": "wheels-issue-resolver",
    },
    body: JSON.stringify({ query, variables: { prId: prNodeId } }),
  });
  if (!res.ok) {
    throw new Error(`markPrReadyForReview failed: ${res.status} ${await res.text()}`);
  }
  const json = (await res.json()) as { errors?: unknown[] };
  if (json.errors)
    throw new Error(`markPrReadyForReview GraphQL: ${JSON.stringify(json.errors)}`);
}

export async function getCheckRuns(sha: string): Promise<CheckRun[]> {
  const res = await gh<{ check_runs: CheckRun[] }>(
    `${repoPath}/commits/${sha}/check-runs?per_page=100`,
  );
  return res.check_runs;
}

export interface CiStatus {
  state: "pending" | "success" | "failure";
  failed: CheckRun[];
  inProgress: CheckRun[];
}

export function summarizeChecks(checks: CheckRun[]): CiStatus {
  const inProgress = checks.filter((c) => c.status !== "completed");
  if (inProgress.length > 0) {
    return { state: "pending", failed: [], inProgress };
  }
  const failed = checks.filter(
    (c) =>
      c.conclusion === "failure" ||
      c.conclusion === "timed_out" ||
      c.conclusion === "action_required",
  );
  if (failed.length > 0) {
    return { state: "failure", failed, inProgress: [] };
  }
  return { state: "success", failed: [], inProgress: [] };
}
