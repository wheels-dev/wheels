import "dotenv/config";
import Anthropic from "@anthropic-ai/sdk";
import { existsSync, writeFileSync } from "node:fs";
import { dirname, join } from "node:path";
import { fileURLToPath } from "node:url";

const __dirname = dirname(fileURLToPath(import.meta.url));
const ENV_FILE = join(__dirname, ".env.local");

const FIXER_MODEL = process.env.FIXER_MODEL || "claude-opus-4-7";
const REVIEWER_MODEL = process.env.REVIEWER_MODEL || "claude-sonnet-4-6";

const FIXER_SYSTEM = `You are a Wheels framework engineer resolving GitHub issues. The repo is mounted at /workspace/wheels with a feature branch already checked out.

ALWAYS read /workspace/wheels/CLAUDE.md first. It contains anti-patterns and conventions you must follow strictly. Pay particular attention to:
- The Top-10 Anti-Patterns (mixed positional/named args, query vs array in views, etc.)
- Cross-engine compatibility notes (.ai/wheels/cross-engine-compatibility.md) — Lucee/Adobe CF differences are common bug sources
- Commit message format (commitlint rules in CLAUDE.md)

Workflow:
1. Read the issue body and any referenced files. Use grep/glob to find related code.
2. Make the smallest change that resolves the issue. No refactoring of surrounding code, no scope creep, no speculative abstractions.
3. If a quick relevant test exists, run it (e.g. bash tools/test-local.sh model). Skip heavy matrix tests — CI handles those.
4. Commit using the conventional format \`type(scope): subject\` from CLAUDE.md. The branch is already \`claude/issue-<NUMBER>\`.
5. Push the branch with \`git push -u origin <branch>\`.
6. Output a final message stating: branch name, commit SHA(s), files changed, brief summary.

If the issue is too complex (multi-day work, requires design discussion, spans many subsystems), output a final message that STARTS with "SKIP:" and explains why. The orchestrator will move on.

Do not open PRs — the orchestrator handles that. Do not merge.

A memory store is attached for cross-issue knowledge. Read /conventions.md and /gotchas.md inside it for accumulated context before working. After finishing, append a brief note to /issues-completed.md (issue number, branch, files, key learning) and update /gotchas.md if you discovered anything tricky.`;

const REVIEWER_SYSTEM = `You are a senior code reviewer for Wheels (CFML MVC framework). The PR branch is checked out at /workspace/wheels.

Read /workspace/wheels/CLAUDE.md for the anti-patterns list. Then review the diff (\`git diff develop...HEAD\`) against:
1. Does the change actually resolve the linked issue?
2. CLAUDE.md anti-patterns: mixed positional/named args, query-vs-array in views, route ordering, public mixin functions, etc.
3. Cross-engine compatibility (.ai/wheels/cross-engine-compatibility.md): private mixin functions, struct.map() resolution, application scope, bracket-notation calls in closures, array-by-value in struct literals.
4. Scope creep: was anything changed beyond what the issue requires?
5. Test coverage: new behavior should have tests; bug fixes should have a regression test where feasible.
6. Commit message format: \`type(scope): subject\` with valid types/scopes from CLAUDE.md.

Read affected files in full for context, not just the diff.

End your response with a JSON block (the orchestrator parses this — no other JSON in your response):

\`\`\`json
{"verdict": "approve" | "request_changes", "comments": [{"path": "<file>", "line": <number>, "body": "<actionable feedback>"}], "general_feedback": "<one paragraph summary>"}
\`\`\`

If verdict is "approve", \`comments\` may be empty. If "request_changes", every comment must be actionable and specific. Don't nitpick style if commitlint and tests pass — focus on correctness, framework conventions, and cross-engine concerns.

A memory store is attached. Read /review-patterns.md for accumulated reviewer notes from prior PRs.`;

const SEED_CONVENTIONS = `# Wheels Conventions Cheat Sheet

This file accumulates framework-specific conventions discovered while resolving issues. Initial seed:

- Models extend "Model"; controllers extend "Controller"; new tests extend "wheels.WheelsTest" (BDD).
- All associations/validations/callbacks go in the model's config() function.
- Function-call rule: NEVER mix positional and named arguments in Wheels framework calls. Use all named when passing options.
- Migrations: use NOW() for timestamps (database-agnostic), use direct SQL for seed inserts (parameter binding is unreliable in execute()).
- View variables must be cfparam'd at the top of every view file.
- Filter functions in controllers must be declared private.
- timestamps() in migrations adds createdAt, updatedAt, AND deletedAt (three columns, not two).

Update this file when you discover a new convention or framework idiom.
`;

const SEED_ISSUES_COMPLETED = `# Completed Issues

Append entries as issues are resolved. Format:

## #NNN — <title>
- Branch: claude/issue-NNN
- Files: <list>
- Resolution: <one-paragraph summary>
- Learning: <key takeaway, if any>
`;

