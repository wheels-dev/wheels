/**
 * hasManyCheckBox round trips through nested properties for both join-model
 * shapes: a composite primary key (postid, tagid) (#3884) and a surrogate `id`
 * primary key with the two foreign keys as plain columns, which is what
 * `wheels generate model` creates (#3885).
 *
 * The structs below are what the form posts: hasManyCheckBox names each field
 * `post[<association>][<keys>][_delete]`, where `keys` is "<post key>,<tag id>"
 * (the post key is blank on a new post). A checked box posts _delete=0 and an
 * unchecked one posts _delete=1.
 */
component extends="wheels.WheelsTest" {

	function run() {

		g = application.wo

		describe("hasManyCheckBox nested join rows", () => {

			beforeEach(() => {
				parent = g.model("postWithTagCheckboxes")
			})

			describe("composite-key join model (##3884)", () => {

				it("creates the join rows for a new parent with both keys set", () => {
					transaction {
						var post = parent.new(
							authorid = 1,
							title = "join-composite-new",
							body = "b",
							tagAssignments = {",7" = {_delete = 0}, ",8" = {_delete = 1}}
						)
						expect(post.save()).toBeTrue()
						var rows = g.model("tagAssignment").findAll(where = "postid = #post.id#", order = "tagid")
						expect(rows.recordCount).toBe(1)
						expect(rows.tagid).toBe(7)
						transaction action="rollback";
					}
				})

				it("adds and removes join rows on an existing parent", () => {
					transaction {
						var post = parent.create(authorid = 1, title = "join-composite-edit", body = "b")
						var added = parent.findByKey(post.id)
						var posted = {}
						posted["#post.id#,7"] = {_delete = 0}
						posted["#post.id#,8"] = {_delete = 0}
						expect(added.update(tagAssignments = posted)).toBeTrue()
						expect(g.model("tagAssignment").count(where = "postid = #post.id#")).toBe(2)

						var removed = parent.findByKey(post.id)
						posted = {}
						posted["#post.id#,7"] = {_delete = 0}
						posted["#post.id#,8"] = {_delete = 1}
						expect(removed.update(tagAssignments = posted)).toBeTrue()
						var rows = g.model("tagAssignment").findAll(where = "postid = #post.id#")
						expect(rows.recordCount).toBe(1)
						expect(rows.tagid).toBe(7)
						transaction action="rollback";
					}
				})

			})

			describe("surrogate-id join model (##3885)", () => {

				it("adds and removes join rows on an existing parent", () => {
					transaction {
						var post = parent.create(authorid = 1, title = "join-surrogate-edit", body = "b")
						var added = parent.findByKey(post.id)
						var posted = {}
						posted["#post.id#,7"] = {_delete = 0}
						posted["#post.id#,8"] = {_delete = 0}
						expect(added.update(classifications = posted)).toBeTrue()
						var rows = g.model("classification").findAll(where = "postid = #post.id#", order = "tagid")
						expect(rows.recordCount).toBe(2)
						expect(ValueList(rows.tagid)).toBe("7,8")

						// Re-submitting a checked row must not insert a duplicate.
						var removed = parent.findByKey(post.id)
						posted = {}
						posted["#post.id#,7"] = {_delete = 0}
						posted["#post.id#,8"] = {_delete = 1}
						expect(removed.update(classifications = posted)).toBeTrue()
						rows = g.model("classification").findAll(where = "postid = #post.id#")
						expect(rows.recordCount).toBe(1)
						expect(rows.tagid).toBe(7)
						transaction action="rollback";
					}
				})

				it("creates the join rows for a new parent", () => {
					transaction {
						var post = parent.new(
							authorid = 1,
							title = "join-surrogate-new",
							body = "b",
							classifications = {",7" = {_delete = 0}, ",8" = {_delete = 1}}
						)
						expect(post.save()).toBeTrue()
						var rows = g.model("classification").findAll(where = "postid = #post.id#")
						expect(rows.recordCount).toBe(1)
						expect(rows.tagid).toBe(7)
						transaction action="rollback";
					}
				})

				it("leaves an unrelated classification with the same id as the post untouched", () => {
					transaction {
						// The seeded classification (postid 1, tagid 7) has id 1. Before
						// the fix the first key component was read as the surrogate id,
						// so a form key "<n>,<tag>" loaded classification <n>.
						var seeded = g.model("classification").findAll(order = "id")
						var post = parent.create(authorid = 1, title = "join-surrogate-collide", body = "b")
						var edit = parent.findByKey(post.id)
						var posted = {}
						posted["#seeded.id#,8"] = {_delete = 1}
						edit.update(classifications = posted)
						expect(g.model("classification").count(where = "id = #seeded.id#")).toBe(1)
						transaction action="rollback";
					}
				})

			})

		})

		describe("composite-key join model without a belongsTo for its other key", () => {

			it("refuses a new join row with a clear error instead of a NOT NULL failure", () => {
				transaction {
					var post = g.model("postWithTagCheckboxes").create(authorid = 1, title = "join-bare-new", body = "b")
					var edit = g.model("postWithTagCheckboxes").findByKey(post.id)
					var posted = {}
					posted["#post.id#,7"] = {_delete = 0}
					var state = {type = "", message = ""}
					try {
						edit.update(bareTagAssignments = posted)
					} catch (any e) {
						state.type = e.type
						state.message = e.message & " " & e.extendedInfo
					}
					expect(state.type).toBe("Wheels.InvalidNestedKey")
					expect(state.message).toInclude("belongsTo")
					expect(g.model("tagAssignment").count(where = "postid = #post.id#")).toBe(0)
					transaction action="rollback";
				}
			})

			it("still deletes an existing join row named by its key", () => {
				transaction {
					var post = g.model("postWithTagCheckboxes").create(authorid = 1, title = "join-bare-del", body = "b")
					g.model("tagAssignment").create(postid = post.id, tagid = 7)
					var edit = g.model("postWithTagCheckboxes").findByKey(post.id)
					var posted = {}
					posted["#post.id#,7"] = {_delete = 1}
					edit.update(bareTagAssignments = posted)
					expect(g.model("tagAssignment").count(where = "postid = #post.id#")).toBe(0)
					transaction action="rollback";
				}
			})

		})

		describe("hasManyCheckBox nested keys that fit no join shape", () => {

			it("throws instead of reading a partial key as the primary key", () => {
				var post = g.model("postWithTagCheckboxes").findOne(order = "id")
				var posted = {"1,7,9" = {_delete = 1}}
				expect(() => {
					post.setProperties(classifications = posted)
				}).toThrow(type = "Wheels.InvalidNestedKey")
			})

		})

		describe("hasManyCheckBox checked state for join rows", () => {

			beforeEach(() => {
				_controller = g.controller(name = "dummy")
			})

			afterEach(() => {
				StructDelete(request, "joinCheckboxPost")
			})

			it("checks the box for an existing composite-key join row", () => {
				transaction {
					var post = g.model("postWithTagCheckboxes").create(authorid = 1, title = "join-checked-composite", body = "b")
					g.model("tagAssignment").create(postid = post.id, tagid = 7)
					request.joinCheckboxPost = g.model("postWithTagCheckboxes").findByKey(key = post.id, include = "tagAssignments")
					var checked = _controller.hasManyCheckBox(
						objectName = "request.joinCheckboxPost",
						association = "tagAssignments",
						keys = "#post.id#,7",
						label = false
					)
					var unchecked = _controller.hasManyCheckBox(
						objectName = "request.joinCheckboxPost",
						association = "tagAssignments",
						keys = "#post.id#,8",
						label = false
					)
					expect(checked).toInclude("checked=")
					expect(unchecked).notToInclude("checked=")
					transaction action="rollback";
				}
			})

			it("checks the box for an existing surrogate-id join row", () => {
				transaction {
					var post = g.model("postWithTagCheckboxes").create(authorid = 1, title = "join-checked-surrogate", body = "b")
					g.model("classification").create(postid = post.id, tagid = 7)
					request.joinCheckboxPost = g.model("postWithTagCheckboxes").findByKey(key = post.id, include = "classifications")
					var checked = _controller.hasManyCheckBox(
						objectName = "request.joinCheckboxPost",
						association = "classifications",
						keys = "#post.id#,7",
						label = false
					)
					var unchecked = _controller.hasManyCheckBox(
						objectName = "request.joinCheckboxPost",
						association = "classifications",
						keys = "#post.id#,8",
						label = false
					)
					expect(checked).toInclude("checked=")
					expect(unchecked).notToInclude("checked=")
					transaction action="rollback";
				}
			})

		})

	}

}
