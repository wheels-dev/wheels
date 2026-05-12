# Phase 1 Feature Verification & Testing Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Add comprehensive tests, framework docs, and PR infrastructure for 4 already-implemented Phase 1 features: batch processing (#1911), query scopes (#1907), enum support (#1910), and query builder (#1908).

**Architecture:** Each feature gets its own branch (`peter/feature-<name>`), test file in `vendor/wheels/tests/model/`, doc page in `docs/src/database-interaction-through-models/`, SUMMARY.md entry, CHANGELOG entry, and a PR that closes the corresponding GitHub issue. A shared PR template and CONTRIBUTING.md update land first.

**Tech Stack:** CFML (Lucee 6), H2 in-memory database, Docker test environment on port 60006, Wheels built-in test runner (`/wheels/tests/core?package=model.<subfolder>&format=json`), MkDocs documentation.

---

## Key Reference

- **Test runner URL:** `http://localhost:60006/wheels/tests/core?package=model.<subfolder>&format=json`
- **Test convention:** Extend `wheels.tests.Test`, functions named `test_<description>()`, use `assert("expression")`
- **Test models:** `vendor/wheels/tests/_assets/models/` (existing: Author, Post, User, etc.)
- **Test DB tables:** `c_o_r_e_*` prefix, populated by `vendor/wheels/tests/populate.cfm`
- **Existing test data:** 10 authors, 5 users, 5 posts, comments, galleries, photos, tags, shops, trucks
- **Framework docs:** `docs/src/database-interaction-through-models/` + entry in `docs/src/SUMMARY.md`
- **AI docs (verify only):** `.ai/wheels/models/{batch-processing,scopes,enums,query-builder}.md`
- **Source files:**
  - Batch: `vendor/wheels/model/read.cfc` (findEach ~L627, findInBatches ~L698)
  - Scopes: `vendor/wheels/model/properties.cfc` (scope() ~L687), `vendor/wheels/model/query/ScopeChain.cfc`
  - Enums: `vendor/wheels/model/properties.cfc` (enum() ~L732), `vendor/wheels/model/onmissingmethod.cfc`
  - Query Builder: `vendor/wheels/model/query/QueryBuilder.cfc`
  - onMissingMethod wiring: `vendor/wheels/model/onmissingmethod.cfc`

---

### Task 0: PR Template & CONTRIBUTING.md

**Files:**
- Create: `.github/pull_request_template.md`
- Modify: `CONTRIBUTING.md`

**Step 1: Create PR template**

```markdown
## Summary

<!-- Brief description of what this PR does -->

## Related Issue

Closes #

## Type of Change

- [ ] Bug fix
- [ ] New feature
- [ ] Enhancement to existing feature
- [ ] Documentation update
- [ ] Refactoring

## Feature Completeness Checklist

<!-- All items must be checked for new features and enhancements -->

- [ ] **Tests** — Unit tests covering happy path, edge cases, and error conditions
- [ ] **Framework Docs** — New or updated page in `docs/src/` with SUMMARY.md entry
- [ ] **AI Reference Docs** — New or updated file in `.ai/wheels/` directory
- [ ] **CLAUDE.md** — Updated if the feature changes model/controller/view conventions
- [ ] **CHANGELOG.md** — Entry under `[Unreleased]` section
- [ ] **Test runner passes** — All existing tests still pass (`/wheels/tests/core?format=json`)

## Test Plan

<!-- How to verify this PR works -->

## Screenshots / Output

<!-- If applicable -->
```

**Step 2: Update CONTRIBUTING.md with Definition of Done**

Add a "Definition of Done" section explaining that every new feature or enhancement PR must include tests, framework docs, AI reference docs, CLAUDE.md updates (if conventions change), and a CHANGELOG entry.

**Step 3: Commit and create PR**

```bash
git checkout -b peter/pr-template
git add .github/pull_request_template.md CONTRIBUTING.md
git commit -m "feat: add PR template and Definition of Done to CONTRIBUTING.md"
git push -u origin peter/pr-template
gh pr create --title "Add PR template and Definition of Done" --body "..."
```

---

