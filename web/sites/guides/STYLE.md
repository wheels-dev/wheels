# Wheels Guides — Writing Style Guide

Governs every page in `src/content/docs/v4-0-0/`. Contributors writing or reviewing docs treat it as enforceable.

## Voice & tone

- Second person ("you"), active voice. Never "we" except tutorial welcomes.
- No marketing copy ("powerful," "robust," "effortless"). Describe what the feature does.
- Short sentences. Split two-idea sentences.
- Assume the reader is smart and busy.

## Audience assumptions

Every non-intro page declares assumptions in a "You should already know" `<Aside>` when relevant.

- **Tutorial:** zero Wheels, zero CFML, some programming.
- **Core Concepts:** finished tutorial or equivalent.
- **How-tos:** finished tutorial; may require specific concept section.
- **Reference:** familiarity with the feature; no teaching.

## Code examples

- Complete and runnable wherever possible. Show context even if it's 10 extra lines.
- Real names (`Post`, `user.email`, `publishedAt`), not `foo`/`bar`/`someField`.
- Every code block declares its file path: ` ```cfm title="app/controllers/Posts.cfc" `.
- No placeholder comments like `// your code here`. Show the code or remove the block.
- Every non-illustrative block is tagged for the verify-docs harness (`{test:compile}`, `{test:cli}`, or `{test:tutorial}`). See `scripts/verify-docs/VALIDATION.md`.
- Illustrative blocks that cannot compile: ` ```cfm title="illustrative — do not type" `.

## Page structure

- Every page opens with a 1-sentence summary + 3-line "You'll learn" list.
- Tutorials end with "Checkpoint" and "Troubleshooting" (three common failure modes).
- How-tos end with "Related guides" `<CardGrid>`.
- Concepts end with "See also" link block.
- Reference pages: tables, lists, parameters — no narrative.

## Vocabulary

- "Wheels," never "CFWheels."
- "the `wheels` CLI," never "LuCLI" in user-facing docs. LuCLI appears only in contributor/internal docs.
- "migration," not "db migration." "Model," not "ORM model."
- Function names in code voice: `findAll()`, `hasMany()`. Concept in prose voice: "finders," "associations."

## Diátaxis purity

Every page frontmatter carries `type: tutorial | howto | concept | reference`. A future Vale rule rejects mixed types.

- **Tutorial** — learning-oriented. Hand-held. You build something.
- **How-to** — task-oriented. "How to X." You already know what you want.
- **Concept** — understanding-oriented. "Why Wheels does X." No commands, no steps.
- **Reference** — information-oriented. Dry. Tables and lists.

## Linking discipline

- Internal links relative to site root: `/v4-0-0/core-concepts/request-lifecycle/`.
- External links checked by the link checker in CI.
- Every CLI command links to its reference page the first time it appears in a page.

## Starlight components to prefer

- `<Aside type="note|tip|caution|danger">` for callouts — not blockquotes.
- `<Tabs>` for OS-specific or engine-specific variations.
- `<Steps>` for numbered procedural lists.
- `<Card>` / `<CardGrid>` / `<LinkCard>` for "what to read next" blocks.
- `<FileTree>` for project structure diagrams.

## What we don't write

- No emojis.
- No "Note:" or "Important:" prefixed paragraphs — use `<Aside>`.
- No headings deeper than `###`. If a page needs `####`, split it.
- No tables of contents at the top — Starlight renders one on the right.
