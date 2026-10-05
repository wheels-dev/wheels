/**
 * A polymorphic association with no `foreignKey` / `foreignType` resolves its columns against the
 * child's schema, like the non-polymorphic defaults do: `<name>id` / `<name>type` when they exist,
 * else `<name>_id` / `<name>_type` (what `t.references(polymorphic = true)` writes with
 * useUnderscoreReferenceColumns). The tables here use the underscore shape and the models pass no
 * column names; the legacy shape is covered by the existing polymorphic specs.
 */
component extends="wheels.WheelsTest" {

	function beforeAll() {
		variables.g = application.wo;
		variables.migration = CreateObject("component", "wheels.migrator.Migration").init();
		variables.tables = ["c_o_r_e_uautonotes", "c_o_r_e_uautoposts", "c_o_r_e_uautopages", "c_o_r_e_ubothnotes"];
		dropTables();
		var t = variables.migration.createTable(name = "c_o_r_e_uautoposts");
		t.string(columnNames = "title");
		t.create();
		t = variables.migration.createTable(name = "c_o_r_e_uautopages");
		t.string(columnNames = "title");
		t.create();
		t = variables.migration.createTable(name = "c_o_r_e_uautonotes");
		t.string(columnNames = "body");
		t.bigInteger(columnNames = "notable_id", allowNull = true);
		t.string(columnNames = "notable_type", allowNull = true);
		t.create();
		// both shapes on one table: the legacy names win
		t = variables.migration.createTable(name = "c_o_r_e_ubothnotes");
		t.bigInteger(columnNames = "notableid", allowNull = true);
		t.string(columnNames = "notabletype", allowNull = true);
		t.bigInteger(columnNames = "notable_id", allowNull = true);
		t.string(columnNames = "notable_type", allowNull = true);
		t.create();
		forgetModels();
	}

	function afterAll() {
		dropTables();
		forgetModels();
	}

	function dropTables() {
		for (var table in variables.tables) {
			try {
				variables.migration.dropTable(table);
			} catch (any e) {
			}
		}
	}

	function forgetModels() {
		for (var m in ["UAutoNote", "UAutoPost", "UAutoPage", "UBothNote", "UGhostOwner", "UMixedNote", "UMixedTypeNote"]) {
			StructDelete(application.wheels.models, m);
		}
	}

	function rawNote(required string body) {
		return QueryExecute(
			"SELECT notable_id, notable_type FROM c_o_r_e_uautonotes WHERE body = :b",
			{b = arguments.body},
			{datasource = variables.g.get("dataSourceName")}
		);
	}

	function insertNote(required string body, required numeric id, required string type) {
		QueryExecute(
			"INSERT INTO c_o_r_e_uautonotes (body, notable_id, notable_type) VALUES (:b, :i, :t)",
			{b = arguments.body, i = {value = arguments.id, cfsqltype = "cf_sql_bigint"}, t = arguments.type},
			{datasource = variables.g.get("dataSourceName")}
		);
	}

	function run() {

		describe("A polymorphic association on an underscore-shaped schema", () => {

			beforeEach(() => {
				for (var table in variables.tables) {
					QueryExecute("DELETE FROM #table#", [], {datasource = variables.g.get("dataSourceName")});
				}
				// a cold start for every spec, so each path resolves the columns itself
				forgetModels();
			});

			it("creates through hasMany and reads back through belongsTo", () => {
				var post = variables.g.model("UAutoPost").create(title = "a post");
				var note = post.createUAutoNote(body = "hello");
				var raw = rawNote("hello");
				expect(raw.notable_type).toBe("UAutoPost");
				expect(raw.notable_id).toBe(post.id);
				expect(variables.g.model("UAutoNote").findByKey(note.id).notable().title).toBe("a post");
			});

			it("filters hasMany reads and counts by the type column", () => {
				var post = variables.g.model("UAutoPost").create(title = "p");
				post.createUAutoNote(body = "on the post");
				variables.g.model("UAutoNote").create(body = "on a page", notable_id = post.id, notable_type = "UAutoPage");
				expect(post.uAutoNotes().recordCount).toBe(1);
				expect(post.uAutoNoteCount()).toBe(1);
			});

			it("filters an include join by the type column, as the association's first use", () => {
				var post = variables.g.model("UAutoPost").create(title = "joined");
				// raw rows, so the include join is the first thing to read the association's columns
				insertNote("mine", post.id, "UAutoPost");
				insertNote("not mine", post.id, "UAutoPage");
				var rows = variables.g.model("UAutoPost").findAll(where = "id = #post.id#", include = "uAutoNotes", returnAs = "query");
				expect(rows.recordCount).toBe(1);
			});

			it("creates and reads through hasOne", () => {
				var page = variables.g.model("UAutoPage").create(title = "a page");
				page.createUAutoNote(body = "page note");
				expect(page.uAutoNote().body).toBe("page note");
				expect(rawNote("page note").notable_type).toBe("UAutoPage");
			});

			it("sets both columns through nested properties, as the association's first use", () => {
				var post = variables.g.model("UAutoPost").new(title = "nested", uAutoNotes = [{body = "via nesting"}]);
				expect(post.save()).toBeTrue();
				var raw = rawNote("via nesting");
				expect(raw.notable_type).toBe("UAutoPost");
				expect(raw.notable_id).toBe(post.id);
			});

			it("resolves only the derived name when the other is passed", () => {
				var mixed = variables.g.model("UMixedNote");
				mixed.$resolvePolymorphicColumns("notable");
				expect(mixed.$classData().associations.notable.foreignKey).toBe("notable_id");
				expect(mixed.$classData().associations.notable.foreignType).toBe("notable_type");
			});

			it("resolves only the derived key when the type is passed", () => {
				var mixed = variables.g.model("UMixedTypeNote");
				mixed.$resolvePolymorphicColumns("notable");
				expect(mixed.$classData().associations.notable.foreignKey).toBe("notable_id");
				expect(mixed.$classData().associations.notable.foreignType).toBe("notable_type");
			});

			it("keeps the legacy names when both shapes exist", () => {
				var both = variables.g.model("UBothNote");
				both.$resolvePolymorphicColumns("notable");
				expect(both.$classData().associations.notable.foreignKey).toBe("notableid");
				expect(both.$classData().associations.notable.foreignType).toBe("notabletype");
			});

			it("keeps the default names when the child's columns can't be read", () => {
				var owner = variables.g.model("UGhostOwner");
				var state = {type = ""};
				try {
					owner.$resolvePolymorphicColumns("ghosts");
				} catch (any e) {
					state.type = e.type;
				}
				expect(state.type).toBe("");
				expect(owner.$classData().associations.ghosts.foreignKey).toBe("hauntedid");
				expect(owner.$classData().associations.ghosts.foreignType).toBe("hauntedtype");
			});

			it("records the resolved columns on every side", () => {
				variables.g.model("UAutoPost").create(title = "warm").createUAutoNote(body = "warm");
				variables.g.model("UAutoNote").findOne().notable();
				var note = variables.g.model("UAutoNote").$classData().associations.notable;
				var post = variables.g.model("UAutoPost").$classData().associations.uAutoNotes;
				expect(note.foreignKey).toBe("notable_id");
				expect(note.foreignType).toBe("notable_type");
				expect(post.foreignKey).toBe("notable_id");
				expect(post.foreignType).toBe("notable_type");
			});

		});

	}

}
