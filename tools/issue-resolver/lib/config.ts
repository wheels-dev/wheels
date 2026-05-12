import "dotenv/config";
import { config as loadEnv } from "dotenv";
import { existsSync } from "node:fs";
import { dirname, join } from "node:path";
import { fileURLToPath } from "node:url";

const __dirname = dirname(fileURLToPath(import.meta.url));
const ENV_LOCAL = join(__dirname, "..", ".env.local");

if (existsSync(ENV_LOCAL)) {
  loadEnv({ path: ENV_LOCAL, override: false });
}

function required(name: string): string {
  const v = process.env[name];
  if (!v)
    throw new Error(
      `Missing env var ${name}. Run \`npm run issue-resolver:setup\` to create resources, or set the var manually.`,
    );
  return v;
}

export const config = {
  anthropicApiKey: required("ANTHROPIC_API_KEY"),
  githubToken: required("GITHUB_TOKEN"),
  githubOwner: process.env.GITHUB_OWNER || "wheels-dev",
  githubRepo: process.env.GITHUB_REPO || "wheels",
  baseBranch: process.env.BASE_BRANCH || "develop",

  environmentId: required("RESOLVER_ENVIRONMENT_ID"),
  memoryStoreId: required("RESOLVER_MEMORY_STORE_ID"),
  fixerAgentId: required("RESOLVER_FIXER_AGENT_ID"),
  reviewerAgentId: required("RESOLVER_REVIEWER_AGENT_ID"),

  maxReviewCycles: Number(process.env.MAX_REVIEW_CYCLES || 3),
  maxCiFixAttempts: Number(process.env.MAX_CI_FIX_ATTEMPTS || 2),
  ciPollIntervalSec: Number(process.env.CI_POLL_INTERVAL_SEC || 30),
  ciPollTimeoutSec: Number(process.env.CI_POLL_TIMEOUT_SEC || 1800),
};

export type Config = typeof config;
