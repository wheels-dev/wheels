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
				expect(bootstrap).toInclude("var tokenValidator = function");
				expect(bootstrap).toInclude("TokenStrategy(validator=tokenValidator)");
				expect(reFindNoCase("TokenStrategy\(\s*validator\s*=\s*function", bootstrap)).toBe(0);
			});

			it("injects api-namespaced session routes", () => {
				var routes = fileRead(fixtures.token.root & "/config/routes.cfm");
				expect(routes).toInclude('.namespace("api")');
				expect(routes).toInclude("wheels:generate-auth:routes:begin");
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