### Task 1: Batch Processing Tests & Docs (#1911)

**Files:**
- Create: `vendor/wheels/tests/model/read/batchProcessing.cfc`
- Create: `docs/src/database-interaction-through-models/batch-processing.md`
- Modify: `docs/src/SUMMARY.md` (add entry after "Soft Delete" line)
- Modify: `CHANGELOG.md` (add entry under [Unreleased])
- Verify: `.ai/wheels/models/batch-processing.md` (already exists)

**Step 1: Create test model (if needed)**

The existing `Author` model with `c_o_r_e_authors` table (10 rows) is sufficient for batch testing.

**Step 2: Write test file**

Create `vendor/wheels/tests/model/read/batchProcessing.cfc`:

```cfm
component extends="wheels.tests.Test" {

    function test_findEach_iterates_all_records() {
        local.count = 0;
        model("author").findEach(
            order = "id",
            callback = function(record) {
                local.count++;
            }
        );
        local.total = model("author").count();
        assert("local.count IS local.total");
    }

    function test_findEach_with_batchSize() {
        local.count = 0;
        model("author").findEach(
            order = "id",
            batchSize = 3,
            callback = function(record) {
                local.count++;
            }
        );
        local.total = model("author").count();
        assert("local.count IS local.total");
    }

    function test_findEach_receives_model_objects() {
        local.receivedObject = false;
        model("author").findEach(
            order = "id",
            batchSize = 2,
            callback = function(record) {
                if (IsObject(record) AND StructKeyExists(record, "firstName")) {
                    local.receivedObject = true;
                }
            }
        );
        assert("local.receivedObject IS true");
    }

    function test_findEach_with_where_clause() {
        local.count = 0;
        model("author").findEach(
            where = "lastName = 'Djurner'",
            order = "id",
            callback = function(record) {
                local.count++;
            }
        );
        assert("local.count IS 1");
    }

    function test_findInBatches_processes_batches() {
        local.batchCount = 0;
        model("author").findInBatches(
            order = "id",
            batchSize = 3,
            callback = function(records) {
                local.batchCount++;
            }
        );
        // 10 authors / 3 per batch = 4 batches (3,3,3,1)
        assert("local.batchCount IS 4");
    }

    function test_findInBatches_receives_query_objects() {
        local.receivedQuery = false;
        model("author").findInBatches(
            order = "id",
            batchSize = 5,
            callback = function(records) {
                if (IsQuery(records)) {
                    local.receivedQuery = true;
                }
            }
        );
        assert("local.receivedQuery IS true");
    }

    function test_findInBatches_batch_sizes_correct() {
        local.sizes = [];
        model("author").findInBatches(
            order = "id",
            batchSize = 4,
            callback = function(records) {
                ArrayAppend(local.sizes, records.recordcount);
            }
        );
        // 10 authors / 4 per batch = 3 batches (4,4,2)
        assert("local.sizes[1] IS 4");
        assert("local.sizes[2] IS 4");
        assert("local.sizes[3] IS 2");
    }

    function test_findEach_default_batchSize() {
        // Default batchSize should be 1000, so all 10 authors in 1 internal batch
        local.count = 0;
        model("author").findEach(
            order = "id",
            callback = function(record) {
                local.count++;
            }
        );
        assert("local.count IS model('author').count()");
    }

}
```

**Step 3: Run tests to verify they pass**

```bash
curl -s "http://localhost:60006/wheels/tests/core?package=model.read.batchProcessing&format=json" | python3 -c "import sys,json; d=json.load(sys.stdin); print(f'Tests: {d[\"NUMTESTS\"]}, Pass: {d[\"NUMTESTS\"]-d[\"NUMFAILURES\"]-d[\"NUMERRORS\"]}, Fail: {d[\"NUMFAILURES\"]}, Error: {d[\"NUMERRORS\"]}')"
```

Expected: All tests pass.

**Step 4: Create framework documentation**

