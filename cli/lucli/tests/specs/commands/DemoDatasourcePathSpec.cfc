/**
 * The demo app's H2 datasource must live under THIS checkout's root (#3689).
 *
 * A relative `jdbc:h2:file:./db/h2/wheels-dev` resolves against the server
 * process's working directory, which for a LuCLI server is the Lucee Express
 * install. Every demo-app server on the machine, from any checkout or
 * worktree, then opened the same H2 file: cross-checkout data sharing plus an
 * exclusive-lock collision that made DbCommandsSpec flake whenever a second
 * server was up.
 */
component extends="wheels.wheelstest.system.BaseSpec" {

	function run() {

		describe("demo app H2 datasource path (##3689)", () => {

			it("anchors the wheels-dev H2 file to this checkout's root, not the process cwd", () => {
				var datasources = getApplicationMetadata().datasources ?: {};
				expect(datasources).toHaveKey("wheels-dev");
				var ds = datasources["wheels-dev"];
				var connection = ds.connectionString ?: (ds.url ?: "");
				expect(connection).toInclude("jdbc:h2:file:");

				var filePath = replace(listFirst(replaceNoCase(connection, "jdbc:h2:file:", ""), ";"), "\", "/", "all");
				// expandPath("/") is the webroot (public/); the app root is its parent.
				var webroot = createObject("java", "java.io.File").init(expandPath("/"));
				var appRoot = replace(webroot.getCanonicalFile().getParent(), "\", "/", "all") & "/";
				expect(left(filePath, 2)).notToBe("./", "the H2 path is relative: #filePath#");
				expect(filePath).toInclude(appRoot, "the H2 file #filePath# is not under this checkout (#appRoot#)");
				expect(filePath).toInclude("db/h2/wheels-dev");
			});

		});

	}

}
