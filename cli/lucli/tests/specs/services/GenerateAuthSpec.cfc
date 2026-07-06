/**
 * Tests `wheels generate auth` (issue #3155) — the session/token/jwt
 * authentication scaffold built on the wheels.auth primitives.
 *
 * Service-level coverage runs Scaffold.generateAuth() directly against
 * isolated temp projects (one per strategy fixture). A small Module-level
 * describe verifies the generate() dispatch reaches generateAuth.
 */
component extends="wheels.wheelstest.system.BaseSpec" {

	function beforeAll() {
		variables.testHelper = new cli.lucli.tests.TestHelper();
		variables.moduleRoot = expandPath("/cli/lucli/");
		variables.helpers = new cli.lucli.services.Helpers();

		// One temp project per strategy fixture, generated once up front.
		variables.fixtures = {};
		variables.fixtures.session = $makeFixture({});
		variables.fixtures.noReg = $makeFixture({registration: false});
		variables.fixtures.token = $makeFixture({strategy: "token"});
		variables.fixtures.jwt = $makeFixture({strategy: "jwt"});

		// Module-level dispatch fixture
		variables.dispatchRoot = testHelper.scaffoldTempProject(expandPath("/"));
		directoryCreate(variables.dispatchRoot & "/vendor/wheels", true, true);
		variables.mod = new cli.lucli.Module(cwd = variables.dispatchRoot);
	}

	function afterAll() {
		for (var key in variables.fixtures) {
			testHelper.cleanupTempProject(variables.fixtures[key].root);
		}
		testHelper.cleanupTempProject(variables.dispatchRoot);
	}

	// ── Fixture helpers ─────────────────────────────────────────

	private struct function $makeFixture(required struct options) {
		var root = testHelper.scaffoldTempProject(expandPath("/"));
		var scaffold = $newScaffold(root);
		var args = duplicate(arguments.options);
		args.cliVersion = "test-version";
		var result = scaffold.generateAuth(argumentCollection = args);
		return {root: root, scaffold: scaffold, result: result};
	}

	private any function $newScaffold(required string root) {
		var templates = new cli.lucli.services.Templates(
			helpers = variables.helpers,
			projectRoot = arguments.root,
			moduleRoot = variables.moduleRoot
		);
		var codegen = new cli.lucli.services.CodeGen(
			templateService = templates,
			helpers = variables.helpers,
			projectRoot = arguments.root
		);
		return new cli.lucli.services.Scaffold(
			codeGenService = codegen,
			helpers = variables.helpers,
			projectRoot = arguments.root,
			moduleRoot = variables.moduleRoot
		);
	}

	/**
	 * Strip CFML line, block, and tag comments so content assertions never
	 * match commented-out code (anti-pattern ##14).
	 */
	private string function $stripComments(required string source) {
		var result = arguments.source;
		result = reReplace(result, "<!---[\s\S]*?--->", "", "all");
		result = reReplace(result, "/\*[\s\S]*?\*/", "", "all");
		result = reReplace(result, "//[^\r\n]*", "", "all");
		return result;
	}

	private string function $strippedFile(required string path) {
		return $stripComments(fileRead(arguments.path));
	}

	private numeric function $countOccurrences(required string haystack, required string needle) {
		if (!len(arguments.needle)) return 0;
		return (len(arguments.haystack) - len(replace(arguments.haystack, arguments.needle, "", "all"))) / len(arguments.needle);
	}

	function run() {

		describe("generateAuth() — session strategy (default)", () => {

			it("succeeds and reports generated files", () => {
				expect(fixtures.session.result.success).toBeTrue();
				expect(arrayLen(fixtures.session.result.generated)).toBeGTE(10);
			});

			it("emits the full session file set", () => {
				var root = fixtures.session.root;
				expect(fileExists(root & "/app/models/User.cfc")).toBeTrue();
				expect(fileExists(root & "/app/controllers/Sessions.cfc")).toBeTrue();
				expect(fileExists(root & "/app/controllers/Passwords.cfc")).toBeTrue();
				expect(fileExists(root & "/app/controllers/Registrations.cfc")).toBeTrue();
				expect(fileExists(root & "/app/views/sessions/new.cfm")).toBeTrue();
				expect(fileExists(root & "/app/views/registrations/new.cfm")).toBeTrue();
				expect(fileExists(root & "/app/views/passwords/new.cfm")).toBeTrue();
				expect(fileExists(root & "/app/views/passwords/edit.cfm")).toBeTrue();
				expect(fileExists(root & "/tests/specs/models/UserAuthSpec.cfc")).toBeTrue();
				expect(fileExists(root & "/tests/specs/controllers/SessionsControllerSpec.cfc")).toBeTrue();
				expect(fileExists(root & "/config/services.cfm")).toBeTrue();
			});

			it("emits a create-users migration with digest columns, unique email index, and no api token column", () => {
				var files = directoryList(fixtures.session.root & "/app/migrator/migrations", false, "name", "*_create_users_table.cfc");
				expect(arrayLen(files)).toBe(1);
				var content = fileRead(fixtures.session.root & "/app/migrator/migrations/" & files[1]);
				expect(content).toInclude('t.string(columnNames="email"');
				expect(content).toInclude('t.string(columnNames="passwordDigest"');
				expect(content).toInclude('t.string(columnNames="resetTokenDigest"');
				expect(content).toInclude('t.datetime(columnNames="resetTokenExpiresAt"');
				expect(content).toInclude("t.timestamps();");
				expect(content).toInclude('addIndex(table="users", columnNames="email", unique=true)');
				expect(content).notToInclude("apiTokenDigest");
			});

			it("injects the marked auth route block before the wildcard route", () => {
				var content = fileRead(fixtures.session.root & "/config/routes.cfm");
				expect(content).toInclude("wheels:generate-auth:routes:begin");
				expect(content).toInclude("wheels:generate-auth:routes:end");
				expect(content).toInclude('.get(name="login"');
				expect(content).toInclude('.delete(name="logout"');
				expect(content).toInclude('.resources(name="passwords", only="new,create,edit,update")');
				expect(content).toInclude('.get(name="register"');
				expect(find("wheels:generate-auth:routes:begin", content)).toBeLT(find(".wildcard()", content));
			});

			it("wires passwordHasher, authenticator, and sessionStrategy singletons in config/services.cfm", () => {
				var content = fileRead(fixtures.session.root & "/config/services.cfm");
				expect(content).toInclude("wheels:generate-auth:services:begin");
				expect(content).toInclude('map("passwordHasher").to("wheels.auth.PasswordHasher").asSingleton()');
				expect(content).toInclude('map("authenticator").to("wheels.auth.Authenticator").asSingleton()');
				expect(content).toInclude('map("sessionStrategy").to("wheels.auth.SessionStrategy").asSingleton()');
			});

			it("registers the session strategy in app/events/onapplicationstart.cfm", () => {
				var content = fileRead(fixtures.session.root & "/app/events/onapplicationstart.cfm");
				expect(content).toInclude("wheels:generate-auth:strategy:begin");
				expect(content).toInclude('registerStrategy(name="session"');
			});

			it("calls super.config() first in every generated controller (##2960)", () => {
				for (var name in ["Sessions", "Passwords", "Registrations"]) {
					var stripped = $strippedFile(fixtures.session.root & "/app/controllers/" & name & ".cfc");
					expect(reFind("function config\(\)\s*\{\s*super\.config\(\);", stripped)).toBeGT(
						0,
						name & ".cfc must call super.config() as the first statement of config()"
					);
				}
			});

			it("hashes via the passwordHasher service and scrubs the transient password in the model", () => {
				var stripped = $strippedFile(fixtures.session.root & "/app/models/User.cfc");
				expect(stripped).toInclude('beforeSave("hashPasswordProperty")');
				expect(stripped).toInclude('service("passwordHasher")');
				expect(stripped).toInclude("function authenticate(");
				expect(stripped).toInclude("needsRehash");
				expect(stripped).toInclude('protectedProperties(');
			});

			it("disables the automatic NOT-NULL presence validation on passwordDigest", () => {
				// passwordDigest is only populated by the beforeSave callback,
				// which runs AFTER validation — Wheels' automatic presence
				// validation for the allowNull=false column would otherwise
				// reject every new record ("Password Digest can't be empty").
				// Verified live: seeding/registration failed until this line
				// was added (runtime verification on PR ##3291).
				for (var key in ["session", "token", "jwt"]) {
					var stripped = $strippedFile(fixtures[key].root & "/app/models/User.cfc");
					expect(stripped).toInclude('property(name="passwordDigest", automaticValidations=false)');
				}
			});

			it("uses the injection-safe query builder rather than interpolated where strings", () => {
				var stripped = $strippedFile(fixtures.session.root & "/app/controllers/Sessions.cfc");
				expect(stripped).toInclude('.where("email", email)');
				expect(reFindNoCase("where\s*=\s*""[^""]*##", stripped)).toBe(0);
			});

			it("stamps every generated CFC with the code-you-own header", () => {
				for (var rel in ["app/models/User.cfc", "app/controllers/Sessions.cfc", "app/controllers/Passwords.cfc"]) {
					var content = fileRead(fixtures.session.root & "/" & rel);
					expect(content).toInclude("wheels generate auth");
					expect(content).toInclude("--force");
					expect(content).toInclude("test-version");
				}
			});

			it("uses startFormTag-based forms with cfoutput in every view", () => {
				// chr(60)-concat keeps a literal tag out of this source file —
				// Lucee's tag scanner crashes the whole bundle otherwise.
				var openingOutputTag = chr(60) & "cfoutput" & chr(62);
				for (var rel in ["app/views/sessions/new.cfm", "app/views/registrations/new.cfm", "app/views/passwords/new.cfm", "app/views/passwords/edit.cfm"]) {
					var content = fileRead(fixtures.session.root & "/" & rel);
					expect(content).toInclude("startFormTag(");
					expect(content).toInclude("endFormTag()");
					expect(content).toInclude(openingOutputTag);
				}
			});

			it("never passes an inline closure as a constructor named argument (Cross-Engine Invariant 5)", () => {
				var bootstrap = $stripComments(fileRead(fixtures.session.root & "/app/events/onapplicationstart.cfm"));
				expect(reFindNoCase("new\s+wheels\.auth\.[A-Za-z]+\([^)]*=\s*function", bootstrap)).toBe(0);
			});

			it("rejects a blank password on reset instead of burning the token (Passwords##update)", () => {
				var stripped = $strippedFile(fixtures.session.root & "/app/controllers/Passwords.cfc");
				// Presence is only validated onCreate and the hash callback
				// skips blanks — without this guard a blank submit clears the
				// token, reports success, and keeps the old password valid.
				expect(stripped).toInclude('addError(property="password"');
				var guardPos = find('addError(property="password"', stripped);
				var burnPos = find('resetTokenDigest = ""', stripped);
				expect(guardPos).toBeGT(0);
				expect(burnPos).toBeGT(0);
				expect(guardPos).toBeLT(burnPos, "the blank-password guard must run before the token is cleared");
			});

			it("equalizes login timing with a dummy derivation when the email is unknown", () => {
				var stripped = $strippedFile(fixtures.session.root & "/app/controllers/Sessions.cfc");
				expect(stripped).toInclude('service("passwordHasher").hash(');
			});

			it("emits a controller spec that calls processAction() with no positional action argument", () => {
				var stripped = $strippedFile(fixtures.session.root & "/tests/specs/controllers/SessionsControllerSpec.cfc");
				// processAction()'s only parameter is includeFilters — a
				// positional "create" would silently disable before-filters.
				expect(stripped).toInclude("processAction()");
				expect(stripped).notToInclude('processAction("');
			});

		});

		describe("generateAuth() — bootstrap uses local.-scoped variables, never template-level var (##3063)", () => {

			// app/events/onapplicationstart.cfm is $include()d from a framework
			// function; Adobe CF rejects top-level `var` in an included template
			// at COMPILE time, turning every request into an HTTP 500. `var`
			// inside the hoisted closure body is fine and stays.
			it("session bootstrap", () => {
				var bootstrap = $stripComments(fileRead(fixtures.session.root & "/app/events/onapplicationstart.cfm"));
				expect(bootstrap).toInclude("local.auth = ");
				expect(bootstrap).notToInclude("var auth");
			});

			it("token bootstrap", () => {
				var bootstrap = $stripComments(fileRead(fixtures.token.root & "/app/events/onapplicationstart.cfm"));
				expect(bootstrap).toInclude("local.auth = ");
				expect(bootstrap).toInclude("local.tokenValidator = ");
				expect(bootstrap).notToInclude("var auth");
				expect(bootstrap).notToInclude("var tokenValidator");
			});

			it("jwt bootstrap", () => {
				var bootstrap = $stripComments(fileRead(fixtures.jwt.root & "/app/events/onapplicationstart.cfm"));
				expect(bootstrap).toInclude("local.auth = ");
				expect(bootstrap).toInclude("local.jwtSecret = ");
				expect(bootstrap).toInclude("local.jwtService = ");
				expect(bootstrap).notToInclude("var auth");
				expect(bootstrap).notToInclude("var jwtSecret");
				expect(bootstrap).notToInclude("var jwtService");
			});

		});

		describe("generateAuth() — --no-registration", () => {

			it("omits the Registrations controller, its view, and its routes", () => {
				var root = fixtures.noReg.root;
				expect(fixtures.noReg.result.success).toBeTrue();
				expect(fileExists(root & "/app/controllers/Registrations.cfc")).toBeFalse();
				expect(fileExists(root & "/app/views/registrations/new.cfm")).toBeFalse();
				var routes = fileRead(root & "/config/routes.cfm");
				expect(routes).notToInclude('to="registrations');
				expect(routes).notToInclude('.get(name="register"');
				expect(routes).toInclude('.get(name="login"');
			});

			it("omits the sign-up link from the login view", () => {
				var content = fileRead(fixtures.noReg.root & "/app/views/sessions/new.cfm");
				expect(content).notToInclude('route="register"');
			});

		});

		describe("generateAuth() — token strategy", () => {

			it("emits an API sessions controller and no browser views or registrations", () => {
				var root = fixtures.token.root;
				expect(fixtures.token.result.success).toBeTrue();
				expect(fileExists(root & "/app/controllers/api/Sessions.cfc")).toBeTrue();
				expect(fileExists(root & "/app/controllers/Sessions.cfc")).toBeFalse();
				expect(fileExists(root & "/app/controllers/Registrations.cfc")).toBeFalse();
				expect(fileExists(root & "/app/views/sessions/new.cfm")).toBeFalse();
				expect(fileExists(root & "/tests/specs/controllers/ApiSessionsControllerSpec.cfc")).toBeTrue();
			});

			it("adds the apiTokenDigest column to the migration", () => {
				var files = directoryList(fixtures.token.root & "/app/migrator/migrations", false, "name", "*_create_users_table.cfc");
				expect(arrayLen(files)).toBe(1);
				var content = fileRead(fixtures.token.root & "/app/migrator/migrations/" & files[1]);
				expect(content).toInclude('t.string(columnNames="apiTokenDigest"');
			});

			it("stores only the SHA-256 digest and returns the plaintext token once", () => {
				var model = $strippedFile(fixtures.token.root & "/app/models/User.cfc");
				expect(model).toInclude("function generateApiToken(");
				expect(model).toInclude('Hash(token, "SHA-256")');
				var controller = $strippedFile(fixtures.token.root & "/app/controllers/api/Sessions.cfc");
				expect(reFind("function config\(\)\s*\{\s*super\.config\(\);", controller)).toBeGT(0);
				expect(controller).toInclude("renderWith(");
			});

			it("hoists the token validator instead of inlining a closure into the constructor", () => {
				var bootstrap = $stripComments(fileRead(fixtures.token.root & "/app/events/onapplicationstart.cfm"));
				expect(bootstrap).toInclude("local.tokenValidator = function");
				expect(bootstrap).toInclude("TokenStrategy(validator=local.tokenValidator)");
				expect(reFindNoCase("TokenStrategy\(\s*validator\s*=\s*function", bootstrap)).toBe(0);
			});

			it("equalizes login timing with a dummy derivation when the email is unknown", () => {
				var stripped = $strippedFile(fixtures.token.root & "/app/controllers/api/Sessions.cfc");
				expect(stripped).toInclude('service("passwordHasher").hash(');
			});

			it("hands the Authorization header to the authenticator explicitly on revoke", () => {
				// request.cgi is allowlisted (Global.cfc $cgiScope) and omits
				// http_authorization — passing the raw request scope would 401
				// every revoke.
				var stripped = $strippedFile(fixtures.token.root & "/app/controllers/api/Sessions.cfc");
				expect(stripped).toInclude("GetHttpRequestData");
				expect(stripped).toInclude("http_authorization");
				expect(stripped).notToInclude(".authenticate(request)");
			});

			it("injects api-namespaced session routes", () => {
				var routes = fileRead(fixtures.token.root & "/config/routes.cfm");
				expect(routes).toInclude('.namespace("api")');
				expect(routes).toInclude("wheels:generate-auth:routes:begin");
			});

			it("extends the app base controller by full mapping path (namespaced controller)", () => {
				// app/controllers/api/Sessions.cfc lives in a subfolder — a bare
				// extends="Controller" cannot resolve from there and fails to
				// compile at request time (verified live on PR ##3291). Matches
				// the admin generator's namespaced-controller convention.
				var stripped = $strippedFile(fixtures.token.root & "/app/controllers/api/Sessions.cfc");
				expect(stripped).toInclude('extends="app.controllers.Controller"');
			});

			it("notes that the registration flag does not apply", () => {
				var notes = arrayToList(fixtures.token.result.skipped, "|");
				expect(notes).toInclude("registration");
			});

		});

		describe("generateAuth() — jwt strategy", () => {

			it("emits an API sessions controller that mints JWTs via JwtService", () => {
				var root = fixtures.jwt.root;
				expect(fixtures.jwt.result.success).toBeTrue();
				expect(fileExists(root & "/app/controllers/api/Sessions.cfc")).toBeTrue();
				var controller = $strippedFile(root & "/app/controllers/api/Sessions.cfc");
				expect(controller).toInclude("wheels.auth.JwtService");
				expect(controller).toInclude("WHEELS_JWT_SECRET");
				expect(reFind("function config\(\)\s*\{\s*super\.config\(\);", controller)).toBeGT(0);
			});

			it("fails loudly at startup when WHEELS_JWT_SECRET is missing or short", () => {
				var bootstrap = $stripComments(fileRead(fixtures.jwt.root & "/app/events/onapplicationstart.cfm"));
				expect(bootstrap).toInclude("WHEELS_JWT_SECRET");
				expect(bootstrap).toInclude("throw(");
			});

			it("documents that JWTs have no server-side revocation", () => {
				var content = fileRead(fixtures.jwt.root & "/app/controllers/api/Sessions.cfc");
				expect(content).toInclude("revocation");
			});

			it("does not add the apiTokenDigest column", () => {
				var files = directoryList(fixtures.jwt.root & "/app/migrator/migrations", false, "name", "*_create_users_table.cfc");
				var content = fileRead(fixtures.jwt.root & "/app/migrator/migrations/" & files[1]);
				expect(content).notToInclude("apiTokenDigest");
			});

			it("equalizes login timing with a dummy derivation when the email is unknown", () => {
				var stripped = $strippedFile(fixtures.jwt.root & "/app/controllers/api/Sessions.cfc");
				expect(stripped).toInclude('service("passwordHasher").hash(');
			});

			it("extends the app base controller by full mapping path (namespaced controller)", () => {
				var stripped = $strippedFile(fixtures.jwt.root & "/app/controllers/api/Sessions.cfc");
				expect(stripped).toInclude('extends="app.controllers.Controller"');
			});

		});

		describe("generateAuth() — force and idempotency", () => {

			it("refuses to overwrite existing files without --force", () => {
				var root = fixtures.session.root;
				var before = fileRead(root & "/app/models/User.cfc");
				var result = fixtures.session.scaffold.generateAuth(cliVersion = "second-run");
				expect(arrayLen(result.skipped)).toBeGTE(1);
				expect(fileRead(root & "/app/models/User.cfc")).toBe(before);
				expect(fileRead(root & "/app/models/User.cfc")).notToInclude("second-run");
			});

			it("re-running without --force does not duplicate the route, service, or strategy blocks", () => {
				var root = fixtures.session.root;
				expect($countOccurrences(fileRead(root & "/config/routes.cfm"), "wheels:generate-auth:routes:begin")).toBe(1);
				expect($countOccurrences(fileRead(root & "/config/services.cfm"), "wheels:generate-auth:services:begin")).toBe(1);
				expect($countOccurrences(fileRead(root & "/app/events/onapplicationstart.cfm"), "wheels:generate-auth:strategy:begin")).toBe(1);
			});

			it("--force overwrites files and replaces the injected blocks exactly once", () => {
				var root = fixtures.session.root;
				var result = fixtures.session.scaffold.generateAuth(force = true, cliVersion = "forced-run");
				expect(result.success).toBeTrue();
				expect(fileRead(root & "/app/models/User.cfc")).toInclude("forced-run");
				expect($countOccurrences(fileRead(root & "/config/routes.cfm"), "wheels:generate-auth:routes:begin")).toBe(1);
				expect($countOccurrences(fileRead(root & "/config/services.cfm"), "wheels:generate-auth:services:begin")).toBe(1);
				expect($countOccurrences(fileRead(root & "/app/events/onapplicationstart.cfm"), "wheels:generate-auth:strategy:begin")).toBe(1);
			});

			it("rejects an unknown strategy", () => {
				expect(() => {
					fixtures.session.scaffold.generateAuth(strategy = "basic");
				}).toThrow();
			});

		});

		describe("generateAuth() — routes anchor handling", () => {

			it("falls back to the first uncommented .root( when the CLI-Appends-Here marker is missing", () => {
				var root = testHelper.scaffoldTempProject(expandPath("/"));
				try {
					var routesPath = root & "/config/routes.cfm";
					var nl = chr(10);
					// No marker; a commented-out .root( example above the real one,
					// mirroring the stock app template.
					fileWrite(
						routesPath,
						"// routes" & nl
							& "mapper()" & nl
							& chr(9) & "// .root(to = ""home####index"", method = ""get"")" & nl
							& chr(9) & ".wildcard()" & nl
							& chr(9) & ".root(method = ""get"")" & nl
							& chr(9) & ".end();" & nl
					);
					var result = $newScaffold(root).generateAuth(cliVersion = "test-version");
					expect(result.success).toBeTrue();
					var written = fileRead(routesPath);
					expect(written).toInclude("wheels:generate-auth:routes:begin");
					// $findCodePosition skips the commented-out .root( example and
					// anchors on the real one.
					expect(find("wheels:generate-auth:routes:begin", written)).toBeLT(find('.root(method = "get")', written));
				} finally {
					testHelper.cleanupTempProject(root);
				}
			});

			it("skips with a manual-insert note instead of injecting dead routes when no anchor exists", () => {
				var root = testHelper.scaffoldTempProject(expandPath("/"));
				try {
					var routesPath = root & "/config/routes.cfm";
					// Hand-edited file: no CLI-Appends-Here and the only .root( is
					// commented out. An .end() fallback would have parked the auth
					// routes after .wildcard(), where they could never match
					// (anti-pattern ##6) — refusing is the only safe move.
					var scriptOpen = chr(60) & "cfscript" & chr(62);
					var scriptClose = chr(60) & "/cfscript" & chr(62);
					var nl = chr(10);
					fileWrite(
						routesPath,
						scriptOpen & nl
							& "mapper()" & nl
							& chr(9) & "// .root(to = ""home####index"", method = ""get"")" & nl
							& chr(9) & ".wildcard()" & nl
							& chr(9) & ".end();" & nl
							& scriptClose & nl
					);
					var result = $newScaffold(root).generateAuth(cliVersion = "test-version");
					expect(result.success).toBeTrue();
					expect(fileRead(routesPath)).notToInclude("wheels:generate-auth:routes:begin");
					expect(arrayToList(result.skipped, "|")).toInclude("add this block manually");
				} finally {
					testHelper.cleanupTempProject(root);
				}
			});

			it("refuses to regenerate a block whose begin marker has no matching end marker", () => {
				var root = testHelper.scaffoldTempProject(expandPath("/"));
				try {
					var scaffold = $newScaffold(root);
					expect(scaffold.generateAuth(cliVersion = "test-version").success).toBeTrue();
					var routesPath = root & "/config/routes.cfm";
					fileWrite(routesPath, replace(fileRead(routesPath), "// wheels:generate-auth:routes:end", ""));
					var second = scaffold.generateAuth(force = true, cliVersion = "second-run");
					expect(arrayToList(second.skipped, "|")).toInclude("begin marker without matching end marker");
					// The corrupted block is left untouched for the user to fix.
					expect($countOccurrences(fileRead(routesPath), "wheels:generate-auth:routes:begin")).toBe(1);
				} finally {
					testHelper.cleanupTempProject(root);
				}
			});

		});

		describe("generateAuth() — custom model name", () => {

			it("respects --model for file names, table name, and route wiring", () => {
				var root = testHelper.scaffoldTempProject(expandPath("/"));
				try {
					var scaffold = $newScaffold(root);
					var result = scaffold.generateAuth(model = "Member", cliVersion = "test-version");
					expect(result.success).toBeTrue();
					expect(fileExists(root & "/app/models/Member.cfc")).toBeTrue();
					var files = directoryList(root & "/app/migrator/migrations", false, "name", "*_create_members_table.cfc");
					expect(arrayLen(files)).toBe(1);
					var sessions = fileRead(root & "/app/controllers/Sessions.cfc");
					expect(sessions).toInclude('model("Member")');
				} finally {
					testHelper.cleanupTempProject(root);
				}
			});

		});

		describe("wheels generate auth — Module dispatch", () => {

			it("reaches generateAuth from the generate() switch and writes the scaffold", () => {
				// arg1= exercises the structured callerArgs dispatch path — the
				// same handoff LuCLI produces for `wheels generate auth`.
				mod.generate(arg1 = "auth");
				expect(fileExists(variables.dispatchRoot & "/app/controllers/Sessions.cfc")).toBeTrue();
				expect(fileExists(variables.dispatchRoot & "/app/models/User.cfc")).toBeTrue();
			});

			it("throws Wheels.InvalidArguments for an unknown strategy", () => {
				expect(() => {
					mod.generate(arg1 = "auth", strategy = "basic");
				}).toThrow(type = "Wheels.InvalidArguments");
			});

		});

	}

}
