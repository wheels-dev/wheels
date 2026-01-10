component extends="wheels.Testbox" {

	function run() {

		g = application.wo

		describe("Tests that has_many", () => {

			beforeEach(() => {
				gallery = g.model("gallery")
				photo = g.model("photo")
				user = g.model("user")
				testGallery = $setTestObjects()
				idx = {} // CF10 has issues with just using for(i in foo)
			})

			it("adds children via object array", () => {
				transaction {
					expect(testGallery.save()).toBeTrue()

					testGallery = gallery.findOneByTitle(value = "Nested Properties Gallery", include = "photos")

					expect(testGallery.photos).toBeArray()
					expect(testGallery.photos).toHaveLength(3)

					transaction action="rollback";
				}
			})

			it("deletes children via object array", () => {
				transaction {
					expect(testGallery.save()).toBeTrue()
					testGallery = gallery.findOneByTitle(value = "Nested Properties Gallery", include = "photos")
					for (idx.i in testGallery.photos) {
						idx.i._delete = true
					}
					testGallery.save()

					expect(testGallery.photos).toBeArray()
					expect(testGallery.photos).toHaveLength(0)
					
					transaction action="rollback";
				}
			})

			it("valid function runs beforeValidation callbacks on children", () => {
				expect(testGallery.valid()).toBeTrue()

				for (idx.i in testGallery.photos) {
					expect(idx.i.beforeValidationCallbackRegistered).toBeTrue()
					expect(idx.i.beforeValidationCallbackCount).toBe(1)
				}
			})

			it("valid function runs beforeValidation callbacks on children with validation error on parent", () => {
				testGallery.title = ""
				expect(testGallery.valid()).toBeFalse()

				for (idx.i in testGallery.photos) {
					expect(idx.i.beforeValidationCallbackRegistered).toBeTrue()
					expect(idx.i.beforeValidationCallbackCount).toBe(1)
				}
			})

			it("save function runs beforeValidation callbacks on children", () => {
				transaction {
					expect(testGallery.save()).toBeTrue()

					for (idx.i in testGallery.photos) {
						expect(idx.i.beforeValidationCallbackRegistered).toBeTrue()
						expect(idx.i.beforeValidationCallbackCount).toBe(1)
					}
					transaction action="rollback";
				}
			})

			it("save function runs beforeValidation callbacks on children with validation error on parent", () => {
				testGallery.title = ""
				transaction {
					expect(testGallery.save()).toBeFalse()

					for (idx.i in testGallery.photos) {
						expect(idx.i.beforeValidationCallbackRegistered).toBeTrue()
						expect(idx.i.beforeValidationCallbackCount).toBe(1)
					}
					transaction action="rollback";
				}
			})

			it("save function runs beforeCreate callback on children", () => {
				transaction {
					testGallery.save()
					for (idx.i in testGallery.photos) {
						expect(idx.i.beforeCreateCallbackCount).toBe(1)
					}
					transaction action="rollback";
				}
			})

			it("save function runs beforeSave callback on children", () => {
				transaction {
					testGallery.save()
					for (idx.i in testGallery.photos) {
						expect(idx.i.beforeSaveCallbackCount).toBe(1)
					}
					transaction action="rollback";
				}
			})
			
			it("save function runs afterCreate callback on children", () => {
				transaction {
					testGallery.save()
					for (idx.i in testGallery.photos) {
						expect(idx.i.afterCreateCallbackCount).toBe(1)
					}
					transaction action="rollback";
				}
			})
			
			it("save function runs afterSave callback on children", () => {
				transaction {
					testGallery.save()
					for (idx.i in testGallery.photos) {
						expect(idx.i.afterSaveCallbackCount).toBe(1)
					}
					transaction action="rollback";
				}
			})
			
			it("parent primary key rolled back on parent validation error", () => {
				testGallery.title = ""
				transaction {
					expect(testGallery.save()).toBeFalse()

					transaction action="rollback";
				}

				expect(testGallery.key()).toBeEmpty()
			})

			it("children primary keys rolled back on parent validation error", () => {
				testGallery.title = ""
				transaction {
					expect(testGallery.save()).toBeFalse()

					transaction action="rollback";
				}
				for (idx.i in testGallery.photos) {
					expect(idx.i.key()).toBeEmpty()
				}
			})

			it("parent primary keys rolled back on child validation error", () => {
				testGallery.photos[2].filename = ""
				transaction {
					expect(testGallery.save()).toBeFalse()

					transaction action="rollback";
				}

				expect(testGallery.key()).toBeEmpty()
			})

			it("children primary keys rolled back on child validation error", () => {
				testGallery.photos[2].filename = ""
				transaction {
					expect(testGallery.save()).toBeFalse()

					transaction action="rollback";
				}
				
				for (idx.i in testGallery.photos) {
					expect(testGallery.key()).toBeEmpty()
				}
			})
		})

		describe("Tests that has_one", () => {

			beforeEach(() => {
				author = g.model("author");
				profile = g.model("profile");
				hasone_$setTestObjects();
				testParamsStruct = $setTestParamsStruct();
			})

			/**
			 * Simulates adding an `author` and its child `profile` through a single
			 * structure passed into `author.create()`, much like what's normally done
			 * with the `params` struct.
			 */
			it("adds entire data set via create and struct", () => {
				transaction {
					/* Should return `true` on successful create */
					author = author.create(testParamsStruct.author);

					expect(author).toBeInstanceOf("author")

					transaction action="rollback";
				}

				expect(author.profile).toBeInstanceOf("Profile")
				expect(author.id).toBeTypeOf("numeric")
				expect(author.profile.id).toBeTypeOf("numeric")
			})

			/**
			 * Simulates adding an `author` and its child `profile` through a single
			 * structure passed into `author.new()` and saved with `author.save()`, much
			 * like what's normally done with the `params` struct.
			 */
			it("adds entire data set via new and struct", () => {
				author = author.new(testParamsStruct.author)
				transaction {
					expect(author.save()).toBeTrue()

					transaction action="rollback";
				}

				expect(author.profile).toBeInstanceOf("Profile")
				expect(author.id).toBeTypeOf("numeric")
				expect(author.profile.id).toBeTypeOf("numeric")
			})

			/**
			 * Loads an existing `author` and sets its child `profile` as an object before saving.
			 */
			it("adds child via object", () => {
				transaction {
					expect(testAuthor.save()).toBeTrue()

					p = profile.findByKey(testAuthor.profile.id)
					transaction action="rollback";
				}

				expect(p).toBeInstanceOf("profile")
			})

			/*
			 * Loads an existing `author` and sets its child `profile` as a struct before saving.
			 */
			it("adds child via struct", () => {
				transaction {
					expect(testAuthor.save()).toBeTrue()

					testAuthor.profile = {dateOfBirth = "10/02/1980 18:00:00", bio = bioText}

					expect(testAuthor.save()).toBeTrue()
					expect(testAuthor.profile).toBeInstanceOf("profile")

					p = profile.findByKey(testAuthor.profile.id)
					transaction action="rollback";
				}

				expect(p).toBeInstanceOf("profile")
			})

			/**
			 * Loads an existing `author` and deletes its child `profile` by setting the `_delete` property to `true`.
			 */
			it("deletes child through object property", () => {
				transaction {
					testAuthor.save()
					testAuthor.profile._delete = true
					profileID = testAuthor.profile.id

					expect(testAuthor.save()).toBeTrue()

					missingProfile = profile.findByKey(key = profileId, reload = true)
					transaction action="rollback";
				}

				expect(missingProfile).toBeBoolean()
				expect(missingProfile).toBeFalse()
			})

			/**
			 * Loads an existing `author` and deletes its child `property` by passing in a struct through `update()`.
			 */
			it("deletes child through struct", () => {
				transaction {
					testAuthor.save()
					profileID = testAuthor.profile.id
					updateStruct.profile._delete = true

					expect(testAuthor.update(properties=updateStruct)).toBeTrue()

					missingProfile = profile.findByKey(key = profileId, reload = true)
					transaction action="rollback";
				}

				expect(missingProfile).toBeBoolean()
				expect(missingProfile).toBeFalse()
			})

			it("valid function runs beforeValidation callback on child", () => {
				expect(testAuthor.valid()).toBeTrue()
				expect(testAuthor.profile.beforeValidationCallbackRegistered).toBeTrue()
				expect(testAuthor.profile.beforeValidationCallbackCount).toBe(1)
			})

			it("valid function runs beforeValidation callback on child with validation error on parent", () => {
				testAuthor.firstName = ""
				expect(testAuthor.valid()).toBeFalse()
				expect(testAuthor.profile.beforeValidationCallbackRegistered).toBeTrue()
				expect(testAuthor.profile.beforeValidationCallbackCount).toBe(1)
			})

			it("save function runs beforeValidation callback on child", () => {
				transaction {
					expect(testAuthor.save()).toBeTrue()
					expect(testAuthor.profile.beforeValidationCallbackRegistered).toBeTrue()
					expect(testAuthor.profile.beforeValidationCallbackCount).toBe(1)

					transaction action="rollback";
				}
			})

			it("save function runs beforeValidation callback on child with validation error on parent", () => {
				testAuthor.firstName = ""
				transaction {
					expect(testAuthor.save()).toBeFalse()
					expect(testAuthor.profile.beforeValidationCallbackRegistered).toBeTrue()
					expect(testAuthor.profile.beforeValidationCallbackCount).toBe(1)
					
					transaction action="rollback";
				}
			})

			it("save function runs beforeCreate callback on child", () => {
				transaction {
					testAuthor.save()
					expect(testAuthor.profile.beforeCreateCallbackCount).toBe(1)
					
					transaction action="rollback";
				}
			})

			it("save function runs beforeSave callback on child", () => {
				transaction {
					testAuthor.save()
					expect(testAuthor.profile.beforeSaveCallbackCount).toBe(1)
					
					transaction action="rollback";
				}
			})

			it("save function runs afterCreate callback on child", () => {
				transaction {
					testAuthor.save()
					expect(testAuthor.profile.afterCreateCallbackCount).toBe(1)
					
					transaction action="rollback";
				}
			})

			it("save function runs afterSave callback on child", () => {
				transaction {
					testAuthor.save()
					expect(testAuthor.profile.afterSaveCallbackCount).toBe(1)
					
					transaction action="rollback";
				}
			})
			
			it("parent primary key rolled back on parent validation error", () => {
				testAuthor = author.new(testParams.author)
				testAuthor.firstName = ""
				transaction {
					testAuthor.save()
					transaction action="rollback";
				}
				expect(testAuthor.key()).toBeEmpty()
			})
			
			it("child primary key rolled back on parent validation error", () => {
				testAuthor = author.new(testParams.author)
				testAuthor.firstName = ""
				transaction {
					testAuthor.save()
					transaction action="rollback";
				}
				expect(testAuthor.profile.key()).toBeEmpty()
			})
			
			it("parent primary key rolled back on child validation error", () => {
				testAuthor = author.new(testParams.author)
				testAuthor.profile.dateOfBirth = ""
				transaction {
					testAuthor.save()
					transaction action="rollback";
				}
				expect(testAuthor.key()).toBeEmpty()
			})
			
			it("child primary key rolled back on child validation error", () => {
				testAuthor = author.new(testParams.author)
				testAuthor.profile.dateOfBirth = ""
				transaction {
					testAuthor.save()
					transaction action="rollback";
				}
				expect(testAuthor.profile.key()).toBeEmpty()
			})
		})
	}

	private any function $setTestObjects() {
		/* User */
		var u = user.findOneByLastName("Petruzzi")
		/* Gallery */
		var _params = {
			userId = u.id,
			title = "Nested Properties Gallery",
			description = "A gallery testing nested properties."
		}
		var gallery = gallery.new(_params)
		gallery.photos = [
			photo.new(
				userId = u.id,
				filename = "Nested Properties Photo Test 1",
				DESCRIPTION1 = "test photo 1 for nested properties gallery"
			),
			photo.new(
				userId = u.id,
				filename = "Nested Properties Photo Test 2",
				DESCRIPTION1 = "test photo 2 for nested properties gallery"
			),
			photo.new(
				userId = u.id,
				filename = "Nested Properties Photo Test 3",
				DESCRIPTION1 = "test photo 3 for nested properties gallery"
			)
		]
		return gallery;
	}

	private void function hasone_$setTestObjects() {
		testAuthor = author.findOneByLastName(value = "Peters", include = "profile")
		bioText = "Loves learning how to write tests."
		testAuthor.profile = g.model("profile").new(dateOfBirth = "10/02/1980 18:00:00", bio = bioText)
	}

	/**
	 * Sets up test `author` struct reminiscent of what would be passed through a
	 * form. The `author` represented here also includes a nested child `profile` struct.
	 */
	private struct function $setTestParamsStruct() {
		testParams = {
			author = {
				firstName = "Brian",
				lastName = "Meloche",
				profile = {
					dateOfBirth = "10/02/1970 18:01:00",
					bio = "Host of CFConversations, the best ColdFusion podcast out there."
				}
			}
		}
		return testParams
	}
}