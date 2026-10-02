/**
 * Nested properties only update or delete child rows that belong to the parent
 * being saved. A nested key comes from the request, so a form for parent A must
 * not be able to name, change, move or delete a child row of parent B.
 *
 * Every spec builds A and B, gives B a child, then saves A with B's child key
 * the way a form for A could post it, and checks that B's row is unchanged.
 */
component extends="wheels.WheelsTest" {

	function run() {

		g = application.wo

		describe("Nested child rows are scoped to the parent", () => {

			describe("hasMany with a surrogate primary key (gallery photos)", () => {

				it("does not delete another parent's child", () => {
					transaction {
						var fx = galleries()
						var posted = {}
						posted[fx.photoB.id] = {_delete = 1}
						fx.a.update(photos = posted)
						expect(g.model("photo").count(where = "id = #fx.photoB.id#")).toBe(1)
						transaction action="rollback";
					}
				})

				it("does not change or move another parent's child", () => {
					transaction {
						var fx = galleries()
						var posted = {}
						posted[fx.photoB.id] = {DESCRIPTION1 = "changed by A", filename = "a.jpg"}
						fx.a.update(photos = posted)
						var row = g.model("photo").findByKey(fx.photoB.id)
						expect(row.galleryid).toBe(fx.b.id)
						expect(row.DESCRIPTION1).toBe("owned by B")
						transaction action="rollback";
					}
				})

				it("does not move another parent's child through a posted foreign key", () => {
					transaction {
						var fx = galleries()
						var posted = {}
						posted[fx.photoB.id] = {galleryid = fx.a.id, DESCRIPTION1 = "changed by A"}
						fx.a.update(photos = posted)
						expect(g.model("photo").findByKey(fx.photoB.id).galleryid).toBe(fx.b.id)
						transaction action="rollback";
					}
				})

				// The positive controls post arrays: a struct key above 2^31 is read as a new
				// row (the GetTickCount guard), and CockroachDB ids always are.
				it("still updates and deletes the parent's own children", () => {
					transaction {
						var fx = galleries()
						expect(fx.a.update(photos = [{id = fx.photoA.id, DESCRIPTION1 = "edited"}])).toBeTrue()
						expect(g.model("photo").findByKey(fx.photoA.id).DESCRIPTION1).toBe("edited")
						var reloaded = g.model("gallery").findByKey(fx.a.id)
						reloaded.update(photos = [{id = fx.photoA.id, _delete = 1}])
						expect(g.model("photo").count(where = "id = #fx.photoA.id#")).toBe(0)
						transaction action="rollback";
					}
				})

				it("does not delete another parent's child posted as an array", () => {
					transaction {
						var fx = galleries()
						fx.a.update(photos = [{id = fx.photoB.id, _delete = 1}])
						expect(g.model("photo").count(where = "id = #fx.photoB.id#")).toBe(1)
						transaction action="rollback";
					}
				})

				it("does not change or move another parent's child posted as an array", () => {
					transaction {
						var fx = galleries()
						fx.a.update(photos = [{id = fx.photoB.id, DESCRIPTION1 = "changed by A", galleryid = fx.a.id}])
						var row = g.model("photo").findByKey(fx.photoB.id)
						expect(row.galleryid).toBe(fx.b.id)
						expect(row.DESCRIPTION1).toBe("owned by B")
						transaction action="rollback";
					}
				})

			})

			describe("hasMany with a string parent key", () => {

				it("does not treat parent '01' as parent '1' when deleting", () => {
					transaction {
						var fx = codes()
						var posted = {}
						posted[fx.childOne.id] = {_delete = 1}
						fx.zeroOne.update(codeChildren = posted)
						expect(g.model("codeChild").count(where = "id = #fx.childOne.id#")).toBe(1)
						transaction action="rollback";
					}
				})

				it("does not treat parent '01' as parent '1' when updating", () => {
					transaction {
						var fx = codes()
						var posted = {}
						posted[fx.childOne.id] = {label = "changed by 01"}
						fx.zeroOne.update(codeChildren = posted)
						var row = g.model("codeChild").findByKey(fx.childOne.id)
						expect(row.parentcode).toBe("1")
						expect(row.label).toBe("owned by 1")
						transaction action="rollback";
					}
				})

				it("does not treat a parent key with a leading space as the same parent", () => {
					transaction {
						var fx = codes()
						var posted = {}
						posted[fx.childOne.id] = {_delete = 1}
						fx.spaced.update(codeChildren = posted)
						expect(g.model("codeChild").count(where = "id = #fx.childOne.id#")).toBe(1)
						transaction action="rollback";
					}
				})

				it("still deletes the parent's own child", () => {
					transaction {
						var fx = codes()
						fx.one.update(codeChildren = [{id = fx.childOne.id, _delete = 1}])
						expect(g.model("codeChild").count(where = "id = #fx.childOne.id#")).toBe(0)
						transaction action="rollback";
					}
				})

			})

			describe("hasMany through a custom joinKey", () => {

				it("checks ownership against the join column, not the primary key", () => {
					transaction {
						var fx = joinKeys()
						var posted = {}
						posted[fx.childB.id] = {_delete = 1}
						fx.a.update(jkChildren = posted)
						expect(g.model("jkChild").count(where = "id = #fx.childB.id#")).toBe(1)
						transaction action="rollback";
					}
				})

				it("links a new child through the join column", () => {
					transaction {
						var fx = joinKeys()
						var posted = {"new-1" = {label = "added by A"}}
						expect(fx.a.update(jkChildren = posted)).toBeTrue()
						var row = g.model("jkChild").findOne(where = "label = 'added by A'")
						expect(row.parentcode).toBe(fx.a.code)
						transaction action="rollback";
					}
				})

				it("still deletes the parent's own child", () => {
					transaction {
						var fx = joinKeys()
						fx.a.update(jkChildren = [{id = fx.childA.id, _delete = 1}])
						expect(g.model("jkChild").count(where = "id = #fx.childA.id#")).toBe(0)
						transaction action="rollback";
					}
				})

			})

			describe("nested struct keys above 2^31", () => {

				// The 19-digit end-to-end specs need an adapter that reports BIGINT as
				// cf_sql_bigint. SQLite and Oracle report it as cf_sql_integer (a separate
				// adapter limitation), so there the key is still read as a new row (fail
				// closed) and binding a 19-digit fixture id as an integer is refused by Adobe.
				var bigintAware = g.model("bigKeyPost").$nestedKeyColumnSqlType(model = g.model("bigKeyPost"), column = "id") == "cf_sql_bigint"

				it(title = "updates the parent's own join rows through a 19-digit composite key", skip = !bigintAware, body = () => {
					transaction {
						var big = bigKeys()
						var posted = {}
						posted["#big.id#,7"] = {_delete = 1}
						posted["#big.id#,8"] = {_delete = 0}
						expect(big.post.update(bigTagAssignments = posted)).toBeTrue()
						var rows = g.model("bigTagAssignment").findAll(where = "postid = #big.id#", order = "tagid", returnAs = "query")
						expect(rows.recordCount).toBe(1)
						expect(rows.tagid).toBe(8)
						transaction action="rollback";
					}
				})

				it(title = "does not delete another parent's 19-digit join row", skip = !bigintAware, body = () => {
					transaction {
						var big = bigKeys()
						var other = g.model("bigKeyPost").create(id = "1215335296921698306", title = "other")
						var posted = {}
						posted["#big.id#,7"] = {_delete = 1}
						other.update(bigTagAssignments = posted)
						expect(g.model("bigTagAssignment").count(where = "postid = #big.id# AND tagid = 7")).toBe(1)
						transaction action="rollback";
					}
				})

				it("reads each key part against its own column's range", () => {
					var m = g.model("postWithTagCheckboxes")
					// A composite key whose digits would exceed 2^31 if read as one number
					// (BoxLang's IsNumeric() accepts the comma).
					expect(m.$isNewNestedCollectionKey(collectionKey = "21474,83648", value = {})).toBeFalse()
					expect(m.$integerStringExceedsSqlType(value = "2147483648", sqlType = "cf_sql_integer")).toBeTrue()
					expect(m.$integerStringExceedsSqlType(value = "2147483647", sqlType = "cf_sql_integer")).toBeFalse()
					expect(m.$integerStringExceedsSqlType(value = "1215335296921698305", sqlType = "cf_sql_bigint")).toBeFalse()
					expect(m.$integerStringExceedsSqlType(value = "9223372036854775808", sqlType = "cf_sql_bigint")).toBeTrue()
					expect(m.$integerStringExceedsSqlType(value = "99999999999999999999", sqlType = "cf_sql_numeric")).toBeFalse()
					// Signed minima are in range; one below is not.
					expect(m.$integerStringExceedsSqlType(value = "-2147483648", sqlType = "cf_sql_integer")).toBeFalse()
					expect(m.$integerStringExceedsSqlType(value = "-2147483649", sqlType = "cf_sql_integer")).toBeTrue()
					expect(m.$integerStringExceedsSqlType(value = "-9223372036854775808", sqlType = "cf_sql_bigint")).toBeFalse()
					expect(m.$integerStringExceedsSqlType(value = "-9223372036854775809", sqlType = "cf_sql_bigint")).toBeTrue()
					expect(m.$isNewNestedCollectionKey(collectionKey = "-2147483648", value = {})).toBeFalse()
					// A stale GetTickCount-style key on a 32-bit column is still a new row.
					expect(m.$isNewNestedCollectionKey(collectionKey = "1696262400000", value = {})).toBeTrue()
				})

			})

			describe("key comparison", () => {

				it("does not round 19-digit integer keys", () => {
					var m = g.model("postWithTagCheckboxes")
					expect(m.$nestedKeyValuesMatch(a = "1234567890123456789", b = "1234567890123456788", type = "integer")).toBeFalse()
					expect(m.$nestedKeyValuesMatch(a = "1234567890123456789", b = "1234567890123456789", type = "integer")).toBeTrue()
					// A key the engine hands back as a java.lang.Long, where the engine has Java classes
					// (capability probe; RustCFML has no JVM). Written in the try, not the catch.
					var probe = {hasLong = false, big = ""}
					try {
						probe.big = CreateObject("java", "java.lang.Long").valueOf("1234567890123456789")
						probe.hasLong = true
					} catch (any e) {
					}
					if (probe.hasLong) {
						expect(m.$nestedKeyValuesMatch(a = probe.big, b = "1234567890123456789", type = "integer")).toBeTrue()
						expect(m.$nestedKeyValuesMatch(a = probe.big, b = "1234567890123456788", type = "integer")).toBeFalse()
					}
				})

				it("canonicalises sign and leading zeros on integer keys only", () => {
					var m = g.model("postWithTagCheckboxes")
					expect(m.$nestedKeyValuesMatch(a = "-01", b = "-1", type = "integer")).toBeTrue()
					expect(m.$nestedKeyValuesMatch(a = "+5", b = "5", type = "integer")).toBeTrue()
					expect(m.$nestedKeyValuesMatch(a = "-0", b = "0", type = "integer")).toBeTrue()
					expect(m.$nestedKeyValuesMatch(a = "-1", b = "1", type = "integer")).toBeFalse()
					expect(m.$nestedKeyValuesMatch(a = "01", b = "1", type = "string")).toBeFalse()
					expect(m.$nestedKeyValuesMatch(a = "1 ", b = "1", type = "string")).toBeFalse()
					expect(m.$nestedKeyValuesMatch(a = "abc", b = "ABC", type = "string")).toBeFalse()
				})

			})

			describe("hasMany through a composite-key join model", () => {

				it("does not delete another parent's join row", () => {
					transaction {
						var fx = posts()
						g.model("tagAssignment").create(postid = fx.b.id, tagid = 7)
						var posted = {}
						posted["#fx.b.id#,7"] = {_delete = 1}
						fx.a.update(tagAssignments = posted)
						expect(g.model("tagAssignment").count(where = "postid = #fx.b.id# AND tagid = 7")).toBe(1)
						transaction action="rollback";
					}
				})

				it("does not rewrite another parent's join row", () => {
					transaction {
						var fx = posts()
						g.model("tagAssignment").create(postid = fx.b.id, tagid = 7)
						var posted = {}
						posted["#fx.b.id#,7"] = {_delete = 0}
						fx.a.update(tagAssignments = posted)
						expect(g.model("tagAssignment").count(where = "postid = #fx.b.id# AND tagid = 7")).toBe(1)
						transaction action="rollback";
					}
				})

			})

			describe("hasMany through a surrogate-id join model", () => {

				it("does not delete another parent's join row named by its foreign keys", () => {
					transaction {
						var fx = posts()
						g.model("classification").create(postid = fx.b.id, tagid = 7)
						var posted = {}
						posted["#fx.b.id#,7"] = {_delete = 1}
						fx.a.update(classifications = posted)
						expect(g.model("classification").count(where = "postid = #fx.b.id# AND tagid = 7")).toBe(1)
						transaction action="rollback";
					}
				})

				it("does not delete another parent's join row named by its id", () => {
					transaction {
						var fx = posts()
						var rowB = g.model("classification").create(postid = fx.b.id, tagid = 7)
						var posted = {}
						posted[rowB.id] = {_delete = 1}
						fx.a.update(classifications = posted)
						expect(g.model("classification").count(where = "id = #rowB.id#")).toBe(1)
						transaction action="rollback";
					}
				})

				it("does not move another parent's join row named by its id", () => {
					transaction {
						var fx = posts()
						var rowB = g.model("classification").create(postid = fx.b.id, tagid = 7)
						var posted = {}
						posted[rowB.id] = {tagid = 8}
						fx.a.update(classifications = posted)
						var row = g.model("classification").findByKey(rowB.id)
						expect(row.postid).toBe(fx.b.id)
						expect(row.tagid).toBe(7)
						transaction action="rollback";
					}
				})

			})

			describe("hasMany with a composite primary key that is not all foreign keys", () => {

				it("refuses a posted slotnumber on a new child with a clear error", () => {
					// slotnumber is a primary-key column but not a foreign key, so a nested form
					// can't set it on a new row: a configuration error, not a NOT NULL from the
					// database (and the posted value is never stored).
					var fx = {a = g.model("postWithTagCheckboxes").findOne(order = "id")}
					var posted = {}
					posted["#fx.a.id#,42"] = {label = "posted"}
					expect(() => {
						fx.a.setProperties(postSlots = posted)
					}).toThrow(type = "Wheels.InvalidNestedKey")
				})

			})

			describe("hasOne (author profile)", () => {

				it("does not change or move another parent's child", () => {
					transaction {
						var fx = authors()
						fx.a.update(profile = {id = fx.profileB.id, bio = "changed by A", dateOfBirth = "1/1/1980"})
						var row = g.model("profile").findByKey(fx.profileB.id)
						expect(row.authorid).toBe(fx.b.id)
						expect(row.bio).toBe("owned by B")
						transaction action="rollback";
					}
				})

				it("does not retarget an already loaded child to another parent's row", () => {
					transaction {
						var fx = authors()
						var loaded = g.model("author").findByKey(key = fx.a.id, include = "profile")
						loaded.update(profile = {id = fx.profileB.id, bio = "changed by A"})
						var row = g.model("profile").findByKey(fx.profileB.id)
						expect(row.authorid).toBe(fx.b.id)
						expect(row.bio).toBe("owned by B")
						transaction action="rollback";
					}
				})

				it("does not delete another parent's child", () => {
					transaction {
						var fx = authors()
						fx.a.update(profile = {id = fx.profileB.id, _delete = 1})
						expect(g.model("profile").count(where = "id = #fx.profileB.id#")).toBe(1)
						transaction action="rollback";
					}
				})

			})

			describe("belongsTo (profile author)", () => {

				it("does not change a record the parent does not reference", () => {
					transaction {
						var fx = authors()
						var profileA = g.model("profileWithAuthor").findByKey(fx.profileA.id)
						profileA.update(author = {id = fx.b.id, lastName = "changed by A"})
						expect(g.model("author").findByKey(fx.b.id).lastName).toBe("ScopeB")
						transaction action="rollback";
					}
				})

				it("still updates the record the parent references", () => {
					transaction {
						var fx = authors()
						var profileA = g.model("profileWithAuthor").findByKey(fx.profileA.id)
						profileA.update(author = {id = fx.a.id, lastName = "edited"})
						expect(g.model("author").findByKey(fx.a.id).lastName).toBe("edited")
						transaction action="rollback";
					}
				})

			})

		})

	}

	private struct function galleries() {
		var rv = {}
		var userId = application.wo.model("user").findOne(order = "id").id
		rv.a = application.wo.model("gallery").create(userid = userId, title = "scope A", description = "a")
		rv.b = application.wo.model("gallery").create(userid = userId, title = "scope B", description = "b")
		rv.photoA = application.wo.model("photo").create(galleryid = rv.a.id, filename = "a.jpg", DESCRIPTION1 = "owned by A")
		rv.photoB = application.wo.model("photo").create(galleryid = rv.b.id, filename = "b.jpg", DESCRIPTION1 = "owned by B")
		rv.a = application.wo.model("gallery").findByKey(rv.a.id)
		return rv
	}

	private struct function codes() {
		var rv = {}
		var parent = application.wo.model("codeParent")
		parent.create(code = "1", name = "one")
		parent.create(code = "01", name = "zero one")
		// A leading space: SQL Server compares trailing spaces as padding ('1' = '1 ').
		parent.create(code = " 1", name = "spaced")
		rv.one = parent.findByKey("1")
		rv.zeroOne = parent.findByKey("01")
		rv.spaced = parent.findOne(where = "name = 'spaced'")
		rv.childOne = application.wo.model("codeChild").create(parentcode = "1", label = "owned by 1")
		return rv
	}

	private struct function joinKeys() {
		var rv = {}
		var parent = application.wo.model("jkParent")
		var a = parent.create(code = 0)
		var b = parent.create(code = 0)
		// B's join column equals A's primary key, so a primary-key comparison would
		// wrongly treat B's child as A's.
		a.update(code = a.id + 100000)
		b.update(code = a.id)
		rv.a = parent.findByKey(a.id)
		rv.childA = application.wo.model("jkChild").create(parentcode = rv.a.code, label = "owned by A")
		rv.childB = application.wo.model("jkChild").create(parentcode = a.id, label = "owned by B")
		return rv
	}

	private struct function bigKeys() {
		var rv = {id = "1215335296921698305"}
		application.wo.model("bigKeyPost").create(id = rv.id, title = "big")
		application.wo.model("bigTagAssignment").create(postid = rv.id, tagid = 7)
		rv.post = application.wo.model("bigKeyPost").findByKey(rv.id)
		return rv
	}

	private struct function posts() {
		var rv = {}
		var parent = application.wo.model("postWithTagCheckboxes")
		rv.a = parent.create(authorid = 1, title = "scope post A", body = "a")
		rv.b = parent.create(authorid = 1, title = "scope post B", body = "b")
		rv.a = parent.findByKey(rv.a.id)
		return rv
	}

	private struct function authors() {
		var rv = {}
		rv.a = application.wo.model("author").create(firstName = "Scope", lastName = "ScopeA")
		rv.b = application.wo.model("author").create(firstName = "Scope", lastName = "ScopeB")
		rv.profileA = application.wo.model("profile").create(authorid = rv.a.id, dateOfBirth = "1/1/1970", bio = "owned by A")
		rv.profileB = application.wo.model("profile").create(authorid = rv.b.id, dateOfBirth = "1/1/1970", bio = "owned by B")
		rv.a = application.wo.model("author").findByKey(rv.a.id)
		return rv
	}

}
