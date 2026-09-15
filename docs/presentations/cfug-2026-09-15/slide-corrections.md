# PowerPoint correction checklist

Target: [`wheels-rails-style-cfml-mmcfug-2026-09-15.pptx`](wheels-rails-style-cfml-mmcfug-2026-09-15.pptx).
Slide numbers refer to that **25-slide** file, including its speaker notes.
The binary has **not** been rewritten by the Markdown corrections.
Apply these in PowerPoint, save, then inspect slide show and presenter view.

The current executable reference is [`runbook.md`](runbook.md), with one terminal
command per copyable Bash block, a unique app name and explicit HTTP port.
[`deck.md`](deck.md) is the outline; [`demo.md`](demo.md) preserves prior evidence.
The demo remains eight beats, with Post `title:string{50} body:text
publishedAt:datetime`, generated seeds, associations, auth/policy, tests,
API and Harness-driven Post↔Tags assignment. The dated convention seeds are an explicit recovery option,
not a silent replacement for the live generated-seed track.

## Must correct before presenting

- [ ] **Slides 1 and 12 — “no config files.”** Use “no configuration
  ceremony” or “no manual server/database setup.” We intentionally edit
  model config, layout navigation, policy and test files. The optional
  binding follow-up edits routes too.
- [ ] **Slide 5 — release claim.** Confirm release status independently
  before retaining “4.1 shipped Sept 10.” Remove the date if not confirmed;
  neither the title nor a snapshot build proves a release announcement.
- [ ] **Slide 13 — starter page.** Replace the quoted welcome sentence and
  “point at the welcome line” note with the **The details** list: Wheels,
  engine, datasource and environment. Keep the first-boot/stale-registration
  guidance; use the printed URL.
- [ ] **Slide 14 — executable scaffold.** Quote `'title:string{50}'` and
  give the complete second command instead of `Post …` in the copyable
  runbook. Presence validation includes `publishedAt`; seed data needs
  real dates. Use the actual route table, not a fixed internal-route count.
- [ ] **Slide 14 — CRUD sequence.** Retain **Hello, Wheels** for Beat 4.
  Create/delete a separate throwaway. Preserve the original seeded Post
  IDs 1–10 until after Comment generation/seeding on the rehearsed build.
- [ ] **Slides 14 and 16 — generated seed semantics.** First seed creates
  ten Posts. The second creates ten Comments **and another ten Posts**.
  It is not idempotent. On the rehearsed build integer FKs are 1–10, not
  selected from real parent rows; verify zero orphans. Distinguish the
  optional repeat-safe, title-resolved convention seed files.
- [ ] **Slide 15 — generated versus hand-written code.** Keep generated
  presence/length rules. Only the `Untitled` exclusion and `hasMany` are
  new hand edits. Current generated length validation uses
  `allowBlank=true`; don't retain a note saying an empty title must fail
  maximum-length validation even without presence validation.
- [ ] **Slide 16 — describe all association wiring.** The flag adds
  `post_id`, belongsTo, child eager loading and the title-labelled Post
  picker. It reuses the manually added hasMany and wires the conventional
  parent show finder / related-comments UI. Mention skipped-wiring
  messages for custom parent files. The related add link does not preselect
  its Post; select the intended parent in the form.
- [ ] **Slide 16 — observed console output.** Replace **Test Title 3**
  with **Post Title 3** for the preserved clean seed track. The comments
  query count can increase after the browser demonstration. Each console
  expression must stand alone; no cross-request local variables.
- [ ] **Slide 17 — auth field and missing logout UI.** Keep the bcrypt
  description and explicitly name **passwordHash**, not passwordDigest.
  Add the deliberate layout navigation edit from demo.md, including
  `buttonTo(route="logout", method="delete", text="Log out")` in both
  layout branches. The generator does not add the control itself.
- [ ] **Slide 17 — five-step policy/test boundary.** Keep the unused policy →
  one-action gate → all-action filter → readers read/members write/admins delete
  → member login arc from runbook.md. Admin promotion is optional discussion,
  not validated staged work. Different 404/403 codes disclose record existence;
  remove the anti-enumeration claim. Before tests remove ONLY the temporary
  authorizePost filter/helper and any leftover one-action gate; keep requireRecord,
  `include="comments"`, auth and CSRF. An unused policy alone enforces nothing.
