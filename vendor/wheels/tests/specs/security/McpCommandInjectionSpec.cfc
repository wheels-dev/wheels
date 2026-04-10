component extends="wheels.WheelsTest" {

	function run() {

		describe("MCP command execution allowlist", () => {

			var allowedSubcommands = "g,generate,test,server,dbmigrate,db:seed,jobs,reload,info,new,init,deps";
			var metacharRegex = "[;\|&\$`\(\)\{\}<>\n\r'""\\!\*\?\[\]\^%]";

			describe("subcommand allowlist", () => {

				it("accepts valid subcommand 'generate'", () => {
					expect(ListFindNoCase(allowedSubcommands, "generate") > 0).toBeTrue();
				});

				it("accepts valid subcommand 'g'", () => {
					expect(ListFindNoCase(allowedSubcommands, "g") > 0).toBeTrue();
				});

				it("accepts valid subcommand 'test'", () => {
					expect(ListFindNoCase(allowedSubcommands, "test") > 0).toBeTrue();
				});

				it("accepts valid subcommand 'dbmigrate'", () => {
					expect(ListFindNoCase(allowedSubcommands, "dbmigrate") > 0).toBeTrue();
				});

				it("accepts valid subcommand 'db:seed'", () => {
					expect(ListFindNoCase(allowedSubcommands, "db:seed") > 0).toBeTrue();
				});

				it("rejects unknown subcommand 'exec'", () => {
					expect(ListFindNoCase(allowedSubcommands, "exec") > 0).toBeFalse();
				});

				it("rejects unknown subcommand 'sh'", () => {
					expect(ListFindNoCase(allowedSubcommands, "sh") > 0).toBeFalse();
				});

				it("rejects unknown subcommand 'bash'", () => {
					expect(ListFindNoCase(allowedSubcommands, "bash") > 0).toBeFalse();
				});

				it("rejects unknown subcommand 'run'", () => {
					expect(ListFindNoCase(allowedSubcommands, "run") > 0).toBeFalse();
				});

			});

			describe("argument safety via $isSafeArgument pattern", () => {

				it("allows simple alphanumeric arguments", () => {
					expect(reFind(metacharRegex, "model") == 0).toBeTrue();
				});

				it("allows arguments with dots and hyphens", () => {
					expect(reFind(metacharRegex, "User.name") == 0).toBeTrue();
				});

				it("rejects semicolon injection", () => {
					expect(reFind(metacharRegex, "model;rm -rf /") > 0).toBeTrue();
				});

				it("rejects pipe injection", () => {
					expect(reFind(metacharRegex, "model|cat /etc/passwd") > 0).toBeTrue();
				});

				it("rejects ampersand injection", () => {
					expect(reFind(metacharRegex, "model&whoami") > 0).toBeTrue();
				});

				it("rejects backtick injection", () => {
					expect(reFind(metacharRegex, "model`id`") > 0).toBeTrue();
				});

				it("rejects dollar-paren subshell injection", () => {
					expect(reFind(metacharRegex, "model$(whoami)") > 0).toBeTrue();
				});

				it("rejects newline injection", () => {
					expect(reFind(metacharRegex, "model" & chr(10) & "rm -rf /") > 0).toBeTrue();
				});

				it("rejects carriage return injection", () => {
					expect(reFind(metacharRegex, "model" & chr(13) & "evil") > 0).toBeTrue();
				});

			});

			describe("command prefix validation", () => {

				it("requires wheels prefix", () => {
					expect(reFind("^wheels\s", "bash -c evil") > 0).toBeFalse();
				});

				it("accepts wheels prefix", () => {
					expect(reFind("^wheels\s", "wheels test run") > 0).toBeTrue();
				});

				it("rejects empty command", () => {
					expect(len(trim("")) > 0).toBeFalse();
				});

				it("rejects wheels without a subcommand", () => {
					expect(len(trim(mid("wheels ", 7))) > 0).toBeFalse();
				});

			});

			describe("combined structural validation", () => {

				it("validates a full generate command end-to-end", () => {
					var command = "wheels generate model User";

					expect(reFind("^wheels\s", command) > 0).toBeTrue();

					var stripped = trim(mid(command, 7));
					var parts = ListToArray(stripped, " ");
					expect(ListFindNoCase(allowedSubcommands, parts[1]) > 0).toBeTrue();

					var allSafe = true;
					for (var i = 2; i <= ArrayLen(parts); i++) {
						if (reFind(metacharRegex, parts[i]) > 0) {
							allSafe = false;
						}
					}
					expect(allSafe).toBeTrue();
				});

				it("rejects a command with injected subcommand and metacharacters", () => {
					var command = "wheels exec;rm -rf /";

					var stripped = trim(mid(command, 7));
					var parts = ListToArray(stripped, " ");
					var subcommandAllowed = ListFindNoCase(allowedSubcommands, parts[1]) > 0;

					var argsSafe = true;
					for (var i = 2; i <= ArrayLen(parts); i++) {
						if (reFind(metacharRegex, parts[i]) > 0) {
							argsSafe = false;
						}
					}

					expect(subcommandAllowed && argsSafe).toBeFalse();
				});

				it("rejects a valid subcommand with unsafe arguments", () => {
					var command = "wheels test run;whoami";

					var stripped = trim(mid(command, 7));
					var parts = ListToArray(stripped, " ");
					expect(ListFindNoCase(allowedSubcommands, parts[1]) > 0).toBeTrue();

					var argsSafe = true;
					for (var i = 2; i <= ArrayLen(parts); i++) {
						if (reFind(metacharRegex, parts[i]) > 0) {
							argsSafe = false;
						}
					}
					expect(argsSafe).toBeFalse();
				});

			});

		});

	}

}
