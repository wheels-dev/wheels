/**
 * Names given to `wheels generate` / `wheels new` are written into generated
 * CFML (models, migrations, forms, config/app.cfm), so only plain names are
 * accepted. The checks go by character class, not ^...$: CFML's `$` also
 * matches before a trailing newline, so an anchored pattern let "User" & LF in.
 */
component extends="wheels.wheelstest.system.BaseSpec" {

	function beforeAll() {
		variables.testHelper = new cli.lucli.tests.TestHelper();
		variables.tempRoot = testHelper.scaffoldTempProject(expandPath("/"));
		variables.moduleRoot = expandPath("/cli/lucli/");
		variables.helpers = new cli.lucli.services.Helpers();
		variables.templates = new cli.lucli.services.Templates(
			helpers = variables.helpers,
			projectRoot = variables.tempRoot,
			moduleRoot = variables.moduleRoot
		);
		variables.codegen = new cli.lucli.services.CodeGen(
			templateService = variables.templates,
			helpers = variables.helpers,
			projectRoot = variables.tempRoot
		);
		variables.paths = new cli.lucli.services.GeneratorPaths();
		variables.mod = new cli.lucli.Module(cwd = variables.tempRoot);
		makePublic(variables.mod, "$parsePropertyArg");
		for (var fnName in ["generateMigration", "generateRoute", "generateAdmin", "generateAuth", "generateTest", "generatePolicy"]) {
			makePublic(variables.mod, fnName);
		}
		variables.scaffold = new cli.lucli.services.Scaffold(
			codeGenService = variables.codegen,
			helpers = variables.helpers,
			projectRoot = variables.tempRoot,
			moduleRoot = variables.moduleRoot
		);
		variables.admin = new cli.lucli.services.Admin(
			helpers = variables.helpers,
			projectRoot = variables.tempRoot,
			moduleRoot = variables.moduleRoot
		);
	}

	function afterAll() {
		testHelper.cleanupTempProject(variables.tempRoot);
	}

	private any function pathOf(required string location) {
		return createObject("java", "java.io.File").init(arguments.location).toPath();
	}

	/** Links `link` to `target`; the caller removes it with unlink() before cleanup. */
	private void function symlink(required string link, required string target) {
		var noAttributes = createObject("java", "java.lang.reflect.Array").newInstance(
			createObject("java", "java.lang.Class").forName("java.nio.file.attribute.FileAttribute"),
			javaCast("int", 0)
		);
		createObject("java", "java.nio.file.Files").createSymbolicLink(pathOf(arguments.link), pathOf(arguments.target), noAttributes);
	}

	/** Removes the link itself, never what it points at. */
	private void function unlink(required string link) {
		createObject("java", "java.nio.file.Files").deleteIfExists(pathOf(arguments.link));
	}

	private boolean function escapes(required any fn) {
		var state = {type = ""};
		try {
			arguments.fn();
		} catch (any e) {
			state.type = e.type;
		}
		return state.type == "Wheels.Generate.OutsideProject";
	}

	/** A throwaway project plus a directory outside it that a link inside the project points at. */
	private struct function linkFixture() {
		var fixture = {root = testHelper.scaffoldTempProject(expandPath("/")), outside = getTempDirectory() & "gen-outside-" & createUUID()};
		directoryCreate(fixture.outside);
		fileWrite(fixture.outside & "/keep.txt", "outside");
		fixture.codegen = new cli.lucli.services.CodeGen(templateService = new cli.lucli.services.Templates(helpers = variables.helpers, projectRoot = fixture.root, moduleRoot = variables.moduleRoot), helpers = variables.helpers, projectRoot = fixture.root);
		fixture.admin = new cli.lucli.services.Admin(helpers = variables.helpers, projectRoot = fixture.root, moduleRoot = variables.moduleRoot);
		fixture.destroy = new cli.lucli.services.Destroy(helpers = variables.helpers, projectRoot = fixture.root, moduleRoot = variables.moduleRoot);
		fixture.mod = new cli.lucli.Module(cwd = fixture.root);
		makePublic(fixture.mod, "generateMigration");
		return fixture;
	}

	private array function outsideFiles(required struct fixture) {
		return directoryList(arguments.fixture.outside, true, "name");
	}

	/** `#record.column#` outputs that are not wrapped in a function call (raw record data). */
	private array function $rawRecordOutputs(required string content, required string names) {
		var found = [];
		var pos = 1;
		while (true) {
			var match = ReFind("##(#arguments.names#)\.[A-Za-z_][A-Za-z0-9_]*##", arguments.content, pos, true);
			if (match.pos[1] == 0) {
				break;
			}
			ArrayAppend(found, Mid(arguments.content, match.pos[1], match.len[1]));
			pos = match.pos[1] + match.len[1];
		}
		return found;
	}

	/** The generated lines that output `needle` (a record reference). */
	private array function $outputLines(required string content, required string needle) {
		var lines = [];
		for (var line in ListToArray(arguments.content, Chr(10))) {
			// Helper calls (linkTo, buttonTo) need the framework and encode their text themselves.
			if (Find(arguments.needle, line) && Find("##", line) && !ReFindNoCase("(linkTo|buttonTo)\(", line)) {
				ArrayAppend(lines, Trim(line));
			}
		}
		return lines;
	}

	/** Interpolates one generated line's #...# expressions with `name` bound to `value`. */
	private string function $renderLine(required string line, required string name, required any value) {
		local[arguments.name] = arguments.value;
		return Evaluate(DE(arguments.line));
	}

	private void function dropFixture(required struct fixture) {
		testHelper.cleanupTempProject(arguments.fixture.root);
		directoryDelete(arguments.fixture.outside, true);
	}

	private boolean function refuses(required any fn) {
		var state = {type = ""};
		try {
			arguments.fn();
		} catch (any e) {
			state.type = e.type;
		}
		return state.type == "Wheels.Generate.InvalidName";
	}

	function run() {

		var lf = Chr(10);
		var cr = Chr(13);

		describe("GeneratorPaths name rules", () => {

			it("accepts plain identifiers and package/Name component names", () => {
				expect(paths.isIdentifier("User")).toBeTrue();
				expect(paths.isIdentifier("user_name2")).toBeTrue();
				expect(paths.componentName("api/Products", "controller")).toBe("api/Products");
				expect(paths.viewAction("_partial")).toBe("_partial");
			});

			it("refuses a trailing line feed or carriage return, even though ^...$ would match", () => {
				for (var bad in ["User" & lf, "User" & cr, "User" & cr & lf, lf & "User"]) {
					expect(paths.isIdentifier(bad)).toBeFalse("accepted a name with a line break");
				}
				expect(refuses(() => paths.componentName("api/Products" & lf, "controller"))).toBeTrue();
				expect(refuses(() => paths.viewAction("show" & lf))).toBeTrue();
			});

			it("refuses quotes, ## and other characters outside the class, a leading digit, empty and overlong names", () => {
				for (var bad in ['a"b', "a##b", "a'b", "a b", "a;b", "a/b", "1abc", "", RepeatString("a", 129)]) {
					expect(paths.isIdentifier(bad)).toBeFalse("accepted [#bad#]");
				}
				expect(paths.isIdentifier(RepeatString("a", 128))).toBeTrue();
			});

		});

		describe("generator property and association arguments", () => {

			it("still parses valid properties, typed and enum", () => {
				expect(mod.$parsePropertyArg("email:string").name).toBe("email");
				expect(mod.$parsePropertyArg("price:decimal{10,2}").type).toBe("decimal");
				expect(mod.$parsePropertyArg("status:enum:draft,published").values).toBe("draft,published");
			});

			it("emits the same trimmed enum values and association names it validated", () => {
				expect(mod.$parsePropertyArg("status:enum:draft, published").values).toBe("draft,published");
				makePublic(mod, "$validAssociationNames");
				expect(mod.$validAssociationNames([" user", "post "], "belongsTo")).toBe(["user", "post"]);
			});

			it("refuses a property name, type or enum value that isn't plain", () => {
				expect(refuses(() => mod.$parsePropertyArg('bad"name:string'))).toBeTrue();
				expect(refuses(() => mod.$parsePropertyArg("name" & lf & ":string"))).toBeTrue();
				expect(refuses(() => mod.$parsePropertyArg("name:str##ing"))).toBeTrue();
				expect(refuses(() => mod.$parsePropertyArg('status:enum:draft,pub"lished'))).toBeTrue();
			});

			it("refuses a model, table or property name that isn't plain when generating a model", () => {
				expect(refuses(() => codegen.generateModel(name = 'Bad"Model'))).toBeTrue();
				expect(refuses(() => codegen.generateModel(name = "Widget", tableName = "widgets" & lf))).toBeTrue();
				expect(refuses(() => codegen.generateModel(name = "Widget", properties = [{name = "x##y", type = "string"}]))).toBeTrue();
				expect(fileExists(tempRoot & "/app/models/Bad""Model.cfc")).toBeFalse();
			});

		});

		describe("controller action and helper function names", () => {

			it("refuses an action name that isn't a plain identifier, before writing the controller", () => {
				expect(refuses(() => codegen.generateController(name = "Probepages", actions = ["index() { } function spare"]))).toBeTrue();
				expect(refuses(() => codegen.generateController(name = "Probepages", actions = ["index,show() {}"]))).toBeTrue();
				// trim() drops surrounding whitespace (and the trimmed name is what is emitted);
				// a line break INSIDE the name is refused.
				expect(refuses(() => codegen.generateController(name = "Probepages", actions = ["ab" & lf & "out"]))).toBeTrue();
				expect(fileExists(tempRoot & "/app/controllers/Probepages.cfc")).toBeFalse("a controller was written for an invalid action");
			});

			it("still generates valid actions, space- or comma-separated", () => {
				var result = codegen.generateController(name = "Probeok", actions = ["index,show", " about "]);
				expect(result.success).toBeTrue();
				var content = fileRead(tempRoot & "/app/controllers/Probeok.cfc");
				for (var fnName in ["index", "show", "about"]) {
					expect(reFindNoCase("function\s+#fnName#\(\)", content) > 0).toBeTrue("missing function #fnName#()");
				}
			});

			it("refuses a helper or helper function name that isn't plain, before writing the helper", () => {
				expect(refuses(() => codegen.generateHelper(name = "Probefmt", functions = ["x(required string value) {} function y"]))).toBeTrue();
				expect(refuses(() => codegen.generateHelper(name = "Probefmt", functions = ["fmt" & cr]))).toBeTrue();
				expect(refuses(() => codegen.generateHelper(name = "Probefmt", functions = ["fm" & lf & "t"]))).toBeTrue();
				expect(refuses(() => codegen.generateHelper(name = 'Probe"fmt'))).toBeTrue();
				expect(fileExists(tempRoot & "/app/helpers/ProbefmtHelper.cfc")).toBeFalse("a helper was written for an invalid function name");
			});

			it("still generates a helper with valid function names", () => {
				var result = codegen.generateHelper(name = "Probegood", functions = ["formatPrice", "shortDate"]);
				expect(result.success).toBeTrue();
				var content = fileRead(tempRoot & "/app/helpers/ProbegoodHelper.cfc");
				expect(findNoCase("function formatPrice(", content) > 0 && findNoCase("function shortDate(", content) > 0).toBeTrue();
			});

		});

		describe("every other generator entry point", () => {

			it("refuses a policy, test, scaffold, api-resource or auth model name that isn't plain", () => {
				expect(codegen.validateName("Post" & lf, "policy").valid).toBeFalse("validateName accepted a trailing line feed");
				expect(refuses(() => codegen.generatePolicy(name = "Probe" & lf))).toBeTrue();
				expect(refuses(() => codegen.generateTest(type = "model", name = 'Probe"Spec'))).toBeTrue();
				expect(refuses(() => codegen.generateTest(type = "model", name = "Probe", modelName = "Probe" & lf))).toBeTrue();
				expect(refuses(() => codegen.generateTest(type = "controller", name = "Probes", belongsTo = "user,a""b"))).toBeTrue();
				// scaffold and api-resource report failures in results.errors instead of throwing
				for (var result in [scaffold.generateScaffold(name = "Probe" & lf, properties = []), scaffold.generateApiResource(name = 'Probe"x', properties = [])]) {
					expect(result.success).toBeFalse();
					expect(arrayToList(result.errors)).toInclude("Invalid model name");
					expect(arrayLen(result.generated)).toBe(0);
				}
				expect(refuses(() => scaffold.generateAuth(model = "Account" & lf))).toBeTrue();
				expect(refuses(() => scaffold.updateRoutes('probes"); abort; ("'))).toBeTrue();
				expect(directoryExists(tempRoot & "/app/policies") && arrayLen(directoryList(tempRoot & "/app/policies", false, "name", "Probe*"))).toBeFalse("a policy was written");
				expect(fileExists(tempRoot & "/app/models/Probe.cfc")).toBeFalse("a model was written");
			});

			it("refuses a migration or route name that isn't plain, from the CLI", () => {
				expect(refuses(() => mod.generateMigration(["Add" & lf & "Email"]))).toBeTrue();
				expect(refuses(() => mod.generateMigration(["../../escape"]))).toBeTrue();
				expect(refuses(() => mod.generateRoute(['posts"); abort; ("']))).toBeTrue();
				expect(refuses(() => mod.generatePolicy(["Post" & lf]))).toBeTrue("policy refuses an invalid name too");
				var migrations = directoryExists(tempRoot & "/app/migrator/migrations")
					? directoryList(tempRoot & "/app/migrator/migrations", false, "name", "*Email*") : [];
				expect(arrayLen(migrations)).toBe(0, "a migration was written");
			});

			it("turns hyphens in a migration or property name into underscores, and still refuses anything else", () => {
				mod.generateMigration(["create-probe-table"]);
				var written = directoryList(tempRoot & "/app/migrator/migrations", false, "name", "*_create_probe_table.cfc");
				expect(arrayLen(written)).toBe(1, "the hyphenated migration name wasn't normalised");
				expect(mod.$parsePropertyArg("display-name:string").name).toBe("display_name");
				expect(refuses(() => mod.generateMigration(["-leading"]))).toBeTrue();
				expect(refuses(() => mod.generateMigration(['create-"x']))).toBeTrue();
				expect(refuses(() => mod.$parsePropertyArg("display-na" & lf & "me:string"))).toBeTrue();
			});

			it("refuses an admin model name before introspecting, and bad introspection data before writing", () => {
				// No server runs here: the name check comes first, so this throws InvalidName, not a server error.
				expect(refuses(() => mod.generateAdmin(["Post&command=other"]))).toBeTrue();
				var good = {model = "Probeadmin", tableName = "probeadmins", primaryKey = "id", columns = [{name = "id", type = "integer", primaryKey = true}, {name = "title", type = "string"}], associations = []};
				var shapes = [
					{model = 'Probe"admin'},
					{tableName = "probeadmins" & lf},
					{primaryKey = "id##x"},
					{columns = [{name = 'title") abort; //'}]},
					{associations = [{type = "belongsTo", name = "user", modelName = "User" & lf}]},
					{associations = [{type = "belongsTo", name = "us er"}]}
				];
				for (var shape in shapes) {
					var data = Duplicate(good);
					StructAppend(data, shape, true);
					expect(refuses(() => admin.generateAdmin(modelData = data, noRoutes = true))).toBeTrue("accepted #SerializeJSON(shape)#");
				}
				expect(fileExists(tempRoot & "/app/controllers/admin/Probeadmins.cfc")).toBeFalse("an admin controller was written");
				var result = admin.generateAdmin(modelData = good, noRoutes = true);
				expect(result.success).toBeTrue();
				expect(fileExists(tempRoot & "/app/controllers/admin/Probeadmins.cfc")).toBeTrue();
			});

		});

		describe("writes through a symlink that points outside the project", () => {

			it("admin refuses a symlinked app/controllers/admin before writing anything", () => {
				var fx = linkFixture();
				directoryCreate(fx.root & "/app/controllers", true, true);
				symlink(fx.root & "/app/controllers/admin", fx.outside);
				var data = {model = "Probelink", tableName = "probelinks", primaryKey = "id", columns = [{name = "id", type = "integer", primaryKey = true}, {name = "title", type = "string"}], associations = []};
				var refused = escapes(() => fx.admin.generateAdmin(modelData = data, noRoutes = true));
				var leaked = outsideFiles(fx);
				var viewsMade = directoryExists(fx.root & "/app/views/admin/probelinks");
				unlink(fx.root & "/app/controllers/admin");
				dropFixture(fx);
				expect(refused).toBeTrue("admin wrote through the link");
				expect(leaked).toBe(["keep.txt"]);
				expect(viewsMade).toBeFalse("views were created before the controller destination was checked");
			});

			it("generate test and generate migration refuse a symlinked destination directory", () => {
				var fx = linkFixture();
				directoryCreate(fx.root & "/tests/specs", true, true);
				if (directoryExists(fx.root & "/tests/specs/models")) {
					directoryDelete(fx.root & "/tests/specs/models", true);
				}
				symlink(fx.root & "/tests/specs/models", fx.outside);
				directoryCreate(fx.root & "/app/migrator", true, true);
				if (directoryExists(fx.root & "/app/migrator/migrations")) {
					directoryDelete(fx.root & "/app/migrator/migrations", true);
				}
				symlink(fx.root & "/app/migrator/migrations", fx.outside);
				var testRefused = escapes(() => fx.codegen.generateTest(type = "model", name = "Probelink"));
				var migrationRefused = escapes(() => fx.mod.generateMigration(["CreateProbelinks"]));
				var leaked = outsideFiles(fx);
				unlink(fx.root & "/tests/specs/models");
				unlink(fx.root & "/app/migrator/migrations");
				dropFixture(fx);
				expect(testRefused).toBeTrue("generate test wrote through the link");
				expect(migrationRefused).toBeTrue("generate migration wrote through the link");
				expect(leaked).toBe(["keep.txt"]);
			});

			it("destroy refuses to delete through a symlinked file or directory", () => {
				var fx = linkFixture();
				directoryCreate(fx.root & "/app/models", true, true);
				directoryCreate(fx.root & "/app/views", true, true);
				symlink(fx.root & "/app/models/Victim.cfc", fx.outside & "/keep.txt");
				symlink(fx.root & "/app/views/victims", fx.outside);
				var fileRefused = escapes(() => fx.destroy.destroyModel("Victim"));
				var dirRefused = escapes(() => fx.destroy.destroyView("victim"));
				var kept = fileExists(fx.outside & "/keep.txt");
				unlink(fx.root & "/app/models/Victim.cfc");
				unlink(fx.root & "/app/views/victims");
				dropFixture(fx);
				expect(fileRefused).toBeTrue("destroy deleted through a file link");
				expect(dirRefused).toBeTrue("destroy deleted through a directory link");
				expect(kept).toBeTrue("the file outside the project was deleted");
			});

		});

		describe("generated views encode record data", () => {

			it("scaffold index and show views encode every record field, including the <h1> title", () => {
				scaffold.generateScaffold(name = "Probeview", properties = [{name = "title", type = "string"}, {name = "body", type = "text"}]);
				var index = FileRead(tempRoot & "/app/views/probeviews/index.cfm");
				var show = FileRead(tempRoot & "/app/views/probeviews/show.cfm");
				expect($rawRecordOutputs(index & show, "probeviews|probeview")).toBe([]);
				expect(show).toInclude("<h1>##encodeForHTML(probeview.title)##</h1>");
				// Render the generated lines with markup in the record and check it is escaped.
				var record = {title = '<img src=x onerror=alert(1)>', body = '<img src=x onerror=alert(2)>'};
				var renderLines1 = $outputLines(show, "probeview.");
				expect(ArrayLen(renderLines1)).toBeGT(0, "no generated output line references " & "probeview.");
				for (var line in renderLines1) {
					expect($renderLine(line, "probeview", record)).notToInclude("<img");
				}
				var rows = QueryNew("id,title,body", "integer,varchar,varchar", [[1, record.title, record.body]]);
				var renderLines2 = $outputLines(index, "probeviews.");
				expect(ArrayLen(renderLines2)).toBeGT(0, "no generated output line references " & "probeviews.");
				for (var line in renderLines2) {
					expect($renderLine(line, "probeviews", rows)).notToInclude("<img");
				}
			});

			it("both index builders (card body and table cells) encode every field", () => {
				makePublic(variables.templates, "generateIndexArticleBody");
				makePublic(variables.templates, "generateIndexTableBody");
				var props = [{name = "title", type = "string"}, {name = "website", type = "string"}];
				// The card body leaves out the display property (title): the card's linkTo shows it.
				for (var built in [variables.templates.generateIndexArticleBody(props), variables.templates.generateIndexTableBody(props)]) {
					expect(built).toInclude("encodeForHTML(|ObjectNamePlural|.website)");
					expect(ReFind("##\|ObjectNamePlural\|\.[A-Za-z]+##", built)).toBe(0, "a raw field output remains: " & built);
				}
			});

			it("admin index and show views output and encode every record field", () => {
				var data = {model = "Probeenc", tableName = "probeencs", primaryKey = "id", columns = [{name = "id", type = "integer", primaryKey = true}, {name = "title", type = "string"}], associations = []};
				admin.generateAdmin(modelData = data, noRoutes = true, force = true);
				var index = FileRead(tempRoot & "/app/views/admin/probeencs/index.cfm");
				var show = FileRead(tempRoot & "/app/views/admin/probeencs/show.cfm");
				expect($rawRecordOutputs(index & show, "probeencs|probeenc")).toBe([]);
				// The record cells must be inside the output tag, or they print as literal text.
				// Tag names are built with Chr(60): a literal cf tag in a string breaks Lucee's tag scanner.
				var openOut = Chr(60) & "cfoutput>";
				var closeOut = Chr(60) & "/cfoutput>";
				expect(Find(openOut, index) > 0 && Find(openOut, index) < Find(Chr(60) & "cfloop", index) && Find(closeOut, index) > Find(Chr(60) & "/cfloop>", index)).toBeTrue("admin index rows are outside the output tag");
				expect(Find(openOut, show) > 0 && Find(openOut, show) < Find("<dl>", show) && Find(closeOut, show) > Find("</dl>", show)).toBeTrue("admin show fields are outside the output tag");
				var rows = QueryNew("id,title", "integer,varchar", [[1, '<img src=x onerror=alert(1)>']]);
				var renderLines3 = $outputLines(index, "probeencs.title");
				expect(ArrayLen(renderLines3)).toBeGT(0, "no generated output line references " & "probeencs.title");
				for (var line in renderLines3) {
					expect($renderLine(line, "probeencs", rows)).notToInclude("<img");
				}
				var renderLines4 = $outputLines(show, "probeenc.title");
				expect(ArrayLen(renderLines4)).toBeGT(0, "no generated output line references " & "probeenc.title");
				for (var line in renderLines4) {
					expect($renderLine(line, "probeenc", {id = 1, title = '<img src=x onerror=alert(1)>'})).notToInclude("<img");
				}
			});

		});

		describe("dry run and app creation have no filesystem side effects", () => {

			it("generate --dry-run creates no directory and admin --dry-run writes no file", () => {
				request.$wheelsGenerateDryRun = true;
				request.$wheelsDryRunPaths = [];
				try {
					paths.ensureDirectoryInside(tempRoot, tempRoot & "/app/views/drydir3852");
					var data = {model = "Probedry", tableName = "probedrys", primaryKey = "id", columns = [{name = "id", type = "integer", primaryKey = true}, {name = "title", type = "string"}], associations = []};
					admin.generateAdmin(modelData = data, noRoutes = true);
					var recorded = ArrayLen(request.$wheelsDryRunPaths);
				} finally {
					StructDelete(request, "$wheelsGenerateDryRun");
					StructDelete(request, "$wheelsDryRunPaths");
				}
				expect(directoryExists(tempRoot & "/app/views/drydir3852")).toBeFalse("dry run created a directory");
				expect(fileExists(tempRoot & "/app/controllers/admin/Probedrys.cfc")).toBeFalse("admin dry run wrote the controller");
				expect(directoryExists(tempRoot & "/app/views/admin/probedrys")).toBeFalse("admin dry run created the view folder");
				expect(recorded).toBe(6, "admin dry run should list the controller and its 5 views");
			});

			it("wheels create app refuses a path-like name before creating anything", () => {
				var parent = GetDirectoryFromPath(tempRoot & "/");
				for (var bad in ["../createtrav", "..\createtrav", "/tmp/createtrav"]) {
					mod.__arguments = ["app", bad];
					expect(refuses(() => mod.create())).toBeTrue("create app accepted [#bad#]");
				}
				expect(directoryExists(tempRoot & "/../createtrav")).toBeFalse("create app wrote outside the working directory");
			});

			it("the outside-the-project error does not reveal absolute paths", () => {
				var state = {message = ""};
				try {
					paths.assertInside(tempRoot, tempRoot & "/../../escape.cfc");
				} catch (any e) {
					state.message = e.message;
				}
				expect(state.message).notToInclude(tempRoot);
				expect(state.message).notToInclude(GetTempDirectory());
				expect(state.message).toInclude("escape.cfc");
			});

		});

		describe("wheels destroy names", () => {

			it("refuses a path-like or quoted name for every destroy type before planning or writing anything", () => {
				var destroy = new cli.lucli.services.Destroy(helpers = variables.helpers, projectRoot = tempRoot, moduleRoot = variables.moduleRoot);
				var migrationsDir = tempRoot & "/app/migrator/migrations";
				var before = directoryExists(migrationsDir) ? arrayLen(directoryList(migrationsDir, false, "name")) : 0;
				// Trailing whitespace is trimmed before use, so a line break INSIDE the name is the case.
				for (var bad in ["../x", 'Ab"c', "a b", "a" & Chr(10) & "b"]) {
					expect(refuses(() => destroy.previewDestroy(bad, "resource"))).toBeTrue("preview accepted [#bad#]");
					expect(refuses(() => destroy.destroyResource(bad))).toBeTrue("destroy resource accepted [#bad#]");
					expect(refuses(() => destroy.destroyModel(bad))).toBeTrue("destroy model accepted [#bad#]");
					expect(refuses(() => destroy.destroyController(bad))).toBeTrue("destroy controller accepted [#bad#]");
				}
				// Views report an invalid path instead of throwing (DestroySpec's contract).
				for (var badView in ["../../x/y", 'posts/in"dex', 'Ab"c', "products/.."]) {
					expect(destroy.destroyView(badView).success).toBeFalse("destroy view accepted [#badView#]");
					expect(arrayToList(destroy.previewDestroy(badView, "view"))).toInclude("Invalid view path");
				}
				var after = directoryExists(migrationsDir) ? arrayLen(directoryList(migrationsDir, false, "name")) : 0;
				expect(after).toBe(before, "a refused destroy wrote a migration");
			});

			it("generates no drop-table migration when there was no model, and still does for a real one", () => {
				var destroy = new cli.lucli.services.Destroy(helpers = variables.helpers, projectRoot = tempRoot, moduleRoot = variables.moduleRoot);
				var none = destroy.destroyResource("Nosuchthing");
				expect(none.migrationPath).toBe("");
				expect(arrayToList(none.warnings)).toInclude("no drop-table migration");
				expect(destroy.destroyModel("Nosuchthing").migrationPath).toBe("");
				codegen.generateModel(name = "Probegone");
				var real = destroy.destroyModel("Probegone");
				expect(len(real.migrationPath) > 0 && fileExists(real.migrationPath)).toBeTrue("no migration for a model that existed");
				fileDelete(real.migrationPath);
			});

		});

		describe("wheels new app name", () => {

			it("refuses an app name with quotes, ## or a line break before creating anything", () => {
				for (var bad in ['my"app', "my##app", "myapp" & lf, "../escape"]) {
					expect(refuses(() => mod.new(arg1 = bad))).toBeTrue("accepted app name [#bad#]");
				}
			});

		});

	}

}
