/**
 * Regression: #2888 standardized the deprecated `/wheels/mcp` HTTP transport's
 * doc pointer on the live integration guide
 * (`https://guides.wheels.dev/v4-0-0/command-line-tools/mcp-integration`),
 * but three runtime-visible strings still cite a phantom path that has
 * never existed in the repo:
 *
 *   - vendor/wheels/public/views/mcp.cfm           (deprecation log message)
 *   - vendor/wheels/public/mcp/McpServer.cfc       (CLI-disabled-tool error)
 *   - cli/src/commands/wheels/mcp/setup.cfc        (legacy CommandBox CLI output)
 *
 * The phantom path is `docs/command-line-tools/commands/mcp/mcp-configuration-guide.md`.
 * Issue ##3016.
 */
component extends="wheels.WheelsTest" {

	function run() {

		describe("MCP deprecation pointers cite the live integration guide", () => {

			// expandPath("/wheels") resolves to vendor/wheels via the configured
			// Lucee mapping; the repo root is two levels above.
			var repoRoot = expandPath("/wheels/../..");
			var phantomPath = "docs/command-line-tools/commands/mcp/mcp-configuration-guide.md";
			var canonical = "https://guides.wheels.dev/v4-0-0/command-line-tools/mcp-integration";
			var targets = [
				"vendor/wheels/public/views/mcp.cfm",
				"vendor/wheels/public/mcp/McpServer.cfc",
				"cli/src/commands/wheels/mcp/setup.cfc"
			];

			for (var rel in targets) {
				// Capture the loop variable so the closure body binds the
				// current value, not the final iteration's value.
				(function(relPath) {
					it("references " & canonical & " in " & relPath, () => {
						var absolute = repoRoot & "/" & relPath;
						expect(fileExists(absolute)).toBeTrue("Missing file: " & absolute);

						var content = fileRead(absolute);

						expect(content contains canonical).toBeTrue(
							relPath & " should reference " & canonical
							& " — the URL ##2888 standardized on for the deprecated /wheels/mcp transport."
						);

						expect(content contains phantomPath).toBeFalse(
							relPath & " still references the phantom path " & phantomPath
							& " that has never existed in the repo."
						);
					});
				})(rel);
			}

		});

	}

}
