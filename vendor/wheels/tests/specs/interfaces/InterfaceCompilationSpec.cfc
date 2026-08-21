component extends="wheels.WheelsTest" {

	function run() {

		describe("Interface Compilation", () => {

			it("compiles all interface CFCs without errors", () => {
				var interfaceDir = expandPath("/wheels/interfaces");
				var files = directoryList(
					path=interfaceDir,
					recurse=true,
					filter="*.cfc",
					type="file"
				);

				expect(arrayLen(files)).toBeGT(0, "No interface files found");

				for (var filePath in files) {
					// Convert file path to dot-notation component path
					var relativePath = replaceNoCase(filePath, interfaceDir, "");
					relativePath = replace(relativePath, ".cfc", "");
					relativePath = replace(relativePath, "/", ".", "all");
					relativePath = replace(relativePath, "\", ".", "all");
					if (left(relativePath, 1) == ".") {
						relativePath = mid(relativePath, 2, len(relativePath));
					}
					var componentPath = "wheels.interfaces." & relativePath;

					expect(function() {
						getComponentMetaData(componentPath);
					}).notToThrow("Interface should compile cleanly: #componentPath#");
				}
			});

			it("finds exactly 24 interface files", () => {
				var interfaceDir = expandPath("/wheels/interfaces");
				var files = directoryList(
					path=interfaceDir,
					recurse=true,
					filter="*.cfc",
					type="file"
				);
				// Bump when a wheels.interfaces.* contract is added or removed.
				expect(arrayLen(files)).toBe(24);
			});

			it("re-export wrappers extend their original interfaces", () => {
				var wrappers = [
					"wheels.interfaces.MiddlewareInterface",
					"wheels.interfaces.ServiceProviderInterface",
					"wheels.interfaces.AuthenticatorInterface",
					"wheels.interfaces.AuthStrategy"
				];

				for (var wrapper in wrappers) {
					var meta = getComponentMetaData(wrapper);
					// Verify the wrapper has extends metadata — the exact structure
					// varies across engines (Lucee, Adobe, BoxLang), so we only
					// check that extends is present and non-empty.
					expect(meta).toHaveKey("extends", "#wrapper# should have extends metadata");
					expect(isStruct(meta.extends) && !structIsEmpty(meta.extends)).toBeTrue(
						"#wrapper# extends metadata should be a non-empty struct"
					);
				}
			});

		});

	}

}