Create `docs/src/database-interaction-through-models/batch-processing.md` covering:
- What batch processing is and why it matters (memory efficiency)
- `findEach()` — processes one record at a time via callback
- `findInBatches()` — processes groups of records via callback
- Parameters: `batchSize` (default 1000), `callback` (required), plus standard finder args (`where`, `order`, `include`)
- Usage with scopes: `model("User").active().findEach(...)`
- Code examples for each method

**Step 5: Update SUMMARY.md**

Add after the "Soft Delete" line (line 179):
```
* [Batch Processing](database-interaction-through-models/batch-processing.md)
```

**Step 6: Update CHANGELOG.md**

Add under `[Unreleased]` → `Added`:
```
- Batch processing with `findEach()` and `findInBatches()` for memory-efficient record iteration
```

**Step 7: Verify .ai docs**

Read `.ai/wheels/models/batch-processing.md` and confirm it matches the implementation. Fix if needed.

**Step 8: Commit, push, create PR**

```bash
git checkout -b peter/batch-processing-1911
git add vendor/wheels/tests/model/read/batchProcessing.cfc docs/src/database-interaction-through-models/batch-processing.md docs/src/SUMMARY.md CHANGELOG.md
git commit -m "feat: add tests and docs for batch processing (#1911)"
git push -u origin peter/batch-processing-1911
gh pr create --title "Batch processing: tests and documentation" --body "Closes #1911 ..."
```

---

### Task 2: Query Scopes Tests & Docs (#1907)

**Files:**
- Create: `vendor/wheels/tests/_assets/models/AuthorScoped.cfc` (test model with scopes)
- Create: `vendor/wheels/tests/model/read/queryScopes.cfc`
- Create: `docs/src/database-interaction-through-models/query-scopes.md`
- Modify: `docs/src/SUMMARY.md`
- Modify: `CHANGELOG.md`
- Verify: `.ai/wheels/models/scopes.md`

**Step 1: Create test model with scopes**

Create `vendor/wheels/tests/_assets/models/AuthorScoped.cfc`:

```cfm
component extends="Model" {
    function config() {
        table("c_o_r_e_authors");

        // Static scopes
        scope(name="withLastNameDjurner", where="lastname = 'Djurner'");
        scope(name="orderedByFirstName", order="firstname ASC");
        scope(name="firstThree", maxRows=3);

        // Dynamic scope with handler
        scope(name="byLastName", handler="scopeByLastName");
    }

    private struct function scopeByLastName(required string lastName) {
        return {where: "lastname = '#arguments.lastName#'"};
    }
}
```

**Step 2: Write test file**

Create `vendor/wheels/tests/model/read/queryScopes.cfc`:

```cfm
component extends="wheels.tests.Test" {

    function test_static_where_scope() {
        local.result = model("authorScoped").withLastNameDjurner().findAll();
        assert("local.result.recordcount IS 1");
        assert("local.result.lastname IS 'Djurner'");
    }

    function test_static_order_scope() {
        local.result = model("authorScoped").orderedByFirstName().findAll();
        assert("local.result.firstname[1] IS 'Adam'");
    }

    function test_static_maxRows_scope() {
        local.result = model("authorScoped").firstThree().findAll(order="id");
        assert("local.result.recordcount IS 3");
    }

    function test_chaining_multiple_scopes() {
        local.result = model("authorScoped").orderedByFirstName().firstThree().findAll();
        assert("local.result.recordcount IS 3");
    }

    function test_dynamic_scope_with_argument() {
        local.result = model("authorScoped").byLastName("Petruzzi").findAll();
        assert("local.result.recordcount IS 1");
        assert("local.result.lastname IS 'Petruzzi'");
    }

    function test_scope_with_count() {
        local.result = model("authorScoped").withLastNameDjurner().count();
        assert("local.result IS 1");
    }

    function test_scope_with_findOne() {
        local.result = model("authorScoped").withLastNameDjurner().findOne();
        assert("IsObject(local.result)");
        assert("local.result.lastName IS 'Djurner'");
    }

    function test_scope_with_exists() {
        local.result = model("authorScoped").withLastNameDjurner().exists();
        assert("local.result IS true");
    }

    function test_scope_chain_returns_scope_chain_object() {
        local.chain = model("authorScoped").withLastNameDjurner();
        // Should not be a query — should be a ScopeChain that supports terminal methods
        assert("NOT IsQuery(local.chain)");
    }

    function test_scope_with_additional_finder_args() {
        local.result = model("authorScoped").orderedByFirstName().findAll(select="firstname");
        assert("local.result.recordcount GT 0");
    }

}
```

