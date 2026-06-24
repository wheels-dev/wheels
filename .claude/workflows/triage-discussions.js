export const meta = {
  name: 'triage-discussions',
  description: 'Fetch recent GitHub Discussions, triage each thread, and adversarially verify which ones actually need a code fix, doc update, or new issue',
  whenToUse: 'Periodic (e.g. monthly) sweep of community GitHub Discussions to surface genuinely actionable items — without filing duplicates or acting on reports that are already fixed/answered. Read-only: produces a verified findings report, posts nothing.',
  phases: [
    { title: 'Fetch', detail: 'pull + filter recent discussions (drop Announcements and bot reports)' },
    { title: 'Triage', detail: 'read each discussion thread, classify, propose action', model: 'sonnet' },
    { title: 'Verify', detail: 'adversarially check each proposed action against current code + open issues' },
  ],
}

// ---------------------------------------------------------------------------
// args (all optional). Accepts an object, a JSON string, or a bare date string:
//   { repo: "owner/name", since: "YYYY-MM-DD", max: 40 }
//   "2026-01-01"   -> treated as { since }
// Defaults: repo=wheels-dev/wheels, since=2025-01-01, max=40
// ---------------------------------------------------------------------------
const opts = (() => {
  if (args == null) return {}
  if (typeof args === 'string') {
    const s = args.trim()
    if (s.startsWith('{')) { try { return JSON.parse(s) } catch (e) { return {} } }
    return s ? { since: s } : {}
  }
  return args
})()
const REPO = opts.repo || 'wheels-dev/wheels'
const SINCE = opts.since || '2025-01-01'
const MAX = opts.max || 40
const [OWNER, NAME] = REPO.split('/')

const CANDIDATES_SCHEMA = {
  type: 'object',
  additionalProperties: false,
  properties: {
    candidates: {
      type: 'array',
      items: {
        type: 'object',
        additionalProperties: false,
        properties: {
          number: { type: 'integer' },
          title: { type: 'string' },
          category: { type: 'string' },
          comments: { type: 'integer' },
          isAnswered: { type: 'boolean' },
          updatedAt: { type: 'string' },
          author: { type: 'string' },
        },
        required: ['number', 'title', 'category', 'comments', 'isAnswered', 'updatedAt', 'author'],
      },
    },
  },
  required: ['candidates'],
}

const TRIAGE_SCHEMA = {
  type: 'object',
  additionalProperties: false,
  properties: {
    number: { type: 'integer' },
    classification: { type: 'string', enum: ['bug', 'feature-idea', 'doc-gap', 'question-unanswered', 'question-answered', 'onboarding-friction', 'infra', 'noise'] },
    summary: { type: 'string' },
    resolvedInThread: { type: 'boolean' },
    proposedAction: { type: 'string', enum: ['code-fix', 'doc-update', 'file-issue', 'reply', 'close-stale', 'none'] },
    actionDetail: { type: 'string' },
    severity: { type: 'string', enum: ['high', 'medium', 'low'] },
    needsVerification: { type: 'boolean' },
  },
  required: ['number', 'classification', 'summary', 'resolvedInThread', 'proposedAction', 'actionDetail', 'severity', 'needsVerification'],
}

const VERDICT_SCHEMA = {
  type: 'object',
  additionalProperties: false,
  properties: {
    number: { type: 'integer' },
    verdict: { type: 'string', enum: ['confirmed-needs-action', 'already-fixed', 'already-tracked', 'wont-act', 'insufficient-evidence'] },
    evidence: { type: 'string' },
    existingIssue: { type: 'string' },
    recommendedAction: { type: 'string' },
    confidence: { type: 'string', enum: ['high', 'medium', 'low'] },
  },
  required: ['number', 'verdict', 'evidence', 'existingIssue', 'recommendedAction', 'confidence'],
}

function fetchCmd(num) {
  return `gh api graphql -f query='query($num: Int!) { repository(owner:"${OWNER}", name:"${NAME}") { discussion(number:$num) { title url createdAt updatedAt category{name} answer{ body author{login} } body comments(first:50){ nodes{ author{login} createdAt body replies(first:20){ nodes{ author{login} body } } } } } } }' -F num=${num}`
}

const fetchPrompt = [
  `Build the candidate list of GitHub Discussions to triage for repo ${REPO}.`,
  ``,
  `Run this in Bash (the API returns the 100 most-recently-updated; that is enough for a recency sweep):`,
  `gh api graphql -f query='query { repository(owner:"${OWNER}", name:"${NAME}") { discussions(first:100, orderBy:{field:UPDATED_AT, direction:DESC}) { nodes { number title url createdAt updatedAt isAnswered category{name} comments{totalCount} author{login} } } } }'`,
  ``,
  `Filter the nodes:`,
  `- EXCLUDE category == "Announcements" (maintainer marketing / release posts — not actionable).`,
  `- EXCLUDE author login "github-actions" (automated monthly metrics reports).`,
  `- KEEP only discussions whose updatedAt >= ${SINCE}.`,
  `Sort the kept set by updatedAt descending and return at most ${MAX}.`,
  ``,
  `For each kept discussion emit: number, title, category (name), comments (the comments.totalCount integer), isAnswered (use false when the GraphQL value is null), updatedAt (date only, "YYYY-MM-DD"), author (login).`,
  `Return ONLY the structured object {candidates: [...]}.`,
].join('\n')

