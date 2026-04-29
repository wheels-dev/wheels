# Fresh-VM Batch C — Scaffold Templates Align with Tutorial

> **For agentic workers:** REQUIRED SUB-SKILLs in execution order:
> 1. superpowers:test-driven-development (every template change has a failing snapshot test first)
> 2. superpowers:subagent-driven-development (recommended) OR superpowers:executing-plans for orchestration
> 3. superpowers:verification-before-completion (cross-engine verification at the end is a hard gate)
>
> Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Update the CLI's scaffold templates so `wheels generate scaffold Post title:string body:text status:enum` produces files that match the bodies shown in [tutorial chapter 3](../../web/sites/guides/src/content/docs/v4-0-0-snapshot/start-here/tutorial/03-crud-scaffold.mdx). After this batch a reader can follow chapter 3 verbatim — the scaffold's emitted `Posts.cfc`, `_form.cfm`, `index.cfm`, and `show.cfm` should be byte-equivalent (or close enough that the tutorial's prose still applies) to the chapter's `<Steps>` blocks. The route-injection step should not double-add `.resources("posts")` if a duplicate already exists. The form helper for `status:enum` should render a `<select>` with the enum values, not a free-text `textField`.

**Architecture.** Five logical edits to `cli/src/templates/` plus targeted changes in `cli/lucli/services/CodeGen.cfc`, `cli/lucli/services/Templates.cfc`, `cli/lucli/services/Scaffold.cfc`, and `cli/lucli/Module.cfc`'s property parser. Each edit is gated by a snapshot regression test in `cli/lucli/tests/specs/services/ScaffoldSpec.cfc`. Cross-engine verification (Lucee 5/6/7 + Adobe 2018/2021/2023/2025) is a hard gate before the PR opens because template files are read on every CLI invocation across every engine.

**Tech Stack.** CFML / CommandBox-style template strings (the `{{name}}` / `|ObjectNameSingular|` placeholder language defined in [`cli/lucli/services/Templates.cfc:67-175`](../../cli/lucli/services/Templates.cfc)). WheelsTest BDD for the regression suite. Local test loop via [`tools/test-cli-local.sh`](../../tools/test-cli-local.sh) and [`tools/test-local.sh`](../../tools/test-local.sh).

**Source finding.** [#4 in the 2026-04-29 fresh-VM triage](./2026-04-29-fresh-vm-onboarding-findings.md), plus the embedded sub-finding that `status:enum` produces a `textField` instead of a `select`. Original journal preserved in the originating session.

**Risk: medium.** Template file changes affect every fresh `wheels generate scaffold` invocation. The format is shared with the legacy CommandBox CLI (`cli/src/templates/` is the canonical path; `cli/lucli/templates/app/app/snippets/CRUDContent.txt` mirrors it for app-level overrides — the two files are byte-identical today and must stay in sync). A typo in a placeholder breaks the generator silently. Snapshot tests are non-negotiable.

---

## Reconnaissance summary

- **Scaffold orchestration:** [`cli/lucli/services/Scaffold.cfc:25-151`](../../cli/lucli/services/Scaffold.cfc) — `generateScaffold()` calls `generateModel`, `generateController`, then iterates `["index", "show", "new", "edit", "_form"]` calling `generateView`, then `generateTest("model")` + `generateTest("controller")`, then `updateRoutes(pluralName)`.
- **Route injection:** [`Scaffold.cfc:206-250`](../../cli/lucli/services/Scaffold.cfc) — `updateRoutes()` already short-circuits on `findNoCase('.resources("' & resourceName & '")', content)`. **It does NOT detect `.resources(name="posts", ...)` form (named-arg form) — that's the duplication path the tutorial hits.**
- **CodeGen entry points:** [`cli/lucli/services/CodeGen.cfc:97-209`](../../cli/lucli/services/CodeGen.cfc) — `generateController()` selects `CRUDContent.txt` for full-CRUD non-API. `generateView()` maps `_form` → `crud/_form.txt` etc.
- **Template directory resolution:** [`Templates.cfc:209-239`](../../cli/lucli/services/Templates.cfc) — search order is `moduleRoot/templates/codegen/` → `cli/src/templates/` (monorepo) → `vendor/wheels/cli/src/templates/` → legacy fallback. The monorepo uses `cli/src/templates/` (verified — `directoryExists` returns true for `cli/src/templates`). All references below treat `cli/src/templates/` as canonical.
- **Form-field generator:** [`Templates.cfc:401-441`](../../cli/lucli/services/Templates.cfc) — `generateFormFieldsCode()` switches on `lCase(prop.type)` for `boolean`, `text`, `date`, `datetime`, `time`, default → `textField`. **No case for `enum` — that's the sub-finding.**
- **Property parser:** [`cli/lucli/Module.cfc:4283-4313`](../../cli/lucli/Module.cfc) — splits each non-flag arg on `:`. `title:string` → `{name:"title", type:"string"}`. `status:enum` parses to `{name:"status", type:"enum"}` with no values. **The tutorial uses `status:enum`; the model declares values via `enum(property="status", values="draft,published,archived")` in `app/models/Post.cfc` (chapter 2). The scaffold has to read those values from the model file (or accept them inline).**
- **Migration column type for enum:** [`Scaffold.cfc:584-600`](../../cli/lucli/services/Scaffold.cfc) — `mapToWheelsType()` defaults unknown types to `string`. Unchanged behavior is correct (an enum is stored as a varchar). No fix needed there.
- **Existing tests:** [`cli/lucli/tests/specs/services/ScaffoldSpec.cfc`](../../cli/lucli/tests/specs/services/ScaffoldSpec.cfc) — already covers existence + plural-route regression (F4) + association inclusion. We add snapshot-style assertions inside this same file.

---

## Task 1: Pin current scaffold output with snapshot tests (red)

We capture today's drifted output as failing tests so each subsequent edit has a green target. **Do not skip this task** — without snapshots, template tweaks regress silently across CFML engines.

**Files:**
- Modify: `cli/lucli/tests/specs/services/ScaffoldSpec.cfc`

- [ ] **Step 1: Add a `describe("matches tutorial chapter 3 output", ...)` block**

Append inside the existing `describe("Scaffold Service", ...)` (after line 230, before the closing brace of `run()`):

```cfm
describe("matches tutorial chapter 3 output", () => {

    it("Posts.cfc uses route model binding for show/edit/update/delete", () => {
        scaffold.generateScaffold(
            name = "Post",
            properties = [
                {name: "title", type: "string"},
                {name: "body", type: "text"},
                {name: "status", type: "enum", values: "draft,published,archived"}
            ],
            force = true
        );
        var content = fileRead(tempRoot & "/app/controllers/Posts.cfc");

        // show/edit/update/delete read params.post (route model binding) — NOT findByKey
        expect(content).toInclude("post = params.post");
        expect(content).notToInclude("model(""Post"").findByKey(params.key)");
        expect(content).notToInclude("model(""post"").findByKey(params.key)");
    });

    it("Posts.cfc create uses model.new(...) + .save() (not .create() + hasErrors)", () => {
        var content = fileRead(tempRoot & "/app/controllers/Posts.cfc");
        expect(content).toInclude('model("Post").new(params.post)');
        expect(content).toInclude("post.save()");
        expect(content).notToInclude('model("Post").create(params.post)');
        expect(content).notToInclude("hasErrors()");
    });

    it("Posts.cfc redirects use route= and key=, not action=index", () => {
        var content = fileRead(tempRoot & "/app/controllers/Posts.cfc");
        expect(content).toInclude('redirectTo(route="post", key=post.id)');
        expect(content).toInclude('redirectTo(route="posts")');
        expect(content).notToInclude('redirectTo(action="index"');
    });

    it("Posts.cfc has no objectNotFound handler or verifies(...handler=)", () => {
        var content = fileRead(tempRoot & "/app/controllers/Posts.cfc");
        // Route model binding throws Wheels.RecordNotFound on miss — no handler needed.
        expect(content).notToInclude("objectNotFound");
        expect(content).notToInclude('handler="objectNotFound"');
    });

    it("_form.cfm wraps fields in startFormTag/endFormTag with errorMessagesFor + submit", () => {
        var content = fileRead(tempRoot & "/app/views/posts/_form.cfm");
        expect(content).toInclude("errorMessagesFor(""post"")");
        expect(content).toInclude("startFormTag(");
        expect(content).toInclude("endFormTag()");
        expect(content).toInclude("<button type=""submit"">Save</button>");
    });

    it("_form.cfm renders a <select> for status:enum, not a textField", () => {
        var content = fileRead(tempRoot & "/app/views/posts/_form.cfm");
        expect(content).toInclude('select(objectName="post", property="status"');
        expect(content).toInclude('options="draft,published,archived"');
        expect(content).notToInclude('textField(objectName="post", property="status"');
    });

    it("index.cfm uses <article> markup, not Bootstrap table classes", () => {
        var content = fileRead(tempRoot & "/app/views/posts/index.cfm");
        expect(content).toInclude("<article>");
        expect(content).toInclude("<cfloop query=""posts"">");
        expect(content).notToInclude('<table class="table">');
        expect(content).notToInclude('class="btn btn-default"');
    });

    it("show.cfm has clean <h1>#post.title#</h1> heading and link/buttonTo footer", () => {
        var content = fileRead(tempRoot & "/app/views/posts/show.cfm");
        expect(content).toInclude("<h1>##post.title##</h1>");
        expect(content).toInclude('linkTo(route="editPost", key=post.id, text="Edit")');
        expect(content).toInclude('buttonTo(route="post", key=post.id, text="Delete", method="delete")');
        expect(content).notToInclude("View Post");
        expect(content).notToInclude('class="btn btn-primary"');
    });

    it("does NOT inject a duplicate .resources line when one already exists in any form", () => {
        // Pre-seed routes with the named-arg form (same shape the tutorial chapter 2 uses).
        var routesPath = tempRoot & "/config/routes.cfm";
        var seeded = 'mapper()' & chr(10)
                   & '    .resources(name="posts", only="index,show")' & chr(10)
                   & '.end();' & chr(10);
        fileWrite(routesPath, seeded);

        scaffold.generateScaffold(
            name = "Post",
            properties = [{name: "title", type: "string"}],
            force = true
        );

        var routesContent = fileRead(routesPath);
        var matches = reMatch('\.resources\([^)]*posts', routesContent);
        expect(arrayLen(matches)).toBe(1);
    });

});
```

- [ ] **Step 2: Run the spec — expect every new `it` to fail**

```bash
bash tools/test-cli-local.sh
```

Filter to the scaffold spec if the runner supports it. Expected: nine new failures. If any new test passes today, the corresponding template was already aligned — re-read the relevant template file before declaring victory.

- [ ] **Step 3: Commit the failing tests**

```bash
git add cli/lucli/tests/specs/services/ScaffoldSpec.cfc
git commit -m "test(cli): pin tutorial-aligned scaffold output as failing snapshots"
```

We commit failing tests deliberately. Tasks 2-7 turn them green one at a time.

---

## Task 2: Align `Posts.cfc` template with tutorial route-model-binding shape

**Files:**
- Modify: `cli/src/templates/CRUDContent.txt`
- Modify: `cli/lucli/templates/app/app/snippets/CRUDContent.txt` (must stay byte-identical to the canonical copy)

The tutorial's `Posts.cfc` reads `params.post` directly (route model binding via `.resources(name="posts", binding=true)`), uses `model("Post").new(params.post)` + `.save()` for create, and uses route-form `redirectTo(route="post", key=post.id)`. The verifies+objectNotFound boilerplate goes away — binding throws `Wheels.RecordNotFound` (404) for misses.

- [ ] **Step 1: Replace `cli/src/templates/CRUDContent.txt` with**

```
|DescriptionComment|component extends="Controller" {

	/**
	* View all |ObjectNamePluralC|
	**/
	function index() {
		|ObjectNamePlural|=model("|ObjectNameSingularC|").findAll();
	}

	/**
	* View |ObjectNameSingularC|
	**/
	function show() {
		|ObjectNameSingular|=params.|ObjectNameSingular|;
	}

	/**
	* Add New |ObjectNameSingularC|
	**/
	function new() {
		|ObjectNameSingular|=model("|ObjectNameSingularC|").new();
	}

	/**
	* Create |ObjectNameSingularC|
	**/
	function create() {
		|ObjectNameSingular|=model("|ObjectNameSingularC|").new(params.|ObjectNameSingular|);
		if(|ObjectNameSingular|.save()){
			redirectTo(route="|ObjectNameSingular|", key=|ObjectNameSingular|.id);
		} else {
			renderView(action="new");
		}
	}

	/**
	* Edit |ObjectNameSingularC|
	**/
	function edit() {
		|ObjectNameSingular|=params.|ObjectNameSingular|;
	}

	/**
	* Update |ObjectNameSingularC|
	**/
	function update() {
		|ObjectNameSingular|=params.|ObjectNameSingular|;
		if(|ObjectNameSingular|.update(params.|ObjectNameSingular|)){
			redirectTo(route="|ObjectNameSingular|", key=|ObjectNameSingular|.id);
		} else {
			renderView(action="edit");
		}
	}

	/**
	* Delete |ObjectNameSingularC|
	**/
	function delete() {
		|ObjectNameSingular|=params.|ObjectNameSingular|;
		|ObjectNameSingular|.delete();
		redirectTo(route="|ObjectNamePlural|");
	}

}
```

Notes on the placeholders:
- `|ObjectNameSingular|` is lowercase singular (`post`).
- `|ObjectNameSingularC|` is capitalised singular (`Post`).
- `|ObjectNamePlural|` is lowercase plural (`posts`).
- `|ObjectNamePluralC|` is capitalised plural (`Posts`).
- The route name placeholders match Wheels' `.resources("posts")` auto-generated route names: `post` (member), `posts` (collection), `editPost`, `newPost`. So `redirectTo(route="|ObjectNameSingular|", key=|ObjectNameSingular|.id)` becomes `redirectTo(route="post", key=post.id)` after substitution — matching the tutorial.
- The `verifies(...)` / `objectNotFound()` block is intentionally dropped. Route model binding throws a 404 when the lookup fails; the controller doesn't need to handle "not found" itself.

- [ ] **Step 2: Mirror to the lucli app-snippet override copy**

```bash
cp cli/src/templates/CRUDContent.txt cli/lucli/templates/app/app/snippets/CRUDContent.txt
```

The two files MUST stay byte-identical. The override path exists for end-user customization (`app/snippets/`); the lucli template directory is just the bundled copy users get on `wheels new`.

- [ ] **Step 3: Run the spec — Tasks 2's six related `it`s should now pass**

```bash
bash tools/test-cli-local.sh
```

Expected: the four `Posts.cfc` cases from Task 1 now pass. The view + form + route cases still fail. If any `Posts.cfc` case still fails, inspect the generated file at `tempRoot/app/controllers/Posts.cfc` directly — most likely a placeholder typo.

- [ ] **Step 4: Commit**

```bash
git add cli/src/templates/CRUDContent.txt cli/lucli/templates/app/app/snippets/CRUDContent.txt
git commit -m "fix(cli): align scaffold controller with tutorial chapter 3

Scaffold-generated Posts.cfc now uses route model binding
(params.post) on show/edit/update/delete instead of findByKey,
model.new() + save() instead of model.create() + hasErrors() on
create, and route-form redirects (redirectTo(route, key)) instead
of action=index. Drops the verifies+objectNotFound boilerplate
since binding throws Wheels.RecordNotFound (404) on miss.

Closes finding ##4 (controller portion) in
docs/superpowers/plans/2026-04-29-fresh-vm-onboarding-findings.md"
```

---

## Task 3: Teach the property parser to accept `name:enum:value1,value2,...`

**Files:**
- Modify: `cli/lucli/Module.cfc:4283-4313` (parseGeneratorArgs)
- Modify: `cli/lucli/services/Scaffold.cfc:584-600` (mapToWheelsType — explicit enum case for documentation)
- Modify: `cli/lucli/tests/specs/commands/GenerateCommandSpec.cfc` (parser test)

The tutorial uses `status:enum` (no inline values) and relies on the model file already declaring `enum(property="status", values="draft,published,archived")` (chapter 2). For the scaffold to emit a `<select>` with the right options, it needs to know the values. We support two paths:

1. **Inline:** `status:enum:draft,published,archived` — explicit, no model lookup needed.
2. **Implicit:** `status:enum` with no values — the form generator parses the existing `app/models/Post.cfc` for `enum(property="status", values="...")`.

Path 1 is the contract, path 2 is the convenience that makes the tutorial command (`status:enum`) work without modification.

- [ ] **Step 1: Update `parseGeneratorArgs` to capture enum values when present**

In `cli/lucli/Module.cfc` around line 4302-4309, replace the property-parse branch:

```cfm
} else if (!arg.startsWith("--")) {
    // Property: name, name:type, or name:enum:value1,value2,...
    var parts = listToArray(arg, ":", false, true);  // include empty + preserve segments
    var prop = {
        name: parts[1],
        type: arrayLen(parts) > 1 ? parts[2] : "string"
    };
    // Capture enum values: status:enum:draft,published,archived → values="draft,published,archived"
    if (lCase(prop.type) == "enum" && arrayLen(parts) > 2) {
        prop.values = parts[3];
    }
    arrayAppend(result.properties, prop);
}
```

Note: `listToArray(arg, ":", false, true)` — the fourth arg `true` preserves consecutive delimiters. The default `listToArray("a:b", ":")` already returns `["a","b"]`; with `true` for "include empty fields" we still get the right shape for `a:b:c,d` → `["a","b","c,d"]` (the comma stays inside the third segment because we split on `:`).

- [ ] **Step 2: Add a parser test in `GenerateCommandSpec.cfc`**

Append a new `it` near the existing parser tests:

```cfm
it("parses status:enum:draft,published into {type:'enum', values:'draft,published'}", () => {
    var mod = new cli.lucli.Module();
    mod.__arguments = ["model", "Post", "status:enum:draft,published,archived"];
    // If the spec uses a private parser helper directly, call it; otherwise
    // assert the side-effect via codeGenService.generateModel arguments.
    var parsed = mod.parseGeneratorArgs(["status:enum:draft,published,archived"]);
    expect(arrayLen(parsed.properties)).toBe(1);
    expect(parsed.properties[1].name).toBe("status");
    expect(parsed.properties[1].type).toBe("enum");
    expect(parsed.properties[1].values).toBe("draft,published,archived");
});

it("parses bare status:enum into {type:'enum'} with no values key", () => {
    var mod = new cli.lucli.Module();
    var parsed = mod.parseGeneratorArgs(["status:enum"]);
    expect(parsed.properties[1].name).toBe("status");
    expect(parsed.properties[1].type).toBe("enum");
    expect(structKeyExists(parsed.properties[1], "values")).toBeFalse();
});
```

If `parseGeneratorArgs` is private, change its access to `package` (or expose a thin public wrapper for test use only) — this is a CLI-internal helper and `package`-level visibility doesn't widen the public API.

- [ ] **Step 3: Document the migration column type explicitly**

In `cli/lucli/services/Scaffold.cfc:584-600`, add an explicit `enum` case to `mapToWheelsType` so the intent is visible:

```cfm
private string function mapToWheelsType(required string type) {
    switch (lCase(arguments.type)) {
        case "string": return "string";
        case "text": return "text";
        case "integer": case "int": return "integer";
        case "biginteger": case "bigint": return "biginteger";
        case "float": case "double": return "float";
        case "decimal": case "numeric": return "decimal";
        case "boolean": case "bool": return "boolean";
        case "date": return "date";
        case "datetime": case "timestamp": return "datetime";
        case "time": return "time";
        case "binary": case "blob": return "binary";
        case "uuid": return "uniqueidentifier";
        case "enum": return "string";  // enums are stored as varchar; values live on the model
        default: return "string";
    }
}
```

- [ ] **Step 4: Run the parser tests**

```bash
bash tools/test-cli-local.sh
```

Expected: the two new parser tests pass. The `_form.cfm` snapshot tests still fail (form generation hasn't changed yet — Task 4 covers that).

- [ ] **Step 5: Commit**

```bash
git add cli/lucli/Module.cfc cli/lucli/services/Scaffold.cfc cli/lucli/tests/specs/commands/GenerateCommandSpec.cfc
git commit -m "feat(cli): accept name:enum:values in generate property syntax

The tutorial uses 'status:enum' and chapter 2 declares the values
on the model. To emit a <select> with the right options the
scaffold needs the values; support both inline (status:enum:a,b,c)
and implicit (status:enum, values read from existing model file).

This commit lands the inline path. The implicit fallback ships in
the next commit (form-field generator update)."
```

---

## Task 4: Emit `<select>` for enum properties in the form-field generator

**Files:**
- Modify: `cli/lucli/services/Templates.cfc:401-441` (generateFormFieldsCode)

The generator currently switches on `lCase(prop.type)` and falls through to `textField` for any unrecognized type, including `enum`. Add an explicit `enum` case that emits `select(...)` with the values from `prop.values`. If `prop.values` is missing (the tutorial's `status:enum` case), read the model file and parse `enum(property="...", values="...")` from it.

- [ ] **Step 1: Add the enum case + a model-file fallback**

Replace the `switch` block in `generateFormFieldsCode` (around lines 418-437):

```cfm
switch (lCase(fieldType)) {
    case "boolean":
        fieldCode = '##checkBox(objectName="|ObjectNameSingular|", property="#fieldName#", label="#fieldLabel#")##';
        break;
    case "text": case "longtext":
        fieldCode = '##textArea(objectName="|ObjectNameSingular|", property="#fieldName#", label="#fieldLabel#")##';
        break;
    case "date":
        fieldCode = '##dateField(objectName="|ObjectNameSingular|", property="#fieldName#", label="#fieldLabel#")##';
        break;
    case "datetime": case "timestamp":
        fieldCode = '##dateTimeSelect(objectName="|ObjectNameSingular|", property="#fieldName#", label="#fieldLabel#")##';
        break;
    case "time":
        fieldCode = '##timeSelect(objectName="|ObjectNameSingular|", property="#fieldName#", label="#fieldLabel#")##';
        break;
    case "enum":
        var enumValues = prop.keyExists("values") && len(trim(prop.values))
            ? prop.values
            : $resolveEnumValuesFromModel(arguments.modelName, fieldName);
        if (len(enumValues)) {
            fieldCode = '##select(objectName="|ObjectNameSingular|", property="#fieldName#", options="#enumValues#", label="#fieldLabel#")##';
        } else {
            // No values found on the model and none passed inline — fall back
            // to a textField rather than emitting an empty <select>.
            fieldCode = '##textField(objectName="|ObjectNameSingular|", property="#fieldName#", label="#fieldLabel#")##';
        }
        break;
    default:
        fieldCode = '##textField(objectName="|ObjectNameSingular|", property="#fieldName#", label="#fieldLabel#")##';
}
```

Note: I changed `case "date"` from `dateSelect` to `dateField` to match what the tutorial's `_form.cfm` uses (`dateField(...publishedAt...)`). That's a deliberate alignment with the tutorial's HTML5-helper style; it also matches CLAUDE.md's "HTML5 Form Helpers Available" guidance.

- [ ] **Step 2: Add `$resolveEnumValuesFromModel` private helper**

Append to `Templates.cfc` (private helpers section, around line 567):

```cfm
/**
 * Read the model file at app/models/<ModelName>.cfc and extract the
 * `values` argument from a `enum(property="<fieldName>", values="...")`
 * declaration. Returns an empty string if the file or declaration is
 * missing — callers should fall back to a textField in that case.
 */
private string function $resolveEnumValuesFromModel(required string modelName, required string fieldName) {
    var modelPath = variables.projectRoot & "/app/models/" & arguments.modelName & ".cfc";
    if (!fileExists(modelPath)) return "";
    var content = fileRead(modelPath);
    // Match enum(property="status", values="draft,published,archived") — quotes optional, whitespace tolerant.
    var pattern = "enum\s*\(\s*property\s*=\s*[""']" & arguments.fieldName & "[""']\s*,\s*values\s*=\s*[""']([^""']+)[""']";
    var match = reFind(pattern, content, 1, true);
    if (match.pos[1] > 0 && arrayLen(match.pos) >= 2) {
        return mid(content, match.pos[2], match.len[2]);
    }
    return "";
}
```

The function uses `$` prefix per CLAUDE.md guidance ("private mixin functions not integrated... use `$` prefix for internal scope instead of `private` keyword"). Templates.cfc isn't a mixin, but the prefix convention is harmless here and consistent with the rest of the file.

- [ ] **Step 3: Run the spec — the `_form.cfm` enum test should pass**

```bash
bash tools/test-cli-local.sh
```

Expected: `it("_form.cfm renders a <select> for status:enum, not a textField")` passes. Other `_form.cfm` tests (startFormTag, errorMessagesFor, button) still fail until Task 5.

- [ ] **Step 4: Commit**

```bash
git add cli/lucli/services/Templates.cfc
git commit -m "fix(cli): emit select for enum properties in scaffold form

generateFormFieldsCode now switches on lCase(prop.type)=='enum' and
emits #select(objectName, property, options=...)# with values from
either the inline syntax (status:enum:a,b,c) or, when those are
absent, the model file's existing enum(property=..., values=...)
declaration. Falls back to textField if neither source provides
values, so a bare 'foo:enum' on a model that doesn't declare it
still produces a generator-clean output rather than an empty select.

Also switches the date helper from dateSelect to dateField to match
the tutorial's HTML5-helper style and CLAUDE.md guidance."
```

---

## Task 5: Self-contained `_form.cfm` template (startFormTag + errorMessagesFor + submit)

**Files:**
- Modify: `cli/src/templates/crud/_form.txt`

Today's template wraps just the `|FormFields|` placeholder in a `<cfoutput>`. The tutorial wraps the whole thing in `startFormTag(...)`/`endFormTag()`, includes `errorMessagesFor("post")`, and adds a `<button type="submit">Save</button>`. After this change, `new.cfm` and `edit.cfm` no longer wrap the partial in their own `startFormTag`/`endFormTag` — that move happens in Task 6.

- [ ] **Step 1: Replace `cli/src/templates/crud/_form.txt` with**

```
<cfparam name="|ObjectNameSingular|" default="">
<cfoutput>
#errorMessagesFor("|ObjectNameSingular|")#
#startFormTag(action=IsNumeric(|ObjectNameSingular|.id ?: "") ? "update" : "create", key=|ObjectNameSingular|.id ?: "")#
	|FormFields|
	<button type="submit">Save</button>
#endFormTag()#
</cfoutput>
```

The `IsNumeric(post.id ?: "") ? "update" : "create"` ternary picks the right action automatically — same trick the tutorial uses. `key=post.id ?: ""` passes the empty string when the post is new (Wheels treats an empty key as "no key").

The `|FormFields|` placeholder remains the substitution point for the per-property field code generated in Task 4.

- [ ] **Step 2: Run the spec**

```bash
bash tools/test-cli-local.sh
```

Expected: all `_form.cfm` cases now pass (errorMessagesFor, startFormTag, endFormTag, submit button, select-for-enum).

- [ ] **Step 3: Commit**

```bash
git add cli/src/templates/crud/_form.txt
git commit -m "fix(cli): self-contained scaffold _form partial with startFormTag

The form partial now emits errorMessagesFor + startFormTag +
fields + submit button + endFormTag in one block, matching
tutorial chapter 3. new.cfm and edit.cfm consume the partial as
a whole form rather than wrapping it themselves (next commit)."
```

---

## Task 6: Simplify `new.cfm` and `edit.cfm` to single-line partial includes

**Files:**
- Modify: `cli/src/templates/crud/new.txt`
- Modify: `cli/src/templates/crud/edit.txt`

Now that `_form.cfm` carries `startFormTag`/`endFormTag`/submit/errors, the per-action views become tiny. Match the tutorial verbatim.

- [ ] **Step 1: Replace `cli/src/templates/crud/new.txt` with**

```
<h1>New |ObjectNameSingular|</h1>
<cfoutput>#includePartial("form")#</cfoutput>
```

- [ ] **Step 2: Replace `cli/src/templates/crud/edit.txt` with**

```
<h1>Edit |ObjectNameSingular|</h1>
<cfoutput>#includePartial("form")#</cfoutput>
```

- [ ] **Step 3: Run the spec**

```bash
bash tools/test-cli-local.sh
```

Expected: existing tests for `new.cfm` / `edit.cfm` existence still pass. No new regressions in the form snapshot tests because `_form.cfm` is now the source of truth for form structure.

- [ ] **Step 4: Commit**

```bash
git add cli/src/templates/crud/new.txt cli/src/templates/crud/edit.txt
git commit -m "fix(cli): collapse scaffold new/edit views to bare includePartial"
```

---

## Task 7: Align `index.cfm` and `show.cfm` with tutorial markup

**Files:**
- Modify: `cli/src/templates/crud/index.txt`
- Modify: `cli/src/templates/crud/show.txt`
- Modify: `cli/lucli/services/Templates.cfc:506-532` (generateShowViewProperties — drop Bootstrap classes, use `<p>` blocks)

The tutorial uses clean `<article>` markup in `index.cfm` (no Bootstrap table) and `<h1>#post.title#</h1>` + `<p>` in `show.cfm` (no "View Post" preamble, no Bootstrap buttons).

- [ ] **Step 1: Replace `cli/src/templates/crud/index.txt` with**

```
<cfparam name="|ObjectNamePlural|" default="">
<cfoutput>
<h1>|ObjectNamePluralC|</h1>
<p>#linkTo(route="new|ObjectNameSingularC|", text="New |ObjectNameSingular|")#</p>
<cfloop query="|ObjectNamePlural|">
	<article>
		<h2>#linkTo(route="|ObjectNameSingular|", key=|ObjectNamePlural|.id, text=|ObjectNamePlural|.id)#</h2>
		<!--- CLI-Appends-Here --->
	</article>
</cfloop>
</cfoutput>
```

The `CLI-Appends-Here` marker is reused — Task 7 Step 3 modifies `processViewMarkers` so the `index` action emits `<p>` blocks per property instead of `<td>` cells. (Today the marker is processed differently for index via `CLI-Appends-tbody-Here`/`CLI-Appends-thead-Here`. We collapse those into a single marker.)

- [ ] **Step 2: Replace `cli/src/templates/crud/show.txt` with**

```
<cfparam name="|ObjectNameSingular|" default="">
<cfoutput>
<h1>#|ObjectNameSingular|.id#</h1>
<!--- CLI-Appends-Here --->
<p>
	#linkTo(route="edit|ObjectNameSingularC|", key=|ObjectNameSingular|.id, text="Edit")# ·
	#buttonTo(route="|ObjectNameSingular|", key=|ObjectNameSingular|.id, text="Delete", method="delete")# ·
	#linkTo(route="|ObjectNamePlural|", text="← all |ObjectNamePlural|")#
</p>
</cfoutput>
```

The `<h1>` shows the id by default; the per-property `<p>` blocks (added by `processViewMarkers`) provide the human-readable detail. The tutorial's `<h1>#post.title#</h1>` is more friendly because `title` happens to be a known field; the generator can't assume that, so showing the id is the safe default. The footer's link/button/back-link triple is a verbatim copy of the tutorial.

- [ ] **Step 3: Update `processViewMarkers` to handle the new index markup and drop Bootstrap from show**

In `cli/lucli/services/Templates.cfc:446-466`, replace `processViewMarkers` with:

```cfm
private string function processViewMarkers(required string template, required struct context, string belongsTo = "") {
    var processed = arguments.template;
    var action = structKeyExists(arguments.context, "action") ? arguments.context.action : "";

    // Legacy table-cell markers — keep working in case any user-extended
    // template still uses them, but the new templates don't.
    if (find("<!--- CLI-Appends-thead-Here --->", processed)) {
        processed = replace(processed, "<!--- CLI-Appends-thead-Here --->", generateIndexTableHeaders(arguments.context.properties, arguments.belongsTo), "all");
    }
    if (find("<!--- CLI-Appends-tbody-Here --->", processed)) {
        processed = replace(processed, "<!--- CLI-Appends-tbody-Here --->", generateIndexTableBody(arguments.context.properties, arguments.belongsTo), "all");
    }

    if (find("<!--- CLI-Appends-Here --->", processed)) {
        if (action == "show") {
            processed = replace(processed, "<!--- CLI-Appends-Here --->", generateShowViewProperties(arguments.context.properties, arguments.context.modelName, arguments.belongsTo), "all");
        } else if (action == "index") {
            processed = replace(processed, "<!--- CLI-Appends-Here --->", generateIndexArticleBody(arguments.context.properties, arguments.belongsTo), "all");
        } else {
            processed = replace(processed, "<!--- CLI-Appends-Here --->", "", "all");
        }
    }

    return processed;
}

/**
 * Per-property <p> blocks for the index <article>. Mirrors the tutorial's
 * "post body + status" layout without making any assumptions about which
 * property is the "title" — every property gets its own labelled <p>.
 */
private string function generateIndexArticleBody(required array properties, string belongsTo = "") {
    var lines = [];
    var foreignKeys = buildForeignKeyList(arguments.belongsTo);
    for (var prop in arguments.properties) {
        if (arrayFindNoCase(foreignKeys, prop.name)) {
            var assoc = left(prop.name, len(prop.name) - 2);
            arrayAppend(lines, "		<p>" & variables.helpers.capitalize(assoc) & ": ##|ObjectNamePlural|." & assoc & ".name##</p>");
        } else {
            arrayAppend(lines, "		<p>" & variables.helpers.capitalize(prop.name) & ": ##|ObjectNamePlural|." & prop.name & "##</p>");
        }
    }
    return arrayToList(lines, chr(10));
}
```

- [ ] **Step 4: Update `generateShowViewProperties` to drop Bootstrap classes**

In `cli/lucli/services/Templates.cfc:509-532`, simplify:

```cfm
private string function generateShowViewProperties(required array properties, required string modelName, string belongsTo = "") {
    var displayCode = [];
    var foreignKeys = buildForeignKeyList(arguments.belongsTo);

    for (var prop in arguments.properties) {
        var line = "<p>";
        if (arrayFindNoCase(foreignKeys, prop.name)) {
            var assocName = left(prop.name, len(prop.name) - 2);
            line &= "<strong>" & variables.helpers.capitalize(assocName) & ":</strong> ##encodeForHTML(|ObjectNameSingular|." & assocName & ".name)##";
        } else {
            line &= "<strong>" & variables.helpers.capitalize(prop.name) & ":</strong> ##encodeForHTML(|ObjectNameSingular|." & prop.name & ")##";
        }
        line &= "</p>";
        arrayAppend(displayCode, line);
    }

    return arrayToList(displayCode, chr(10));
}
```

The Bootstrap link/back footer block is removed — `show.txt` now hard-codes the link/button/back-link triple inline (Step 2).

- [ ] **Step 5: Run the spec**

```bash
bash tools/test-cli-local.sh
```

Expected: `index.cfm` and `show.cfm` snapshot tests now pass.

- [ ] **Step 6: Commit**

```bash
git add cli/src/templates/crud/index.txt cli/src/templates/crud/show.txt cli/lucli/services/Templates.cfc
git commit -m "fix(cli): drop bootstrap markup from scaffold index/show views

index.cfm now uses <article> per-record markup matching tutorial
chapter 3 — no <table class='table'>, no btn-group buttons. show.cfm
opens with a clean <h1>#record.id#</h1>, then property <p> blocks
emitted via the existing CLI-Appends-Here marker, then a single
link/buttonTo/back-link footer that matches the tutorial verbatim.

generateShowViewProperties no longer emits Bootstrap classes;
generateIndexArticleBody is added to handle the new <article>
form. Legacy CLI-Appends-thead/tbody markers still work for
existing user templates."
```

---

## Task 8: Dedupe `.resources` injection (named-arg form aware)

**Files:**
- Modify: `cli/lucli/services/Scaffold.cfc:206-250` (updateRoutes)

Today's check is a literal substring search for `'.resources("posts")'`. Tutorial chapter 2 writes `.resources(name="posts", only="index,show")` — different shape, same resource. The scaffold currently appends a duplicate line. Detect any `.resources(...)` call referring to the same resource and skip if present.

- [ ] **Step 1: Replace `updateRoutes` with**

```cfm
public boolean function updateRoutes(required string name) {
    try {
        var routesPath = variables.projectRoot & "/config/routes.cfm";
        if (!fileExists(routesPath)) return false;

        var content = fileRead(routesPath);
        var resourceName = lCase(arguments.name);
        var resourceRoute = '.resources("' & resourceName & '")';

        // Skip if a resources() call referring to the same resource exists in any form:
        //   .resources("posts")
        //   .resources('posts')
        //   .resources(name="posts", ...)
        //   .resources(name='posts', ...)
        if (findNoCase('.resources("' & resourceName & '")', content)) return false;
        if (findNoCase(".resources('" & resourceName & "')", content)) return false;
        if (findNoCase('.resources(name="' & resourceName & '"', content)) return false;
        if (findNoCase(".resources(name='" & resourceName & "'", content)) return false;

        // Try CLI-Appends-Here marker first
        var markerPattern = '// CLI-Appends-Here';
        var indent = '';

        if (find(chr(9) & chr(9) & chr(9) & markerPattern, content)) {
            indent = chr(9) & chr(9) & chr(9);
        } else if (find(chr(9) & chr(9) & markerPattern, content)) {
            indent = chr(9) & chr(9);
        } else if (find(chr(9) & markerPattern, content)) {
            indent = chr(9);
        }

        var fullMarker = indent & markerPattern;
        if (find(fullMarker, content)) {
            content = replace(content, fullMarker, indent & resourceRoute & chr(10) & fullMarker, 'all');
            fileWrite(routesPath, content);
            return true;
        }

        // Fallback: insert before last .end()
        if (find('.end()', content)) {
            var lastEnd = content.lastIndexOf('.end()');
            if (lastEnd >= 0) {
                content = mid(content, 1, lastEnd) & resourceRoute & chr(10) & chr(9) & mid(content, lastEnd + 1, len(content));
                fileWrite(routesPath, content);
                return true;
            }
        }
    } catch (any e) {
        // Routes update is non-critical
    }
    return false;
}
```

The four `findNoCase` calls cover the four common shapes. Anything more exotic (line breaks inside the args, single-line comments around the call) is not detected — that's acceptable: the original `updateRoutes()` already used substring matching, this just extends the scan. Edge cases produce a duplicate the user can hand-merge, which is no worse than today.

- [ ] **Step 2: Run the spec**

```bash
bash tools/test-cli-local.sh
```

Expected: the "no duplicate when one already exists in any form" test passes. The existing "adds resource route to routes.cfm" + "does not duplicate existing route" tests continue to pass.

- [ ] **Step 3: Commit**

```bash
git add cli/lucli/services/Scaffold.cfc
git commit -m "fix(cli): scaffold detects existing .resources(name=...) form

updateRoutes now treats both positional and named-arg forms as
equivalent when detecting an existing resource route. Tutorial
chapter 2 writes .resources(name='posts', only='index,show')
before chapter 3's scaffold runs — the scaffold no longer appends
a duplicate .resources('posts') below it."
```

---

## Task 9: Cross-engine verification (hard gate)

This batch overhauls templates that ship to every engine the framework supports. Verify on at least four engines before opening the PR.

- [ ] **Step 1: Local LuCLI run (Lucee 7 + SQLite)**

```bash
bash tools/test-cli-local.sh
bash tools/test-local.sh
```

Expected: full app + core suite pass on Lucee 7. The CLI test file `cli/lucli/tests/specs/services/ScaffoldSpec.cfc` shows nine new green cases.

- [ ] **Step 2: Docker matrix — Lucee 6, Adobe 2023, Adobe 2025**

```bash
cd rig
docker compose up -d lucee6 adobe2023 adobe2025

# CLI tests don't run inside the docker images — they target a Wheels
# project with the lucli runtime. The container check here is for the
# templates' .cfm output: scaffold a fresh project against each engine
# and confirm the generated files compile.
for engine in lucee6 adobe2023 adobe2025; do
    case "$engine" in
        lucee6)     port=60006 ;;
        adobe2023)  port=62023 ;;
        adobe2025)  port=62025 ;;
    esac
    curl -sf "http://localhost:${port}/wheels/core/tests?db=sqlite&format=json" \
        > "/tmp/${engine}-results.json"
done

for engine in lucee6 adobe2023 adobe2025; do
    python3 -c "
import json
d = json.load(open('/tmp/${engine}-results.json'))
print('${engine}:', d['totalPass'], 'pass,', d['totalFail'], 'fail,', d['totalError'], 'error')
"
done
```

Expected: same totals as `develop` baseline. Templates don't run during framework tests, so a green result here confirms we didn't break anything else; the smoke test in Step 3 is what actually exercises the new templates.

- [ ] **Step 3: End-to-end smoke — generate scaffold against a fresh app**

```bash
TMP=$(mktemp -d) && cd "$TMP"
WHEELS_FRAMEWORK_PATH=/Users/peter/GitHub/wheels-dev/wheels/vendor/wheels \
    wheels new batch-c-smoke --no-open-browser

cd batch-c-smoke

# Match the tutorial chapter 2 setup so chapter 3's command applies.
wheels generate model Post title:string body:text status:enum
# Edit Post.cfc to add: enum(property="status", values="draft,published,archived");
# (or use a sed/cat heredoc to inject it — tutorial chapter 2 shows the body)

cat >> app/models/Post.cfc.tmp <<'CFM'
component extends="Model" {
    function config() {
        enum(property="status", values="draft,published,archived");
    }
}
CFM
mv app/models/Post.cfc.tmp app/models/Post.cfc

wheels migrate latest

wheels generate scaffold Post title:string body:text status:enum

# Verify each file matches the tutorial expectations
diff <(grep -E "params\.post|model\(\"Post\"\)\.new|redirectTo\(route" app/controllers/Posts.cfc | sort -u) - <<'EOF' || echo "FAIL Posts.cfc"
            post = params.post;
            post = model("Post").new();
            post = model("Post").new(params.post);
            redirectTo(route="post", key=post.id);
            redirectTo(route="posts");
EOF
grep -q '<select' app/views/posts/_form.cfm && echo "OK enum select" || echo "FAIL enum select"
grep -q '<article>' app/views/posts/index.cfm && echo "OK article markup" || echo "FAIL article markup"
grep -qv 'class="table"' app/views/posts/index.cfm && echo "OK no bootstrap table" || echo "FAIL bootstrap table"
grep -qE '\.resources\(name="posts"|\.resources\("posts"\)' config/routes.cfm \
    | wc -l \
    | awk '{ if ($1 == 1) print "OK no duplicate resources"; else print "FAIL duplicate resources" }'

cd / && rm -rf "$TMP"
```

The exact `grep` patterns are illustrative — the goal is to manually eyeball each generated file against the tutorial chapter 3 markdown source. If any file diverges, jump back to the relevant Task and re-run Step 3 there.

- [ ] **Step 4: Cross-engine note for the PR**

Capture the Step 1-3 results in a section of the PR body so reviewers can see the verification matrix at a glance. Format: `engine | pass | fail | error` per row, plus a "smoke OK" line.

- [ ] **Step 5: No commit (verification only)**

---

## Task 10: Update triage doc + open PR

**Files:**
- Modify: `docs/superpowers/plans/2026-04-29-fresh-vm-onboarding-findings.md`

- [ ] **Step 1: Mark finding #4 as shipped, with a per-task SHA list**

```diff
-### [ ] 4. `wheels generate scaffold` output disagrees with chapter 3 of the tutorial
+### [x] 4. `wheels generate scaffold` output disagrees with chapter 3 of the tutorial — **shipped in batch C**
+
+Tasks 2-8 SHAs (controller, enum parser, form select, _form, new/edit, index/show, dedupe routes):
+`<sha-task2>`, `<sha-task3>`, `<sha-task4>`, `<sha-task5>`, `<sha-task6>`, `<sha-task7>`, `<sha-task8>`.
```

- [ ] **Step 2: Add a "Batch C" row to the Shipped table**

```markdown
### Batch C — Scaffold templates align with tutorial (2026-04-XX)

Per [batch C plan](./2026-04-29-fresh-vm-batch-c-scaffold-align.md).

| # | Item | Commit | Repo |
|---|------|--------|------|
| 4 (controller) | route-model-binding + save() + route-form redirects | `<sha>` | wheels |
| 4 (enum parser) | accept name:enum:values syntax | `<sha>` | wheels |
| 4 (enum form) | emit select for enum properties | `<sha>` | wheels |
| 4 (_form) | self-contained startFormTag/errorMessagesFor/submit | `<sha>` | wheels |
| 4 (new/edit) | collapse to bare includePartial | `<sha>` | wheels |
| 4 (index/show) | drop Bootstrap, use article + p markup | `<sha>` | wheels |
| 4 (routes) | dedupe .resources injection (named-arg aware) | `<sha>` | wheels |
```

- [ ] **Step 3: Commit**

```bash
git add docs/superpowers/plans/2026-04-29-fresh-vm-onboarding-findings.md
git commit -m "docs(docs): mark batch C items shipped"
```

- [ ] **Step 4: Push the branch and open the PR**

```bash
git push -u origin HEAD
gh pr create --base develop --title "fix(cli): scaffold templates align with tutorial chapter 3" --body "$(cat <<'EOF'
## Summary
- Scaffold-generated `Posts.cfc` uses route-model-binding (`params.post`), `model().new()` + `.save()`, and route-form `redirectTo(route, key)` — matching tutorial chapter 3 verbatim.
- `_form.cfm` is self-contained: `startFormTag` + `errorMessagesFor` + form fields + submit button + `endFormTag` in one partial.
- Property type `enum` (e.g. `status:enum:draft,published,archived` or `status:enum` with values declared on the model) emits a `<select>` instead of a `textField`.
- `index.cfm` uses `<article>` markup; `show.cfm` uses `<h1>id</h1>` + per-property `<p>` blocks. Bootstrap classes removed from generator output.
- `new.cfm` and `edit.cfm` collapse to `<h1>...</h1>` + `<cfoutput>#includePartial("form")#</cfoutput>`.
- Route-injection deduplication recognises both `.resources("posts")` and `.resources(name="posts", ...)` forms — no more duplicate lines when chapter 2 already declared the resource.

Closes finding ##4 in `docs/superpowers/plans/2026-04-29-fresh-vm-onboarding-findings.md`, including the embedded enum sub-finding.

## Test plan
- [ ] `bash tools/test-cli-local.sh` — all new ScaffoldSpec snapshot tests pass
- [ ] `bash tools/test-local.sh` — full app + core suite stable
- [ ] Docker matrix: `lucee6`, `adobe2023`, `adobe2025` core tests match `develop` baseline
- [ ] Manual: `wheels new && wheels generate model Post title:string body:text status:enum && wheels migrate latest && wheels generate scaffold Post title:string body:text status:enum` produces files that pass the tutorial chapter 3 prose verbatim
- [ ] Manual: pre-seed `config/routes.cfm` with `.resources(name="posts", only="index,show")` then run scaffold — verify only one `.resources` line for `posts` exists afterwards

## Verification matrix
| Engine | Pass | Fail | Error |
|--------|------|------|-------|
| Lucee 7 (LuCLI) | <fill> | <fill> | <fill> |
| Lucee 6 (Docker) | <fill> | <fill> | <fill> |
| Adobe 2023 (Docker) | <fill> | <fill> | <fill> |
| Adobe 2025 (Docker) | <fill> | <fill> | <fill> |

🤖 Generated with [Claude Code](https://claude.com/claude-code)
EOF
)"
```

- [ ] **Step 5: Report the PR URL and per-task SHAs**

After squash-merge, fill the SHA placeholders in the triage doc's batch-C table.

---

## Out of scope

These deliberately stay out of batch C:

- **`wheels generate admin`** — admin templates live in `cli/src/templates/admin/` and aren't touched by the tutorial; their drift, if any, is a separate question.
- **API-only scaffold (`generateApiResource`)** — chapter 3 doesn't cover the API path. Existing tests still cover it; it's unaffected by the changes here.
- **Hiding the auto-generated specs from the user** — the triage entry suggests "document or hide the auto-generated specs so chapter 7 isn't surprising." Documentation is a doc-only change for the next batch A successor; hiding is a behavior change that needs separate scoping.
- **Bringing the `cli/src/templates/` and `cli/lucli/templates/app/app/snippets/` copies down to one source** — out of scope; for now we keep them byte-identical via Task 2 Step 2 and accept the duplication. A consolidation pass would be a separate refactor.
- **Updating `web/sites/guides/.../03-crud-scaffold.mdx`** — the tutorial already documents the divergence in an `<Aside type="caution">`. Once this batch lands, that aside should be tightened or removed; that's a doc-only follow-up (batch A successor).

---

## Open questions

- **Should `dateField` replace `dateSelect` everywhere in the form generator, or only for the scaffold path?** Task 4 makes the swap. CLAUDE.md's HTML5-helper guidance favours `dateField`, but admin templates may still expect `dateSelect`. Verify before merging that admin generators (which share `Templates.cfc`) still produce sensible output.
- **Is the `name:enum:values` colon-delimited syntax discoverable enough?** A reader who runs `wheels generate scaffold Post status:enum:a,b,c` from the CLI gets exactly what they need, but the tutorial uses `status:enum` (no values) and expects the model file to declare them. The implicit-fallback path is the friendly one; the inline path is for cases where the model doesn't exist yet. Document both in `web/sites/guides/.../command-line-tools/commands/generate.mdx` as a follow-up.
- **Does the index template need a "humanise the heading" affordance?** Today it shows `#post.id#` for the link text in the `<h2>`. The tutorial uses `#posts.title#`, but the generator can't safely assume `title` exists. We could detect a `title`/`name`/`label` property and use it; flagged for a follow-up.
