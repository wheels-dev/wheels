component extends="testbox.system.BaseSpec" {

	function run() {

		g = application.wo

		describe("Tests that afterDelete", () => {

			beforeEach(() => {
				g.model("tag").$registerCallback(type = "afterDelete", methods = "callbackThatSetsProperty")
				obj = g.model("tag").findOne()
			})

			afterEach(() => {
				g.model("tag").$clearCallbacks(type = "afterDelete")
			})

			it("is working on existing object", () => {
				transaction {
					obj.delete(transaction = "none")
					transaction action="rollback";
				}

				expect(obj).toHaveKey("setByCallback")
			})

			it("is working on existing object with skipped callbacks", () => {
				transaction {
					obj.delete(transaction = "none", callbacks = "false")
					transaction action="rollback";
				}

				expect(obj).notToHaveKey('setByCallback')
			})			
		})

		describe("Tests that afterFind", () => {

			beforeEach(() => {
				g.model("post").$registerCallback(type = "afterFind", methods = "afterFindCallback")
			})

			afterEach(() => {
				g.model("post").$clearCallbacks(type = "afterFind")
			})

			it("property named method should not clash with cfinvoke", () => {
				results = g.model("collisionTest").findAll(returnAs = "objects")

				expect(results[1].method).toBe("done")
			})

			it("is setting one query record", () => {
				posts = g.model("post").findAll(maxRows = 1, order = "id DESC")

				expect(posts.views[1]).toBe(102)
				expect(posts['title'][1]).toBe("setTitle")
			})

			it("is setting one query record with skipped callback", () => {
				posts = g.model("post").findAll(maxRows = 1, order = "id DESC")

				expect(posts.views[1]).toBe(102)
				expect(posts['title'][1]).toBe("setTitle")
			})

			it("is setting multiple query records", () => {
				posts = g.model("post").findAll(order = "id DESC")

				expect(posts.views[1]).toBe(102)
				expect(posts.views[2]).toBe(103)
				expect(posts['title'][1]).toBe("setTitle")
			})

			it("is setting multiple query records with skipped callback", () => {
				posts = g.model("post").findAll(order = "id DESC", callbacks = false)

				expect(posts.views[1]).toBe(2)
				expect(posts.views[2]).toBe(3)
				expect(posts.title[1]).toBe("Title for fifth test post")
			})

			it("is setting property on one object", () => {
				post = g.model("post").findOne()

				expect(post.title).toBe("setTitle")
			})

			it("is setting property on one object with skipped callback", () => {
				post = g.model("post").findOne(callbacks = false, order = "id")

				expect(post.title).toBe("Title for first test post")
			})

			it("is setting property on multiple objects", () => {
				posts = g.model("post").findAll(returnAs = "objects")

				expect(posts[1].title).toBe("setTitle")
				expect(posts[2].title).toBe("setTitle")
			})

			it("is setting property on multiple objects with skipped callback", () => {
				posts = g.model("post").findAll(returnAs = "objects", callbacks = false, order = "id")

				expect(posts[1].title).toBe("Title for first test post")
				expect(posts[2].title).toBe("Title for second test post")
			})

			it("is creating new column and property", () => {
				posts = g.model("post").findAll(order = "id DESC")

				expect(posts.something[1]).toBe("hello world")
				
				posts = g.model("post").findAll(returnAs = "objects")
				
				expect(posts[1].something).toBe("hello world")
			})

			/* issue 329
				function test_creation_of_new_column_and_property_on_included_model() {
					posts = model("author").findAll(include="posts")
					assert("posts.something[1] eq 'hello world'")
					posts = model("author").findAll(include="posts", returnAs="objects")
					assert("posts[1].something eq 'hello world'")
				} */

			it("is getting columns added when returnAs is struct", () => {
				posts = g.model("post").findAll(returnAs = "struct")

				expect(posts[1].something).toBe("hello world")
			})
		})

		describe("Tests that afterFindNonLegacy", () => {

			beforeEach(() => {
				g.model("post").$registerCallback(type = "afterFind", methods = "afterFindCallback")
			})

			afterEach(() => {
				g.model("post").$clearCallbacks(type = "afterFind")
			})

			it("is setting property on one object", () => {
				post = g.model("post").findOne()

				expect(post.title).toBe("setTitle")
			})

			it("is setting properties on multiple objects", () => {
				postsOrg = g.model("post").findAll(returnAs = "objects", callbacks = "false", orderby = "views DESC")
				views1 = postsOrg[1].views + 100
				views2 = postsOrg[2].views + 100
				posts = g.model("post").findAll(returnAs = "objects", orderby = "views DESC")

				expect(posts[1].title).toBe("setTitle")
				expect(posts[2].title).toBe("setTitle")
				expect(posts[1].views).toBe(views1)
				expect(posts[2].views).toBe(views2)
			})

			it("is creating new column and property", () => {
				posts = g.model("post").findAll(order = "id DESC")
				
				expect(posts.something[1]).toBe("hello world")

				posts = g.model("post").findAll(returnAs = "objects")
				
				expect(posts[1].something).toBe("hello world")
			})
		})

		describe("Tests that afterSaveProperties", () => {

			it("has access to changed property values in aftersave", () => {
				g.model("user").$registerCallback(type = "afterSave", methods = "saveHasChanged")
				obj = g.model("user").findOne(where = "username = 'tonyp'")
				obj.saveHasChanged = saveHasChanged
				obj.getHasObjectChanged = getHasObjectChanged

				expect(obj.hasChanged()).toBeFalse()

				obj.password = "xxxxxxx"

				expect(obj.hasChanged()).toBeTrue()

				transaction {
					obj.save(transaction = "none")

					expect(obj.getHasObjectChanged()).toBeTrue()
					expect(obj.hasChanged()).toBeFalse()
					transaction action="rollback";
				}
				g.model("user").$clearCallbacks(type = "afterSave")
			})
		})

		describe("Tests that afterSaving", () => {

			beforeEach(() => {
				g.model("tag").$registerCallback(type = "afterValidation", methods = "callbackThatIncreasesVariable")
				g.model("tag").$registerCallback(type = "afterValidationOnCreate", methods = "callbackThatIncreasesVariable")
				g.model("tag").$registerCallback(type = "afterValidationOnUpdate", methods = "callbackThatIncreasesVariable")
				g.model("tag").$registerCallback(type = "afterSave", methods = "callbackThatIncreasesVariable")
				g.model("tag").$registerCallback(type = "afterCreate", methods = "callbackThatIncreasesVariable")
				g.model("tag").$registerCallback(type = "afterUpdate", methods = "callbackThatIncreasesVariable")
				obj = g.model("tag").findOne()
				obj.name = "somethingElse"
			})

			afterEach(() => {
				g.model("tag").$clearCallbacks(
					type = "afterValidation,afterValidationOnCreate,afterValidationOnUpdate,afterSave,afterCreate,afterUpdate"
				)
			})

			it("is working in chain when saving existing object", () => {
				transaction {
					obj.save(transaction = "none")
					transaction action="rollback";
				}

				expect(obj.callbackCount).toBe(4)
			})

			it("is working in chain when saving existing object with all callbacks skipped", () => {
				transaction {
					obj.save(transaction = "none", callbacks = false)
					transaction action="rollback";
				}

				expect(obj).notToHaveKey('callbackCount')
			})
		})

		describe("Tests that beforeCreate", () => {

			beforeEach(() => {
				g.model("tag").$registerCallback(
					type = "beforeCreate",
					methods = "callbackThatSetsProperty, callbackThatReturnsFalse"
				)
			})

			afterEach(() => {
				g.model("tag").$clearCallbacks(type = "beforeCreate")
			})

			it("is working on new object", () => {
				obj = g.model("tag").create()

				expect(obj).toHaveKey("setByCallback")
			})

			it("is working on new object with skipped callback", () => {
				obj = g.model("tag").create(
					name = "mustSetAtLeastOnePropertyOrCreateFails",
					transaction = "rollback",
					callbacks = false
				)

				expect(obj).notToHaveKey('setByCallback')
			})
		})

		describe("Tests that beforeCreateAndBeforeUpdate", () => {

			afterEach(() => {
				g.model("tag").$clearCallbacks(type = "beforeCreate,beforeUpdate")
			})

			it("is working on existing object", () => {
				g.model("tag").$registerCallback(type = "beforeCreate", methods = "callbackThatSetsProperty")
				g.model("tag").$registerCallback(type = "beforeUpdate", methods = "callbackThatReturnsFalse")
				obj = g.model("tag").findOne()
				obj.name = "somethingElse"
				obj.save()

				expect(obj).notToHaveKey('setByCallback')
			})

			it("is working on new object", () => {
				g.model("tag").$registerCallback(type = "beforeUpdate", methods = "callbackThatSetsProperty")
				g.model("tag").$registerCallback(type = "beforeCreate", methods = "callbackThatReturnsFalse")
				obj = g.model("tag").create()

				expect(obj).notToHaveKey('setByCallback')
			})
		})

		describe("Tests that beforeDelete", () => {

			beforeEach(() => {
				g.model("tag").$registerCallback(type = "beforeDelete", methods = "callbackThatSetsProperty,callbackThatReturnsFalse")
				obj = g.model("tag").findOne()
			})

			afterEach(() => {
				g.model("tag").$clearCallbacks(type = "beforeDelete")
			})

			it("is working on exising object", () => {
				obj.delete()

				expect(obj).toHaveKey("setByCallback")
			})

			it("is working on exising object with skipped callback", () => {
				obj.delete(callbacks = false, transaction = "rollback")

				expect(obj).notToHaveKey('setByCallback')
			})
		})

		describe("Tests that beforeSave", () => {

			it("is proceeding on true and nothing", () => {
				g.model("tag").$registerCallback(type = "beforeSave", methods = "callbackThatReturnsTrue,callbackThatReturnsNothing")
				obj = g.model("tag").findOne(order = "id")
				oldName = obj.name
				obj.name = "somethingElse"
				obj.save()
				obj.reload()
				name = obj.name
				obj.name = oldName
				obj.save()
				g.model("tag").$clearCallbacks(type = "beforeSave")

				expect(name).notToBe(oldName)
			})

			it("is aborting on false", () => {
				g.model("tag").$registerCallback(type = "beforeSave", methods = "callbackThatReturnsFalse")
				obj = g.model("tag").findOne(order = "id")
				oldName = obj.name
				obj.name = "somethingElse"
				obj.save()
				obj.reload()
				g.model("tag").$clearCallbacks(type = "beforeSave")

				expect(obj.name).toBe(oldName)
			})

			it("is setting property", () => {
				g.model("tag").$registerCallback(type = "beforeSave", methods = "callbackThatSetsProperty")
				obj = g.model("tag").findOne(order = "id")
				existBefore = StructKeyExists(obj, "setByCallback")
				obj.save()
				existAfter = StructKeyExists(obj, "setByCallback")
				g.model("tag").$clearCallbacks(type = "beforeSave")

				expect(existBefore).toBeFalse()
				expect(existAfter).toBeTrue()
			})

			it("is setting property with skipped callback", () => {
				g.model("tag").$registerCallback(type = "beforeSave", methods = "callbackThatSetsProperty")
				obj = g.model("tag").findOne(order = "id")
				existBefore = StructKeyExists(obj, "setByCallback")
				obj.save(callbacks = false, transaction = "rollback")
				existAfter = StructKeyExists(obj, "setByCallback")
				g.model("tag").$clearCallbacks(type = "beforeSave")

				expect(existBefore).toBeFalse()
				expect(existAfter).toBeFalse()
			})

			it("is executing in order", () => {
				g.model("tag").$registerCallback(type = "beforeSave", methods = "firstCallback,secondCallback")
				obj = g.model("tag").findOne(order = "id")
				obj.name = "somethingElse"
				obj.save()
				g.model("tag").$clearCallbacks(type = "beforeSave")

				expect(obj.orderTest).toBe("first,second")
			})

			it("is aborting chain", () => {
				g.model("tag").$registerCallback(
					type = "beforeSave",
					methods = "firstCallback,callbackThatReturnsFalse,secondCallback"
				)
				obj = g.model("tag").findOne(order = "id")
				obj.name = "somethingElse"
				obj.save()
				g.model("tag").$clearCallbacks(type = "beforeSave")

				expect(obj.orderTest).toBe("first")
			})

			it("is setting in config and clearing", () => {
				callbacks = g.model("author").$callbacks()

				expect(callbacks.beforeSave[1]).toBe("callbackThatReturnsTrue")

				g.model("author").$clearCallbacks(type = "beforeSave")

				expect(callbacks.beforeSave).toHaveLength(0)
				expect(callbacks.beforeDelete[1]).toBe("callbackThatReturnsTrue")

				g.model("author").$clearCallbacks()
				
				expect(callbacks.beforeDelete).toHaveLength(0)
			})
		})

		describe("Tests that beforeUpdate", () => {

			beforeEach(() => {
				g.model("tag").$registerCallback(type = "beforeUpdate", methods = "callbackThatSetsProperty,callbackThatReturnsFalse")
				obj = g.model("tag").findOne()
				obj.name = "somethingElse"
			})

			afterEach(() => {
				g.model("tag").$clearCallbacks(type = "beforeUpdate")
			})

			it("is working on existing object", () => {
				obj.save()

				expect(obj).toHaveKey("setByCallback")
			})

			it("is working on existing object with skipped callback", () => {
				obj.save(callbacks = false, transaction = "rollback")

				expect(obj).notToHaveKey('setByCallback')
			})
		})

		describe("Tests that beforeValidation", () => {

			beforeEach(() => {
			 	g.model("tag").$registerCallback(
					type = "beforeValidation",
					methods = "callbackThatSetsProperty,callbackThatReturnsFalse"
				)
				obj = g.model("tag").findOne()
				obj.name = "somethingElse"
			})

			afterEach(() => {
			 	g.model("tag").$clearCallbacks(type = "beforeValidation")
			})

			it("is working when saving object", () => {
			 	obj.save()

			 	expect(obj).toHaveKey("setByCallback")
			})

			it("is working when saving object without callbacks", () => {
			 	obj.save(callbacks = false, transaction = "rollback")

			 	expect(obj).notToHaveKey('setByCallback')
			})

			it("should register callback when validating nested property object", () => {
			 	obj = $setGalleryNestedProperties()
				obj.gallery.valid()

				expect(obj.gallery.photos[1].properties()).toHaveKey("beforeValidationCallbackRegistered")
			})

			it("should register callback only once when saving nested property object", () => {
			 	transaction {
					obj = $setGalleryNestedProperties()
					obj.gallery.save()

					expect(obj.gallery.photos[1].beforeValidationCallbackCount).toBe(1)
					transaction action="rollback";
				}
			})
		})

		describe("Tests that beforeValidationOnCreate", () => {

			beforeEach(() => {
				g.model("tag").$registerCallback(
					type = "beforeValidationOnCreate",
					methods = "callbackThatSetsProperty,callbackThatReturnsFalse"
				)
			})

			afterEach(() => {
				g.model("tag").$clearCallbacks(type = "beforeValidationOnCreate")
			})

			it("is working on new object", () => {
				obj = g.model("tag").create()

				expect(obj).toHaveKey("setByCallback")
			})

			it("is working on new object with skipped callback", () => {
				obj = g.model("tag").create(
					name = "mustSetAtLeastOnePropertyOrCreateFails",
					transaction = "rollback",
					callbacks = false
				)

				expect(obj).notToHaveKey('setByCallback')
			})
		})

		describe("Tests that beforeValidationOnUpdate", () => {

			beforeEach(() => {
				g.model("tag").$registerCallback(
					type = "beforeValidationOnUpdate",
					methods = "callbackThatSetsProperty,callbackThatReturnsFalse"
				)
				obj = g.model("tag").findOne()
				obj.name = "somethingElse"
			})

			afterEach(() => {
				g.model("tag").$clearCallbacks(type = "beforeValidationOnUpdate")
			})

			it("works on existing object", () => {
				obj.save()

				expect(obj, "setByCallback")
			})

			it("works on existing object with skipped callback", () => {
				obj.save(callbacks = false, transaction = "rollback")

				expect(obj).notToHaveKey('setByCallback')
			})
		})

		describe("Tests that custom", () => {

			it("is working on existing object", () => {
				args.type = "myCustomCallBack"
				g.model("tag").$registerCallback(type = args.type, methods = "methodOne")
				r = g.model("tag").$callbacks(argumentCollection = args)

				expect(r).toBeArray()
				expect(r).toHaveLength(1)
			})
		})
	}

	function saveHasChanged() {
		hasObjectChanged = hasChanged()
	}

	function getHasObjectChanged() {
		return hasObjectChanged
	}

	function $setGalleryNestedProperties() {
		var rv = {}
		rv.user = g.model("user").findOneByLastName("Petruzzi")
		rv.gallery = g.model("gallery").new(
			userId = rv.user.id,
			title = "Nested Properties Gallery",
			description = "A gallery testing nested properties."
		)
		rv.gallery.photos = [
			g.model("photo").new(
				userId = rv.user.id,
				filename = "Nested Properties Photo Test 1",
				DESCRIPTION1 = "test photo 1 for nested properties gallery"
			)
		]
		return rv
	}
}