function triagePrompt(c) {
  return [
    `You are triaging a GitHub Discussion in the Wheels CFML framework repo (${REPO}). Wheels is on the develop branch; many older threads reference 3.x.`,
    `Discussion #${c.number}: "${c.title}" — category=${c.category}, comments=${c.comments}, updated=${c.updatedAt}, author=${c.author}.`,
    ``,
    `STEP 1 — Read the FULL thread. Run this in Bash:`,
    fetchCmd(c.number),
    ``,
    `STEP 2 — Understand what the user reports or asks, and whether the thread already resolved it (accepted answer, "thanks that worked", maintainer fix linked, etc).`,
    ``,
    `STEP 3 — Classify and decide whether the maintainer needs to DO something NOW.`,
    `- classification: bug | feature-idea | doc-gap | question-unanswered | question-answered | onboarding-friction | infra | noise`,
    `- proposedAction: code-fix | doc-update | file-issue | reply | close-stale | none`,
    `- needsVerification: TRUE when the proposed action depends on the current state of the codebase or on whether an issue already exists (any code-fix / file-issue / doc-update claim a downstream verifier must confirm against HEAD). FALSE for pure social replies, clear no-ops, or answered questions that revealed nothing latent.`,
    ``,
    `Be conservative: an answered Q&A with an accepted answer usually needs no action UNLESS it exposes a real doc gap or a latent bug. A "broken"/"doesn't work" title is a CLAIM, not a confirmed bug — flag it for verification rather than asserting it.`,
    `summary: 1-2 sentences. actionDetail: the concrete next step (or "none"). severity: high|medium|low (impact on users).`,
    `Return ONLY the structured object.`,
  ].join('\n')
}

function verifyPrompt(t, c) {
  return [
    `You are an ADVERSARIAL verifier for the Wheels CFML framework (${REPO}); working tree is the develop branch. DEFAULT TO SKEPTICAL — assume the proposed action is unnecessary until evidence proves otherwise.`,
    `A triage agent reviewed Discussion #${c.number} ("${c.title}") and proposed: ${t.proposedAction} — "${t.actionDetail}" (classification: ${t.classification}, severity: ${t.severity}).`,
    `Thread summary: ${t.summary}`,
    ``,
    `Verify against reality, citing evidence:`,
    `1. ALREADY FIXED? Search the codebase (Grep/Glob/Read) and recent history (git log --oneline -40). The reported behavior may already be patched. Re-read the thread if useful: ${fetchCmd(c.number)}`,
    `2. ALREADY TRACKED? Run: gh issue list --repo ${REPO} --state all --search "<relevant keywords>" --limit 15  (try a couple of keyword sets).`,
    `3. Only if it is a REAL, untracked, unfixed problem -> confirmed-needs-action.`,
    ``,
    `verdict: confirmed-needs-action | already-fixed | already-tracked | wont-act | insufficient-evidence`,
    `evidence: cite a file:line, commit SHA, or issue number that justifies the verdict (be specific). existingIssue: issue number if already-tracked, else "".`,
    `recommendedAction: the crisp final recommendation for the maintainer. confidence: high|medium|low.`,
    `READ-ONLY: do NOT post anything to GitHub, do NOT edit files. Return ONLY the structured object.`,
  ].join('\n')
}

phase('Fetch')
const fetched = await agent(fetchPrompt, { label: 'fetch-discussions', phase: 'Fetch', schema: CANDIDATES_SCHEMA, effort: 'low' })
const candidates = (fetched && fetched.candidates) || []
log(`Fetched ${candidates.length} candidate discussions (updated since ${SINCE}, excluding Announcements + bots).`)
if (!candidates.length) return { reviewed: 0, confirmedCount: 0, findings: [] }

phase('Triage')
const results = await pipeline(
  candidates,
  (c) => agent(triagePrompt(c), { label: `triage:#${c.number}`, phase: 'Triage', schema: TRIAGE_SCHEMA, model: 'sonnet', effort: 'medium' }),
  (t, c) => {
    if (!t) return { number: c.number, candidate: c, triage: null, verdict: null }
    const actionable = t.needsVerification && t.proposedAction !== 'none' && t.classification !== 'noise'
    if (!actionable) {
      return {
        number: c.number, candidate: c, triage: t,
        verdict: {
          number: c.number, verdict: 'wont-act',
          evidence: 'triage: no codebase/issue verification needed',
          existingIssue: '',
          recommendedAction: t.proposedAction === 'none' ? 'No action needed' : t.actionDetail,
          confidence: 'medium', skippedVerify: true,
        },
      }
    }
    return agent(verifyPrompt(t, c), { label: `verify:#${c.number}`, phase: 'Verify', effort: 'high', schema: VERDICT_SCHEMA })
      .then(v => ({ number: c.number, candidate: c, triage: t, verdict: v }))
  }
)

const findings = results.filter(Boolean)
const confirmed = findings.filter(f => f.verdict && f.verdict.verdict === 'confirmed-needs-action')
log(`Done: ${findings.length} reviewed, ${confirmed.length} confirmed as needing action.`)
return { reviewed: candidates.length, confirmedCount: confirmed.length, findings }