- [ ] **Slide 18 — remove warm-up workaround.** Delete the instruction to
  run the first failing suite off-screen. The current generated controller
  spec persists its parent and uses that ID. Rehearsal on build 2482 passed
  **27** on the first untouched test database; then **28 green → 27 passed,
  1 failed → 28 green** for the new body spec. Future builds should report
  their actual counts, not inherit these as a guarantee.
- [ ] **Slide 19 — fix successful API payload.** Add `"sku":"DRUM-001"`
  to the Product JSON. The existing missing-SKU request returns **422**;
  the complete request returns **201**, followed by GET **200**. Use
  `curl -i` and the actual server port to show status as well as JSON.
- [ ] **Slide 19 — remove stale API-test avoidance.** The build-2482
  rehearsal passed **36/36** on the first test run after API addition.
  Remove the blanket instruction not to run the suite after API
  generation. If another build regresses, report that result rather than
  hiding it. Info, migrate diff and coverage also passed in this rehearsal.
- [ ] **Slide 20 — setup agents and a real feature.** Show `wheels setup agents`
  in the demo app: it merges `.mcp.json` / `.opencode.json`, not a Harness install
  or automatic live connection. Configure/import if necessary; reconnect/reload
  tools and verify actual schemas/list against the intended project. The client
  launches `wheels mcp wheels`; the protocol server is not a REPL. Disclose CLI
  fallback if MCP is unavailable. Use [harness-tags-prompt.md](harness-tags-prompt.md)
  to implement Tags **on existing Posts**: persisted many-to-many joins, constraints,
  atomic multi-selection/edit/clear/re-add, validation preservation, Tags navigation/
  management and readable names. Preserve Comments/auth/CSRF, round-trip migrations
  before seeding, resolve real IDs in repeat-safe seeds, test and inspect the browser.
  Pre-Tags baseline is 36; final count must come from the current run, not a frozen
  46. Historical build-2482/2488 and local-patch evidence remains in demo.md; it did
  not validate Post↔Tag assignment. A successful command/HTTP 200/green scaffold
  suite is insufficient. Rehearse the implementation and disclose prepared results.
- [ ] **Slide 21 — result claims.** Remove “versioned” from the `/api/products`
  description: an `/api` namespace alone does not version an API. Recap
  only the features actually shown, including any disclosed fallback.

## Accuracy and presentation polish

- [ ] **Slides 10 and 16 — SQL safety wording.** Say “these two-/three-argument
  query-builder calls bind values,” not “you cannot accidentally write SQL
  injection.” Raw SQL remains the developer's responsibility. Replace
  typographic quotes inside code with straight quotes.
- [ ] **Slides 1, 12 and 21 — timing.** The eight beat budgets total roughly
  52 minutes. Agree the context/demo/Q&A split and cuts in advance. Do not
  restore the earlier Markdown's unrelated 25-minute live-build plan.
- [ ] **Slides 6, 20 and 23 — counts/benchmarks.** Check current engine
  coverage, MCP tool count and performance evidence before retaining exact
  numbers. A Lucee/SQLite demo is not a cross-engine compatibility run.
- [ ] **Slide 24 — first boot.** Avoid a guaranteed 60-second first-run
  promise; network/JVM downloads depend on the machine and cache.
- [ ] **Optional binding note.** If showing Post binding, preserve related
  Comments with `findAll(..., returnAs="objects")` or a query-compatible
  view. Plain findAll returns a query while the generated related block
  loops an array. Keep the rest of the route file. Rehearse existing/missing
  keys and CRUD. The generated direct-controller show test bypasses the
  dispatcher: supply `post=variables.post` in its params, as in demo.md,
  and test HTTP binding separately. The fixture-adjusted suite passed
  44/44. A slug example also needs a populated slug column.

## Final inspection

- [ ] Read slides and notes side by side with demo.md; every command should
  use the same app name, properties, seed mode and actual URL.
- [ ] Do a slide-show pass for code wrapping and a presenter-view pass for
  stale “VERIFIED” notes, shortcuts or old workaround instructions.
- [ ] Record the CLI **and app framework** versions and keep rehearsal
  evidence separate from predictions about a later release.
