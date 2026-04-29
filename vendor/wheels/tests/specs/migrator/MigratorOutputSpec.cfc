component extends="wheels.WheelsTest" {

	function run() {

		describe("Migrator output formatting", () => {

			it("announce() appends CRLF, not bare CR", () => {
				// Regression: Base.cfc::announce() used to append Chr(13) only,
				// which collapsed migrator output onto a single line in macOS
				// and Linux terminals. Tutorial chapter 2's "Run the migration"
				// step displayed mangled output as a result. See finding #3 in
				// docs/superpowers/plans/2026-04-29-fresh-vm-onboarding-findings.md
				request.$wheelsMigrationOutput = "";
				var base = new wheels.migrator.Base();
				base.announce("Created table posts");

				expect(request.$wheelsMigrationOutput).toInclude(Chr(13) & Chr(10));
				// Sanity: the message body should still be present.
				expect(request.$wheelsMigrationOutput).toInclude("Created table posts");
			});

			it("announce() output ends with the LF (\\n) so terminals advance the line", () => {
				request.$wheelsMigrationOutput = "";
				var base = new wheels.migrator.Base();
				base.announce("Migrated up to 20260101000000");

				// The output string ends with CRLF; the LF (Chr(10)) is the
				// part that actually moves the terminal cursor to a new line.
				// Bare CR (Chr(13)) without LF only resets the cursor to
				// column 0, causing the next chunk to overwrite.
				var lastChar = Right(request.$wheelsMigrationOutput, 1);
				expect(Asc(lastChar)).toBe(10);
			});

		});

	}

}
