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

			it("finds exactly 22 interface files", () => {
				var interfaceDir = expandPath("/wheels/interfaces");
				var files = directoryList(
					path=interfaceDir,
					recurse=true,
					filter="*.cfc",
					type="file"
				);
				expect(arrayLen(files)).toBe(22);
			});

			it("re-export wrappers extend their original interfaces", () => {
				var reexports = {
					"wheels.interfaces.MiddlewareInterface": "wheels.middleware.MiddlewareInterface",
					"wheels.interfaces.ServiceProviderInterface": "wheels.ServiceProviderInterface",
					"wheels.interfaces.AuthenticatorInterface": "wheels.auth.AuthenticatorInterface",
					"wheels.interfaces.AuthStrategy": "wheels.auth.AuthStrategy"
				};

				for (var wrapper in reexports) {
					var meta = getComponentMetaData(wrapper);
					expect(meta).toHaveKey("extends", "#wrapper# should have extends metadata");
					expect(meta.extends.name).toBe(
						reexports[wrapper],
						"#wrapper# should extend #reexports[wrapper]#"
					);
				}
			});

		});

	}

}
