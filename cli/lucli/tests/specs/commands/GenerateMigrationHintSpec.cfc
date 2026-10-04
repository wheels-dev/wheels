/**
 * `wheels generate migration AddUserIdToArticles` writes a blank up()/down()
 * whatever the name says (the guides call it a blank migration), but its own
 * usage example was `AddEmailToUsers`, which reads as if the column were
 * inferred. A column-change name now gets a next step: `generate property`
 * for an add (it writes the addColumn), the removeColumn() call for a remove.
 */
component extends="wheels.wheelstest.system.BaseSpec" {

	function beforeAll() {
		variables.testHelper = new cli.lucli.tests.TestHelper();
		variables.tempRoot = testHelper.scaffoldTempProject(expandPath("/"));
	}

	function afterAll() {
		testHelper.cleanupTempProject(variables.tempRoot);
	}

	function run() {

		describe("wheels generate migration: column-change names", () => {

			it("points an AddXToY name at generate property", () => {
				var hint = $module().$migrationNameHint("AddUserIdToArticles");
				expect(hint).toInclude("doesn't read columns from its name");
				expect(hint).toInclude("wheels generate property Article userId:string");
			});

			it("reads the snake_case form too", () => {
				expect($module().$migrationNameHint("add_email_to_users")).toInclude("wheels generate property User email:string");
			});

			it("keeps each word of a multi-word table in the model name", () => {
				var m = $module();
				expect(m.$migrationNameHint("AddEmailToBlogPosts")).toInclude("wheels generate property BlogPost email:string");
				expect(m.$migrationNameHint("add_email_to_blog_posts")).toInclude("wheels generate property BlogPost email:string");
			});

			it("shows the removeColumn() call for a RemoveXFromY name", () => {
				var hint = $module().$migrationNameHint("RemoveLegacyFlagFromAccounts");
				expect(hint).toInclude('removeColumn(table="accounts", columnName="legacyFlag");');
				expect(hint).notToInclude("generate property");
			});

			it("says nothing for any other name", () => {
				var m = $module();
				expect(m.$migrationNameHint("BackfillUserSlugs")).toBe("");
				expect(m.$migrationNameHint("CreatePosts")).toBe("");
				expect(m.$migrationNameHint("Addresses")).toBe("");
				expect(m.$migrationNameHint("AddIndexes")).toBe("");
			});

			it("prints the hint after creating the migration", () => {
				var m = $module();
				m.generate(arg1 = "migration", arg2 = "AddEmailToUsers");
				var said = "";
				for (var call in m.$callLog().out) {
					said &= call[1] & chr(10);
				}
				expect(said).toInclude("wheels generate property User email:string");
				var files = directoryList(variables.tempRoot & "/app/migrator/migrations", false, "name", "*_AddEmailToUsers.cfc");
				expect(arrayLen(files)).toBe(1);
			});

		});

	}

	private any function $module() {
		var m = new cli.lucli.Module(cwd = variables.tempRoot);
		prepareMock(m);
		m.$("out");
		return m;
	}

}
