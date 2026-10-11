/**
 * Polymorphic associations accept an explicit `foreignType` (the type column) alongside
 * `foreignKey`, so an underscore-shaped schema (`notable_id` / `notable_type`, as
 * `t.references(polymorphic = true)` writes it with useUnderscoreReferenceColumns) works through
 * every path that reads the type column: the belongsTo loader, hasMany / hasOne reads, counts and
 * creates (with the type discriminator), an include join, and nested properties. Without
 * `foreignType`, the default stays `<name>type`.
 */
component extends="wheels.WheelsTest" {

	function beforeAll() {
		variables.g = application.wo;
		variables.migration = CreateObject("component", "wheels.migrator.Migration").init();
		for (var table in ["c_o_r_e_upolynotes", "c_o_r_e_upolyposts", "c_o_r_e_upolypages"]) {
			try {
				variables.migration.dropTable(table);
			} catch (any e) {
			}
		}
		var t = variables.migration.createTable(name = "c_o_r_e_upolyposts");
		t.string(columnNames = "title");
		t.create();
		t = variables.migration.createTable(name = "c_o_r_e_upolypages");
		t.string(columnNames = "title");
		t.create();
		t = variables.migration.createTable(name = "c_o_r_e_upolynotes");
		t.string(columnNames = "body");
		// as wide as the parents' primary keys (64-bit on CockroachDB)
		t.bigInteger(columnNames = "notable_id", allowNull = true);
		t.string(columnNames = "notable_type", allowNull = true);
		t.create();
		for (var m in ["UPolyNote", "UPolyPost", "UPolyPage"]) {
			StructDelete(application.wheels.models, m);
		}
	}

	function afterAll() {
		for (var table in ["c_o_r_e_upolynotes", "c_o_r_e_upolyposts", "c_o_r_e_upolypages"]) {
			try {
				variables.migration.dropTable(table);
			} catch (any e) {
			}
		}
		for (var m in ["UPolyNote", "UPolyPost", "UPolyPage"]) {
			StructDelete(application.wheels.models, m);
		}
	}

	function run() {

		describe("A polymorphic association with an explicit foreignType", () => {

			beforeEach(() => {
				for (var table in ["c_o_r_e_upolynotes", "c_o_r_e_upolyposts", "c_o_r_e_upolypages"]) {
					QueryExecute("DELETE FROM #table#", [], {datasource = variables.g.get("dataSourceName")});
				}
			});

			it("records the type column on the association", () => {
				expect(variables.g.model("UPolyNote").$classData().associations.notable.foreignType).toBe("notable_type");
				expect(variables.g.model("UPolyPost").$classData().associations.uPolyNotes.foreignType).toBe("notable_type");
				expect(variables.g.model("UPolyPage").$classData().associations.uPolyNote.foreignType).toBe("notable_type");
			});

			it("keeps the <name>type default when foreignType isn't given", () => {
				expect(variables.g.model("PolyComment").$classData().associations.commentable.foreignType).toBe("commentabletype");
				expect(variables.g.model("PolyArticle").$classData().associations.polyComments.foreignType).toBe("commentabletype");
			});

			it("creates through hasMany and reads back through belongsTo", () => {
				var post = variables.g.model("UPolyPost").create(title = "a post");
				var note = post.createUPolyNote(body = "hello");
				var raw = QueryExecute("SELECT notable_id, notable_type FROM c_o_r_e_upolynotes WHERE id = :id", {id = {value = note.id, cfsqltype = "cf_sql_bigint"}}, {datasource = variables.g.get("dataSourceName")});
				expect(raw.notable_type).toBe("UPolyPost");
				expect(raw.notable_id).toBe(post.id);
				var owner = variables.g.model("UPolyNote").findByKey(note.id).notable();
				expect(owner.title).toBe("a post");
			});

			it("filters hasMany reads and counts by the type column", () => {
				var post = variables.g.model("UPolyPost").create(title = "p");
				var page = variables.g.model("UPolyPage").create(title = "g");
				post.createUPolyNote(body = "on the post");
				// The only note is the post's, so the page has none, even when the two ids are equal.
				expect(page.hasUPolyNote()).toBeFalse();
				// A note for a page with the post's id must not show up on the post.
				variables.g.model("UPolyNote").create(body = "on a page", notable_id = post.id, notable_type = "UPolyPage");
				expect(post.uPolyNotes().recordCount).toBe(1);
				expect(post.uPolyNoteCount()).toBe(1);
				expect(post.hasUPolyNotes()).toBeTrue();
			});

			it("filters an include join by the type column", () => {
				var post = variables.g.model("UPolyPost").create(title = "joined");
				post.createUPolyNote(body = "mine");
				variables.g.model("UPolyNote").create(body = "not mine", notable_id = post.id, notable_type = "UPolyPage");
				var rows = variables.g.model("UPolyPost").findAll(where = "id = #post.id#", include = "uPolyNotes", returnAs = "query");
				expect(rows.recordCount).toBe(1);
			});

			it("creates and reads through hasOne", () => {
				var page = variables.g.model("UPolyPage").create(title = "a page");
				page.createUPolyNote(body = "page note");
				expect(page.uPolyNote().body).toBe("page note");
				expect(variables.g.model("UPolyNote").findOne(where = "body = 'page note'").notable_type).toBe("UPolyPage");
			});

			it("sets the type column through nested properties", () => {
				var post = variables.g.model("UPolyPost").new(title = "nested", uPolyNotes = [{body = "via nesting"}]);
				expect(post.save()).toBeTrue();
				var raw = QueryExecute("SELECT notable_type FROM c_o_r_e_upolynotes WHERE body = 'via nesting'", [], {datasource = variables.g.get("dataSourceName")});
				expect(raw.notable_type).toBe("UPolyPost");
			});

		});

	}

}