const SEED_GOTCHAS = `# Recurring Gotchas

Cross-engine, framework, and tooling pitfalls discovered while fixing issues. Append findings here so future runs benefit.

- Lucee/Adobe CF: \`obj.map()\` resolves to the built-in struct member function, not a CFC method. Use a wrapper instead.
- Adobe CF: \`obj["key"]()\` crashes the parser inside closures. Split into two statements.
- Lucee 7: \`Left(str, 0)\` crashes. Use a ternary guard.
- Test infrastructure: HTML entities like \`&#111;\` contain \`#\` which CFML interprets as expression delimiters — escape as \`&##111;\` in string literals.
- \`private\` mixin functions are not integrated into model/controller objects. Use \`public\` access with a \`$\` prefix for internal scope.
`;

const SEED_REVIEW_PATTERNS = `# Reviewer Patterns

Notes accumulated across PR reviews — recurring issues, false positives, framework-specific concerns the reviewer should weight heavily.

- Always check \`vendor/wheels/\` changes for cross-engine compatibility (Lucee 6/7, Adobe 2023/2025, BoxLang).
- New CFC files: confirm \`extends="..."\` is correct and matches the CLAUDE.md convention.
- Routes: order matters; resources before custom-named before root before wildcard.
- Migrations: use \`NOW()\` not database-specific timestamp functions.
`;

async function main() {
  if (existsSync(ENV_FILE)) {
    console.error(
      `Refusing to overwrite ${ENV_FILE}.\n` +
        `If you want to recreate resources, delete this file first (the old Anthropic-side resources will become orphans you can clean up via the \`ant\` CLI).`,
    );
    process.exit(1);
  }

  const client = new Anthropic();
  const ts = new Date().toISOString().replace(/[:.]/g, "-").slice(0, 19);

  console.log("Creating environment...");
  const environment = await client.beta.environments.create({
    name: `wheels-issue-resolver-${ts}`,
    config: {
      type: "cloud",
      networking: { type: "unrestricted" },
    },
  });
  console.log(`  ${environment.id}`);

  console.log("Creating memory store...");
  const memory = await client.beta.memoryStores.create({
    name: `wheels-issue-resolver-${ts}`,
    description:
      "Cross-issue knowledge for Wheels framework: conventions, gotchas, completed-issue log, reviewer patterns. Read before starting any task; append findings after.",
  });
  console.log(`  ${memory.id}`);

  console.log("Seeding memory store...");
  for (const [path, content] of [
    ["/conventions.md", SEED_CONVENTIONS],
    ["/issues-completed.md", SEED_ISSUES_COMPLETED],
    ["/gotchas.md", SEED_GOTCHAS],
    ["/review-patterns.md", SEED_REVIEW_PATTERNS],
  ] as const) {
    await client.beta.memoryStores.memories.create(memory.id, {
      path,
      content,
    });
    console.log(`  ${path}`);
  }

  console.log(`Creating fixer agent (model: ${FIXER_MODEL})...`);
  const fixer = await client.beta.agents.create({
    name: `Wheels Issue Fixer (${ts})`,
    model: FIXER_MODEL,
    system: FIXER_SYSTEM,
    tools: [
      { type: "agent_toolset_20260401", default_config: { enabled: true } },
    ],
    description:
      "Resolves Wheels framework issues by reading the issue, making the smallest change, and pushing a branch.",
  });
  console.log(`  ${fixer.id} (version ${fixer.version})`);

  console.log(`Creating reviewer agent (model: ${REVIEWER_MODEL})...`);
  const reviewer = await client.beta.agents.create({
    name: `Wheels PR Reviewer (${ts})`,
    model: REVIEWER_MODEL,
    system: REVIEWER_SYSTEM,
    tools: [
      { type: "agent_toolset_20260401", default_config: { enabled: true } },
    ],
    description:
      "Reviews Wheels PRs for issue resolution, anti-pattern compliance, and cross-engine compatibility. Outputs structured JSON verdict.",
  });
  console.log(`  ${reviewer.id} (version ${reviewer.version})`);

  const env =
    [
      `# Generated by tools/issue-resolver/setup.ts at ${new Date().toISOString()}`,
      `# Delete this file to force recreate Anthropic-side resources (the old ones become orphans).`,
      `RESOLVER_ENVIRONMENT_ID=${environment.id}`,
      `RESOLVER_MEMORY_STORE_ID=${memory.id}`,
      `RESOLVER_FIXER_AGENT_ID=${fixer.id}`,
      `RESOLVER_FIXER_AGENT_VERSION=${fixer.version}`,
      `RESOLVER_REVIEWER_AGENT_ID=${reviewer.id}`,
      `RESOLVER_REVIEWER_AGENT_VERSION=${reviewer.version}`,
    ].join("\n") + "\n";

  writeFileSync(ENV_FILE, env);
  console.log(`\nWrote ${ENV_FILE}`);
  console.log(`Run \`npm run issue-resolver:run\` to start resolving issues.`);
}

main().catch((err) => {
  console.error("Setup failed:", err);
  process.exit(1);
});
