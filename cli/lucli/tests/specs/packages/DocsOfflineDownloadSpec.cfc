component extends="wheels.wheelstest.system.BaseSpec" {

	function beforeAll() {
		variables.testHelper = new cli.lucli.tests.TestHelper();
		variables.tempRoot = testHelper.scaffoldTempProject(expandPath("/"));
		variables.version = "9.9.9";
		directoryCreate(tempRoot & "/vendor/wheels", true, true);
		fileWrite(tempRoot & "/vendor/wheels/wheels.json", serializeJSON({version: variables.version}));
		variables.workDir = getTempDirectory() & "docs-offline-spec-" & createUUID();
		directoryCreate(workDir, true);
	}

	function afterAll() {
		if (directoryExists(variables.workDir)) directoryDelete(variables.workDir, true);
		testHelper.cleanupTempProject(variables.tempRoot);
	}

	private any function fetchModule(required any stub, required string home) {
		var mod = new cli.lucli.Module(cwd = variables.tempRoot);
		prepareMock(mod);
		mod.$("$resolveLucliHome", arguments.home);
		mod.$("$docsBundleUrl", "http://127.0.0.1:#arguments.stub.getPort()#/wheels-docs-#variables.version#.zip");
		mod.$("$docsMountIntoWebroot");
		return mod;
	}

	private struct function runDocs(required any mod, required array argv) {
		var state = {type: "", message: ""};
		arguments.mod.__arguments = arguments.argv;
		try {
			arguments.mod.docs();
		} catch (any e) {
			state.type = e.type;
			state.message = e.message;
		}
		return state;
	}

	function run() {
		describe("wheels docs fetch offline", () => {
			it("refuses the checksum request before any network access", () => {
				var home = variables.workDir & "/home-" & createUUID();
				directoryCreate(home & "/docs", true, true);
				var stub = new cli.lucli.tests.StubHttpServer(statusCode = 404, bindAddress = "127.0.0.1");
				var mod = fetchModule(stub, home);
				var state = {type: "", message: ""};
				var requests = [];
				StructDelete(request, "$wheelsOffline");

				try {
					state = runDocs(mod, ["fetch", "--force", "--offline"]);
					requests = stub.requests();
				} finally {
					stub.stop();
					StructDelete(request, "$wheelsOffline");
				}

				expect(state.type).toBe("Wheels.DocsFetchFailed");
				expect(state.message).toInclude("Offline mode is enabled");
				expect(arrayLen(requests)).toBe(0);
				expect(directoryExists(home & "/docs/" & variables.version)).toBeFalse();
			});
		});
	}
}