**Step 3: Run tests**

```bash
curl -s "http://localhost:60006/wheels/tests/core?package=model.read.queryScopes&format=json" | python3 -c "..."
```

**Step 4: Create framework doc** `docs/src/database-interaction-through-models/query-scopes.md`

**Step 5: Update SUMMARY.md and CHANGELOG.md**

**Step 6: Commit, push, create PR closing #1907**

---

### Task 3: Enum Support Tests & Docs (#1910)

**Files:**
- Create: `vendor/wheels/tests/_assets/models/PostWithEnum.cfc`
- Create: `vendor/wheels/tests/model/properties/enums.cfc`
- Create: `docs/src/database-interaction-through-models/enums.md`
- Modify: `docs/src/SUMMARY.md`
- Modify: `CHANGELOG.md`
- Modify: `vendor/wheels/tests/populate.cfm` (add `status` column to `c_o_r_e_posts` table)
- Verify: `.ai/wheels/models/enums.md`

**Step 1: Add status column to posts table in populate.cfm**

Add `status varchar(20) DEFAULT 'draft' NOT NULL` to the `c_o_r_e_posts` CREATE TABLE and set some test data with different statuses.

**Step 2: Create test model**

Create `vendor/wheels/tests/_assets/models/PostWithEnum.cfc`:

```cfm
component extends="Model" {
    function config() {
        table("c_o_r_e_posts");
        belongsTo("author");
        enum(property="status", values="draft,published,archived");
    }
}
```

**Step 3: Write test file**

Create `vendor/wheels/tests/model/properties/enums.cfc` testing:
- `isDraft()`, `isPublished()`, `isArchived()` boolean checkers
- Enum validation (rejects invalid values)
- Auto-generated scopes per enum value
- Getting/setting enum values

**Step 4: Run tests, create docs, update SUMMARY/CHANGELOG, commit, push, create PR closing #1910**

---

### Task 4: Query Builder Tests & Docs (#1908)

**Files:**
- Create: `vendor/wheels/tests/model/read/queryBuilder.cfc`
- Create: `docs/src/database-interaction-through-models/query-builder.md`
- Modify: `docs/src/SUMMARY.md`
- Modify: `CHANGELOG.md`
- Verify: `.ai/wheels/models/query-builder.md`

**Step 1: Write test file**

Create `vendor/wheels/tests/model/read/queryBuilder.cfc` testing:
- `.where("col", "value")` — equality
- `.where("col", ">", value)` — operator
- `.where("raw string")` — passthrough
- `.orWhere()` — OR conditions
- `.whereNull()` / `.whereNotNull()`
- `.whereBetween()`
- `.whereIn()` / `.whereNotIn()`
- `.orderBy()`
- `.limit()`
- `.get()` / `.findAll()` / `.first()` / `.findOne()`
- `.count()` / `.exists()`
- Chaining multiple conditions
- Integration with scopes (scope → builder transition)

**Step 2: Run tests, create docs, update SUMMARY/CHANGELOG, commit, push, create PR closing #1908**

---

## Execution Order

1. **Task 0** — PR template + CONTRIBUTING.md (merge to develop first)
2. **Task 1** — Batch processing (simplest, no new test models needed)
3. **Task 2** — Query scopes (needs new test model)
4. **Task 3** — Enums (needs schema change in populate.cfm + new test model)
5. **Task 4** — Query builder (most complex test suite, no schema changes)

Each task branches from `develop`, gets its own PR.

## Unresolved Questions

- Does the H2 test DB auto-recreate on each test run, or do we need `?reload=true` after schema changes?
- Will modifying `populate.cfm` break existing tests that depend on `c_o_r_e_posts` schema?
- Should enum tests modify the shared `c_o_r_e_posts` table or create a new dedicated table?
