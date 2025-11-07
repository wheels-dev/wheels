component extends="wheels.Testbox" {

	function run() {

		g = application.wo

		describe("Tests that accessibleproperties", () => {

			beforeEach(() => {
				// BoxLang compatibility: Force model reinitialization since Duplicate() doesn't work
				g.$clearModelInitializationCache()
				_authorModel = g.model("author")
				_postModel = g.model("post")
			})

			afterEach(() => {
				// Clear model cache to prevent cross-test contamination
				g.$clearModelInitializationCache()
			})

			it("can be set by default", () => {
				properties = {firstName = "James", lastName = "Gibson"}
				_model = _authorModel.new(properties = properties)

				expect(_model).toHaveKey("firstName")
				expect(_model).toHaveKey("lastName")
			})

			it("can not set other properties", () => {
				_postModel.accessibleProperties(properties = "views")
				properties = {views = "2000", averageRating = 4.9, body = "This is the body", title = "this is the title"}
				_model = _postModel.new(properties = properties)

				expect(_model).notToHaveKey("averageRating")
				expect(_model).notToHaveKey("body")
				expect(_model).notToHaveKey("title")
				expect(_model).toHaveKey("views")
			})

			it("can be set directly", () => {
				_postModel.accessibleProperties(properties = "views")
				_model = _postModel.new()
				_model.averageRating = 4.9
				_model.body = "This is the body"
				_model.title = "this is the title"

				expect(_model).toHaveKey("averageRating")
				expect(_model).toHaveKey("body")
				expect(_model).toHaveKey("title")
			})
		})

		describe("Tests that columnForProperty", () => {

			beforeEach(() => {
				_model = g.model("author").new()
			})

			it("returns column name", () => {
				expect(_model.columnForProperty("firstName")).toBe("firstname")
			})

			it("returns false", () => {
				expect(_model.columnForProperty("myFavy")).toBeFalse()
			})
			
			it("works with dynamic method call", () => {
				expect(_model.columnForFirstName()).toBe("firstname")
			})
		})

		describe("Tests that columns", () => {

			it("returns array", () => {
				columns = g.model("author").columns()
				
				expect(columns).toBeArray()
			})
		})

		describe("Tests that defaults", () => {

			it("creates new model with property defaults", () => {
				author = g.model("Author").new()

				expect(author).toHaveKey("firstName")
				expect(author.firstName).toBe("Dave")
			})

			it("creates new model with property defaults set to blank", () => {
				author = g.model("Author").new()

				expect(author).toHaveKey("lastName")
				expect(author.lastName).toBe("")
			})

			it("loads database defaults after create", () => {
				transaction action="begin" {
					user = g.model("UserBlank").create(
						username = "The Dude",
						password = "doodle",
						firstName = "The",
						lastName = "Dude",
						reload = true
					)
					transaction action="rollback";
				}
				if(isInstanceOf(user.birthTime,"java.time.LocalDateTime")){
					user.birthTime = createDateTime(user.birthTime.getYear(),user.birthTime.getMonthValue(),user.birthTime.getDayOfMonth(),user.birthTime.getHour(),user.birthTime.getMinute(),user.birthTime.getSecond());
				} else if (isInstanceOf(user.birthTime, "oracle.sql.TIMESTAMP")){
					user.birthTime = user.birthTime.timestampValue();
				}
				expect(user).toHaveKey("birthTime")
				expect(TimeFormat(user.birthTime, "HH:mm:ss")).toBe("18:26:08")
			})

			it("loads database defaults after save", () => {
				transaction action="begin" {
					user = g.model("UserBlank").new(username = "The Dude", password = "doodle", firstName = "The", lastName = "Dude")
					user.save(reload = true)
					transaction action="rollback";
				}
				if(isInstanceOf(user.birthTime,"java.time.LocalDateTime")){
					user.birthTime = createDateTime(user.birthTime.getYear(),user.birthTime.getMonthValue(),user.birthTime.getDayOfMonth(),user.birthTime.getHour(),user.birthTime.getMinute(),user.birthTime.getSecond());
				} else if (isInstanceOf(user.birthTime, "oracle.sql.TIMESTAMP")){
					user.birthTime = user.birthTime.timestampValue();
				}
				expect(user).toHaveKey("birthTime")
				expect(TimeFormat(user.birthTime, "HH:mm:ss")).toBe("18:26:08")
			})
		})

		describe("Tests that hasChanged", () => {

			it("handles boolean properly", () => {
				sqltype = g.model("Sqltype").findOne();
				sqltype.booleanType = "false"

				expect(sqltype.hasChanged()).toBeFalse()

				sqltype.booleanType = "no"

				expect(sqltype.hasChanged()).toBeFalse()

				sqltype.booleanType = 0

				expect(sqltype.hasChanged()).toBeFalse()

				sqltype.booleanType = "0"

				expect(sqltype.hasChanged()).toBeFalse()

				sqltype.booleanType = "true"

				expect(sqltype.hasChanged()).toBeTrue()

				sqltype.booleanType = "yes"

				expect(sqltype.hasChanged()).toBeTrue()

				sqltype.booleanType = 1

				expect(sqltype.hasChanged()).toBeTrue()

				sqltype.booleanType = "1"

				expect(sqltype.hasChanged()).toBeTrue()
			})

			it("should be able to update integer from null to 0", () => {
				user = g.model("user").findByKey(1)

				transaction {
					user.birthDayYear = ""
					user.save()
					user.birthDayYear = 0
					user.save()
					user.reload()
					transaction action="rollback";
				}

				expect(user.birthDayYear).toBe(0)
			})
		})

		describe("Tests that hasProperty", () => {

			it("returns true when property is set", () => {
				_model = g.model("author")
				properties = {firstName = "James", lastName = "Gibson"}
				_model = _model.new(properties = properties)

				expect(_model.hasProperty("firstname")).toBeTrue()
			})

			it("returns true when property is blank", () => {
				_model = g.model("author").new()

				expect(_model.hasProperty("firstname")).toBeTrue()
			})

			it("returns false when property does not exist", () => {
				_model = g.model("author").new()
				StructDelete(_model, "lastName")

				expect(_model.hasProperty("lastName")).toBeFalse()
			})

			it("dynamic method call", () => {
				_model = g.model("author")
				properties = {firstName = "James", lastName = "Gibson"}
				_model = _model.new(properties = properties)

				expect(_model.hasFirstName()).toBeTrue()
			})
		})
		
		describe("Tests that ignorecolumns", () => {
			it("works", () => {
				shop = g.model("shop").findOne()
				expect(shop).notToHaveKey('isblackmarket')
			})
		})
		
		describe("Tests that key", () => {

			it("works", () => {
				author = g.model("author").findOne()
				result = author.key()

				expect(result).toBe(author.id)
			})

			it("is selecting pk through calculated property", () => {
				shop = g.model("Shop").findOne(select = "shopid", where = "id = 'shop1'")
				actual = shop.key()

				expect(len(actual)).toBeGT(0)
			})

			it("works with new", () => {
				author = g.model("author").new(id = 1, firstName = "Per", lastName = "Djurner")
				result = author.key()

				expect(result).toBe(1)
			})

			it("returns numeric value if PK is numeric", () => {
				author = g.model("author").findByKey(1)
				authorArr = []

				// BoxLang compatibility: Ensure numeric ID remains numeric
				local.authorId = author.key()
				if (StructKeyExists(server, "boxlang") && IsNumeric(local.authorId)) {
					local.authorId = Int(local.authorId)
				}

				arrayAppend(authorArr, {
					"id": local.authorId,
					"firstname": author.firstname,
					"lastname": author.lastname
				})

				responseJSON = serializeJSON(authorArr)

				expect(find('"id":1',responseJSON)).toBeTrue()
			})

			xit("returns pk calculated property selecting alias", () => {
				shop = g.model("Shop").findOne(select = "id", where = "id = 'shop1'")
				actual = shop.key()
				expect(Len(actual)).toBeGT(0)
			})
		})

		describe("Tests that properties", () => {

			beforeEach(() => {
				_debug = false
			})

			it("is setting and getting properties", () => {
				user = g.model("user").new()

				args = {}
				args.Address = "1313 mockingbird lane"
				args.City = "deerfield beach"
				args.Fax = "9545551212"
				args.FirstName = "anthony"
				args.LastName = "Petruzzi"
				args.Password = "it's a secret"
				args.Phone = "9544826106"
				args.State = "fl"
				args.UserName = "tonypetruzzi"
				args.ZipCode = "33441"
				args.Id = ""
				args.birthday = "11/01/1975"
				args.birthdaymonth = "11"
				args.birthdayyear = "1975"
				args.allowExplicitTimestamps = false

				user.setProperties(args)

				props = user.properties()

				for (i in props) {
					expect(props[i]).toBe(args[i])
				}

				args.FirstName = "per"
				args.LastName = "djurner"

				user.setproperties(firstname = "per", lastname = "djurner")
				props = user.properties()

				for (i in props) {
					expect(props[i]).toBe(args[i])
				}

				args.FirstName = "chris"
				args.LastName = "peters"
				args.ZipCode = "33333"

				_params = {}
				_params.lastname = "peters"
				_params.zipcode = "33333"

				user.setproperties(firstname = "chris", properties = _params)
				props = user.properties()

				for (i in props) {
					expect(props[i]).toBe(args[i])
				}
			})

			it("is setting and getting properties with named arguments", () => {
				author = g.model("author").findOne()
				author.setProperties(firstName = "a", lastName = "b")
				result = author.properties()

				expect(result.firstName).toBe("a")
				expect(result.lastName).toBe("b")
			})

			it("returns expected struct keys in properties", () => {
				author = g.model("author").new(firstName = "Foo", lastName = "Bar")

				_properties = author.properties()
				actual = ListSort(StructKeyList(_properties), "text")
				expected = "allowExplicitTimestamps,firstName,lastName"

				expect(actual).toBe(expected)
				expect(author.firstName).toBe("Foo")
				expect(author.lastName).toBe("Bar")
			})

			it("returns an object in nested property", () => {
				author = g.model("author").new(firstName = "Foo", lastName = "Bar")
				author.post = g.model("post").new(title = "Brown Fox")
				_properties = author.properties()

				actual = IsObject(_properties.post)
				
				expect(actual).toBeTrue()
			})

			it("returns array of objects in nested properties", () => {
				author = g.model("author").new(firstName = "Foo", lastName = "Bar")
				author.posts = [g.model("post").new(title = "Brown Fox"), g.model("post").new(title = "Lazy Dog")]

				actual = author.properties().posts[2]

				expect(actual).toBeInstanceOf("post")
			})

			it("does not return nested property when returnincluded is false", () => {
				author = g.model("author").new(firstName = "Foo", lastName = "Bar")
				author.post = g.model("post").new(title = "Brown Fox")

				_properties = author.properties(returnIncluded = false)
				actual = ListSort(StructKeyList(_properties), "text")
				expected = "allowExplicitTimestamps,firstName,lastName"

				expect(actual).toBe(expected)
			})

			it("returns included model as object in afterFind callback", () => {
				mypost = g.model("postWithAfterFindCallback").findOne(include = "author")

				expect(mypost.author).toBeInstanceOf("author")
			})

			it("overrides calculated property", () => {
				user = g.model("User3").findOne()

				expect(user).toBeInstanceOf("user3")
				expect(user.firstName).toBe("Calculated Property Column Override")
			})
		})

		describe("Tests that propertyIsBlank", () => {

			it("return false when property is set", () => {
				_model = g.model("author")
				properties = {firstName = "James", lastName = "Gibson"}
				_model = _model.new(properties = properties)

				expect(_model.propertyIsBlank("firstName")).toBeFalse()
			})

			it("return true when property is blank", () => {
				_model = g.model("author").new();
				_model.lastName = ""

				expect(_model.propertyIsBlank("lastName")).toBeTrue()
			})

			it("return true when property does not exist", () => {
				_model = g.model("author").new()
				StructDelete(_model, "lastName")

				expect(_model.propertyIsBlank("lastName")).toBeTrue()
			})

			it("dynamic method call", () => {
				_model = g.model("author")
				properties = {firstName = "James", lastName = "Gibson"}
				_model = _model.new(properties = properties)

				expect(_model.firstNameIsBlank()).toBeFalse()
			})
		})

		describe("Tests that propertyIsPresent", () => {

			it("return true when property is set", () => {
				_model = g.model("author")
				properties = {firstName = "James", lastName = "Gibson"}
				_model = _model.new(properties = properties)

				expect(_model.propertyIsPresent("firstName")).toBeTrue()
			})

			it("return false when property is blank", () => {
				_model = g.model("author").new();
				_model.lastName = ""

				expect(_model.propertyIsPresent("lastName")).toBeFalse()
			})

			it("return false when property does not exist", () => {
				_model = g.model("author").new()
				StructDelete(_model, "lastName")

				expect(_model.propertyIsPresent("lastName")).toBeFalse()
			})

			it("dynamic method call", () => {
				_model = g.model("author")
				properties = {firstName = "James", lastName = "Gibson"}
				_model = _model.new(properties = properties)

				expect(_model.firstNameIsPresent()).toBeTrue()
			})
		})

		describe("Tests that protectedproperties", () => {

			it("cannot set property with mass assignment when protected", () => {
				_model = g.model("post")
				_model.protectedProperties(properties = "views")
				properties = {views = "2000"}
				_model = _model.new(properties = properties)

				expect(_model).notToHaveKey("views")
			})

			it("can set property directly", () => {
				_model = g.model("post");
				_model.protectedProperties(properties = "views");
				_model = _model.new();
				_model.views = 2000;

				expect(_model).toHaveKey("views")
			})
		})

		describe("Tests that timestamp", () => {

			afterEach(() => {
				g.model("Post").getClass().timeStampOnCreateProperty = "createdAt"
				g.model("Post").getClass().timeStampOnUpdateProperty = "updatedAt"
				g.model("Post").getClass().timeStampMode = "utc"
			})

			it("UTC works", () => {
				transaction {
					utctime = DateConvert("local2Utc", Now())
					author = g.model("Author").findOne()
					post = author.createPost(title = "test post", body = "here is some text")

					if (get("adapterName") == "SQLite") {
						// Store as quoted ISO 8601 string (standard for SQLite)
						if (IsDate(utctime)) {
							utctime = "#DateFormat(utctime, 'yyyy-mm-dd')# #TimeFormat(utctime, 'HH:mm:ss')#";
						}
						post.createdAt = replaceNoCase(post.createdAt, "'", "", "all");
						post.updatedAt = replaceNoCase(post.updatedAt, "'", "", "all");
					}
					expect(DateDiff("s", utctime, post.createdAt)).toBeLTE(2)
					expect(DateDiff("s", utctime, post.updatedAt)).toBeLTE(2)

					transaction action="rollback";
				}
			})

			it("local works", () => {
				transaction {
					localtime = Now();
					g.model("Post").getClass().timeStampMode = "local"
					author = g.model("Author").findOne()
					post = author.createPost(title = "test post", body = "here is some text")

					if (get("adapterName") == "SQLite") {
						// Store as quoted ISO 8601 string (standard for SQLite)
						if (IsDate(localtime)) {
							localtime = "#DateFormat(localtime, 'yyyy-mm-dd')# #TimeFormat(localtime, 'HH:mm:ss')#";
						}
						post.createdAt = replaceNoCase(post.createdAt, "'", "", "all");
						post.updatedAt = replaceNoCase(post.updatedAt, "'", "", "all");
					}
					expect(DateDiff("s", localtime, post.createdAt)).toBeLTE(2)
					expect(DateDiff("s", localtime, post.updatedAt)).toBeLTE(2)

					transaction action="rollback";
				}
			})

			it("epoch works", () => {
				transaction {
					epochtime = Now().getTime();
					g.model("Post").getClass().timeStampOnCreateProperty = "createdAtEpoch"
					g.model("Post").getClass().timeStampOnUpdateProperty = "updatedAtEpoch"
					g.model("Post").getClass().timeStampMode = "epoch"
					author = g.model("Author").findOne()
					post = author.createPost(title = "test post", body = "here is some text", createdAt = Now(), updatedAt = Now())

					expect(post.createdAtEpoch - epochtime).toBeLTE(2000)
					expect(post.updatedAtEpoch - epochtime).toBeLTE(2000)

					transaction action="rollback";
				}
			})

			it("updatedAt is not changed when no changes are made to model", () => {
				transaction {
					post = g.model("Post").findOne()
					orgUpdatedAt = post.properties().updatedAt
					post.update()
					post.reload()
					newUpdatedAt = post.properties().updatedAt
					if(isInstanceOf(orgUpdatedAt,"java.time.LocalDateTime") and isInstanceOf(newUpdatedAt,"java.time.LocalDateTime")){
						orgUpdatedAt = createDateTime(orgUpdatedAt.getYear(),orgUpdatedAt.getMonthValue(),orgUpdatedAt.getDayOfMonth(),orgUpdatedAt.getHour(),orgUpdatedAt.getMinute(),orgUpdatedAt.getSecond());
						newUpdatedAt = createDateTime(newUpdatedAt.getYear(),newUpdatedAt.getMonthValue(),newUpdatedAt.getDayOfMonth(),newUpdatedAt.getHour(),newUpdatedAt.getMinute(),newUpdatedAt.getSecond());
					} else if (isInstanceOf(orgUpdatedAt, "oracle.sql.TIMESTAMP") and isInstanceOf(newUpdatedAt, "oracle.sql.TIMESTAMP")){
						orgUpdatedAt = orgUpdatedAt.timestampValue();
						newUpdatedAt = newUpdatedAt.timestampValue();
					}
					expect(orgUpdatedAt).toBe(newUpdatedAt)

					transaction action="rollback";
				}
			})

			it("createdAt is not changed on update", () => {
				transaction {
					post = g.model("Post").findOne()
					orgCreatedAt = post.properties().createdAt
					post.update(body = "here is some updated text")
					post.reload()
					newCreatedAt = post.properties().createdAt
					if(isInstanceOf(orgUpdatedAt,"java.time.LocalDateTime") and isInstanceOf(newUpdatedAt,"java.time.LocalDateTime")){
						orgUpdatedAt = createDateTime(orgUpdatedAt.getYear(),orgUpdatedAt.getMonthValue(),orgUpdatedAt.getDayOfMonth(),orgUpdatedAt.getHour(),orgUpdatedAt.getMinute(),orgUpdatedAt.getSecond());
						newUpdatedAt = createDateTime(newUpdatedAt.getYear(),newUpdatedAt.getMonthValue(),newUpdatedAt.getDayOfMonth(),newUpdatedAt.getHour(),newUpdatedAt.getMinute(),newUpdatedAt.getSecond());
					} else if (isInstanceOf(orgUpdatedAt, "oracle.sql.TIMESTAMP") and isInstanceOf(newUpdatedAt, "oracle.sql.TIMESTAMP")){
						orgUpdatedAt = orgUpdatedAt.timestampValue();
						newUpdatedAt = newUpdatedAt.timestampValue();
					}
					expect(orgUpdatedAt).toBe(newUpdatedAt)
					
					transaction action="rollback";
				}
			})

			it("is respected on create when explicitly passed", () => {
				transaction {
					author = g.model("Author").findOne()
					post = author.createPost(
						title = "test_explicit_timestamps_are_respected test post",
						body = "here is some text",
						createdAt = CreateDate(1969, 4, 1),
						updatedAt = CreateDate(1970, 4, 1),
						allowExplicitTimestamps = true
					)

					expect(Year(post.createdAt)).toBe(1969)
					expect(Year(post.updatedAt)).toBe(1970)

					transaction action="rollback";
				}
			})

			it("is respected on update when explicitly passed", () => {
				transaction {
					author = g.model("Author").findOne()
					author.update(
						city = "Dateville",
						createdAt = CreateDate(1972, 4, 1),
						updatedAt = CreateDate(1974, 4, 1),
						allowExplicitTimestamps = true
					)

					expect(Year(author.createdAt)).toBe(1972)
					expect(Year(author.updatedAt)).toBe(1974)

					transaction action="rollback";
				}
			})

			it("requires allowexplicittimestamps on create for passing explicitly", () => {
				transaction {
					utctime = DateConvert("local2Utc", Now())
					author = g.model("Author").findOne()
					post = author.createPost(
						title = "test_default_timestamps test post",
						body = "here is some text",
						createdAt = CreateDate(1969, 4, 1),
						updatedAt = CreateDate(1970, 4, 1)
					)
					if (get("adapterName") == "SQLite") {
						// Store as quoted ISO 8601 string (standard for SQLite)
						if (IsDate(utctime)) {
							utctime = "#DateFormat(utctime, 'yyyy-mm-dd')# #TimeFormat(utctime, 'HH:mm:ss')#";
						}
						post.createdAt = replaceNoCase(post.createdAt, "'", "", "all");
						post.updatedAt = replaceNoCase(post.updatedAt, "'", "", "all");
					}

					expect(DateDiff("s", utctime, post.createdAt)).toBeLTE(2)
					expect(DateDiff("s", utctime, post.updatedAt)).toBeLTE(2)

					transaction action="rollback";
				}
			})
		})

		describe("Tests that toggle", () => {

			it("works with save", () => {
				_model = g.model("user").findOne(where = "firstName='Chris'")
				transaction action="begin" {
					saved = _model.toggle("isActive")
					transaction action="rollback";
				}

				expect(_model.isActive).toBeFalse()
				expect(saved).toBeTrue()
			})

			it("works without save", () => {
				_model = g.model("user").findOne(where = "firstName='Chris'")
				_model.toggle("isActive", false)

				expect(_model.isActive).toBeFalse()
			})

			it("works for dynamic methods with save", () => {
				_model = g.model("user").findOne(where = "firstName='Chris'")
				transaction action="begin" {
					saved = _model.toggleIsActive()
					transaction action="rollback";
				}

				expect(_model.isActive).toBeFalse()
				expect(saved).toBeTrue()
			})

			it("works for dynamic methods without save", () => {
				_model = g.model("user").findOne(where = "firstName='Chris'")
				_model.toggleIsActive(save = false)

				expect(_model.isActive).toBeFalse()
			})

			it("throws error for toggle property without save when not existing", () => {
				_model = g.model("user").findOne(where = "firstName='Chris'")

				expect(function() {
					_model.toggle("isMember", false)
				}).toThrow("Wheels.PropertyDoesNotExist")
			})

			it("throws error for toggle property without save when not boolean", () => {
				_model = g.model("user").findOne(where = "firstName='Chris'")

				expect(function() {
					_model.toggle("firstName", false)
				}).toThrow("Wheels.PropertyIsIncorrectType")
			})
		})
	}
}