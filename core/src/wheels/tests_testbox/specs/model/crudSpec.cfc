component extends="wheels.Testbox" {

	function run() {

		g = application.wo

		describe("Tests that binarydata", () => {

			beforeEach(() => {
				binaryData = FileReadBinary(ExpandPath('/wheels/tests_testbox/_assets/files/cfwheels-logo.png'))
				if( application.wheels.adapterName eq 'SQLite' ){
					binaryData = toBase64(binaryData)
				}
			})

			it("is updating", () => {
				transaction action="begin" {
					photo = g.model("photo").findOne()
					photo.update(filename = "somefilename", fileData = binaryData)
					photo = g.model("photo").findByKey(photo.id)
					_binary = photo.filedata
					transaction action="rollback";
				}

				expect(ToBinary(_binary)).toBeTypeOf("binary")
			})

			it("is inserting", () => {
				gallery = g.model("gallery").findOne(include = "user", where = "c_o_r_e_users.lastname = 'Petruzzi'", order = "id")
				transaction action="begin" {
					photo = g.model("photo").create(
						galleryid = "#gallery.id#",
						filename = "somefilename",
						fileData = binaryData,
						description1 = "something something"
					)
					photo = g.model("photo").findByKey(photo.id)
					_binary = photo.filedata
					transaction action="rollback";
				}

				expect(ToBinary(_binary)).toBeTypeOf("binary")
			})
		})

		describe("Tests that changes", () => {

			it("is clearing all change info", () => {
				author = g.model("author").findOne(select = "firstName");
				author.firstName = "asfdg9876asdgf"
				author.lastName = "asfdg9876asdgf"
				result = author.hasChanged()

				expect(result).toBeTrue()

				author.clearChangeInformation()
				result = author.hasChanged()

				expect(result).toBeFalse()
			})

			it("is clearing property change info", () => {
				author = g.model("author").findOne(select = "firstName");
				author.firstName = "asfdg9876asdgf"
				author.lastName = "asfdg9876asdgf"
				result = author.hasChanged(property = "firstName")

				expect(result).toBeTrue()

				result = author.hasChanged(property = "lastName")

				expect(result).toBeTrue()

				author.clearChangeInformation(property = "firstName")
				result = author.hasChanged(property = "firstName")

				expect(result).toBeFalse()

				result = author.hasChanged(property = "lastName")

				expect(result).toBeTrue()
			})

			it("is comparing existing properties only", () => {
				author = g.model("author").findOne(select = "firstName");
				result = author.hasChanged()

				expect(result).toBeFalse()

				result = author.hasChanged("firstName")

				expect(result).toBeFalse()

				author = g.model("author").findOne()
				StructDelete(author, "firstName")
				result = author.hasChanged()

				expect(result).toBeFalse()

				result = author.hasChanged("firstName")

				expect(result).toBeFalse()

				result = author.hasChanged("somethingThatDoesNotExist")

				expect(result).toBeFalse()
			})

			it("function allChanges is working", () => {
				author = g.model("author").findOne(order = "id");
				author.firstName = "a"
				author.lastName = "b"
				compareWith.firstName.changedFrom = "Per"
				compareWith.firstName.changedTo = "a"
				compareWith.lastName.changedFrom = "Djurner"
				compareWith.lastName.changedTo = "b"
				result = author.allChanges()

				expect(result.toString()).toBe(compareWith.toString())
			})

			it("function changedProperties is working", () => {
				author = g.model("author").findOne();
				author.firstName = "a"
				author.lastName = "b"
				result = ListSort(author.changedProperties(), "textnocase")

				expect(result).toBe("firstName,lastName")
			})

			it("function changedProperties without changes is working", () => {
				author = g.model("author").findOne();
				result = author.changedProperties()

				expect(result).toBe("")
			})

			it("function changedProperties change and back is working", () => {
				author = g.model("author").findOne();
				author.oldFirstName = author.firstName
				author.firstName = "a"
				result = author.changedProperties()

				expect(result).toBe("firstName")

				author.firstName = author.oldFirstName
				result = author.changedProperties()

				expect(result).toBe("")
			})

			it("function isNew is working", () => {
				transaction {
					author = g.model("author").new(firstName = "Per", lastName = "Djurner")
					result = author.isNew()

					expect(result).toBeTrue()

					author.save(transaction = "none")
					result = author.isNew()

					expect(result).toBeFalse()
					transaction action="rollback";
				}
			})

			it("function isNew with find is working", () => {
				author = g.model("author").findOne();
				result = author.isNew()

				expect(result).toBeFalse()
			})

			it("function isPersisted is working", () => {
				transaction {
					author = g.model("author").new(firstName = "Per", lastName = "Djurner")
					result = author.isPersisted()

					expect(result).toBeFalse()
					
					author.save(transaction = "none")
					result = author.isPersisted()
					
					expect(result).toBeTrue()

					transaction action="rollback";
				}
			})

			it("function isPersisted with find is working", () => {
				author = g.model("author").findOne();
				result = author.isPersisted()

				expect(result).toBeTrue()
			})

			it("function hasChanged is working", () => {
				author = g.model("author").findOne(where = "lastName = 'Djurner'")
				result = author.hasChanged()

				expect(result).toBeFalse()

				author.lastName = "Petruzzi"
				result = author.hasChanged()

				expect(result).toBeTrue()
				
				author.lastName = "Djurner"
				result = author.hasChanged()

				expect(result).toBeFalse()
			})

			it("function hasChanged with new is working", () => {
				transaction {
					author = g.model("author").new()
					result = author.hasChanged()

					expect(result).toBeTrue()

					author.firstName = "Per"
					author.lastName = "Djurner"
					author.save(transaction = "none")
					result = author.hasChanged()

					expect(result).toBeFalse()

					author.lastName = "Petruzzi"
					result = author.hasChanged()

					expect(result).toBeTrue()

					author.save(transaction = "none")
					result = author.hasChanged()

					expect(result).toBeFalse()
					
					transaction action="rollback";
				}
			})

			it("function XXXHasChanged is working", () => {
				author = g.model("author").findOne(where = "lastName = 'Djurner'")
				author.lastName = "Petruzzi"
				result = author.lastNameHasChanged()

				expect(result).toBeTrue()

				result = author.firstNameHasChanged()

				expect(result).toBeFalse()
			})

			it("function changedFrom is working", () => {
				author = g.model("author").findOne(where = "lastName = 'Djurner'")
				author.lastName = "Petruzzi"
				result = author.changedFrom(property = "lastName")
				
				expect(result).toBe("Djurner")
			})

			it("function XXXChangedFrom is working", () => {
				author = g.model("author").findOne(where = "lastName = 'Djurner'")
				author.lastName = "Petruzzi"
				result = author.lastNameChangedFrom(property = "lastName")
				
				expect(result).toBe("Djurner")
			})

			it("function hasChanged is working with date compare", () => {
				user = g.model("user").findOne(where = "username = 'tonyp'")
				if (structKeyExists(server, "boxlang")) {
					user.birthday = createDateTime("1975", "11", "01", "00", "00", "00")
				} else {
					user.birthday = "11/01/1975 12:00 AM"
				}
				
				e = user.hasChanged("birthday")

				expect(e).toBeFalse()
			})

			it("function hasChanged is working with binary compare", () => {
				transaction {
					photo = g.model("photo").findOne(order = g.model("photo").primaryKey())

					expect(photo.hasChanged('fileData')).toBeFalse()

					binaryData = FileReadBinary(ExpandPath('/wheels/tests_testbox/_assets/files/cfwheels-logo.png'))
					if( application.wheels.adapterName eq 'SQLite' ){
						binaryData = toBase64(binaryData)
					}
					photo.fileData = binaryData

					expect(photo.hasChanged('fileData')).toBeTrue()

					photo.galleryid = 99
					photo.save()

					expect(photo.hasChanged('fileData')).toBeFalse()

					photo = g.model("photo").findOne(where = "galleryid=99")

					expect(photo.hasChanged('fileData')).toBeFalse()

					binaryData = FileReadBinary(ExpandPath('/wheels/tests_testbox/_assets/files/cfwheels-logo.txt'))
					if( application.wheels.adapterName eq 'SQLite' ){
						binaryData = toBase64(binaryData)
					}
					photo.fileData = binaryData

					expect(photo.hasChanged('fileData')).toBeTrue()

					transaction action="rollback";
				}
			})

			it("function hasChanged is working with float compare", () => {
				transaction {
					post = g.model("post").findByKey(2)
					post.averagerating = 3.0000
					post.save(reload = true)
					post.averagerating = "3.0000"
					changed = post.hasChanged("averagerating")

					expect(changed).toBeFalse()
					transaction action="rollback";
				}
			})
		})

		describe("Tests that create", () => {

			beforeEach(() => {
				results = {}
			})

			it("is saving null strings", () => {
				transaction {
					results.author = g.model("author").create(firstName = "Null", lastName = "Null")

					expect(results.author).toBeInstanceOf("author")

					transaction action="rollback";
				}
			})

			it("is setting auto incrementing primary key", () => {
				transaction {
					results.author = g.model("author").create(firstName = "Test", lastName = "Test")

					expect(results.author).toBeInstanceOf("author")
					expect(results.author).toHaveKey(results.author.primaryKey())
					expect(results.author[results.author.primaryKey()]).toBeTypeOf("numeric")

					transaction action="rollback";
				}
			})

			it("should not change non auto incrementing primary key", () => {
				transaction {
					results.shop = g.model("shop").create(ShopId = 99, CityCode = 99, Name = "Test")

					expect(results.shop).toBeInstanceOf("shop")
					expect(results.shop).toHaveKey(results.shop.primaryKey())
					expect(results.shop[results.shop.primaryKey()]).toBe(99)
					
					transaction action="rollback";
				}
			})

			it("should set composite key values when they both exist", () => {
				transaction {
					results.city = g.model("city").create(citycode = 99, id = "z", name = "test")

					expect(results.city.citycode).toBe(99)
					expect(results.city.id).toBe("z")

					transaction action="rollback";
				}
			})

			it("should allow for blank string during create for columns that are not null", () => {
				info = g.$dbinfo(datasource = application.wheels.dataSourceName, type = "version")
				db = LCase(Replace(info.database_productname, " ", "", "all"))
				author = g.model("author").create(firstName = "Test", lastName = " ", transaction = "rollback")

				expect(author).toBeInstanceOf("author")
				expect(trim(author.lastName)).toHaveLength(0)
			})

			it("should not throw error when saving a new model without properties", () => {
				transaction action="begin" {
					model = g.model("tag").new()

					$assert.notThrows(function() {
						model.save(reload=true)
					})

					transaction action="rollback";
				}
			})

			it("overrides created at with allow explicit timestamps", () => {
				author = g.model("author").findOne(order = "id")

				transaction {
					twentyDaysAgo = DateAdd("d", -20, Now())

					newPost = g.model("post").create(
						authorId = author.id,
						title = "New title",
						body = "New Body",
						createdAt = twentyDaysAgo,
						updatedAt = twentyDaysAgo,
						transaction = "none",
						allowExplicitTimestamps = true
					)

					expect(newPost.createdAt).toBe(twentyDaysAgo)

					transaction action="rollback";
				}
			})

			it("overrides updated at with allow explicit timestamps", () => {
				author = g.model("author").findOne(order = "id")

				transaction {
					twentyDaysAgo = DateAdd("d", -20, Now())

					newPost = g.model("post").create(
						authorId = author.id,
						title = "New title",
						body = "New Body",
						createdAt = twentyDaysAgo,
						updatedAt = twentyDaysAgo,
						transaction = "none",
						allowExplicitTimestamps = true
					)

					expect(newPost.updatedAt).toBe(twentyDaysAgo)

					transaction action="rollback";
				}
			})
		})

		describe("Tests that findall", () => {

			beforeEach(() => {
				source = g.model("user").findAll(select = "id,lastName", maxRows = 3)
			})

			it("includes column names for paginated finder calls with no records", () => {
				q = g.model("user").findAll(select = "id, firstName", where = "id = -1", page = 1, perPage = 10)

				expect(ListSort(q.columnList, "text")).toBe("FIRSTNAME,ID")
			})

			it("should break cache when maxrows is changed", () => {
				$cacheQueries = application.wheels.cacheQueries
				application.wheels.cacheQueries = true
				q = g.model("user").findAll(maxrows = 1, cache = 10)

				expect(q.recordCount).toBe(1)

				q = g.model("user").findAll(maxrows = 2, cache = 10)

				expect(q.recordCount).toBe(2)

				application.wheels.cacheQueries = $cacheQueries
			})

			it("works with IN operator with quoted strings", () => {
                if (structKeyExists(server, "boxlang")) {
                    values = ListQualify(ValueList(source.lastName), "'")
                } else {
                    values = QuotedValueList(source.lastName)
                }
				q = g.model("user").findAll(where = "lastName IN (#values#)")

				expect(q.recordCount).toBe(3)
			})

			it("works with IN operator with numbers", () => {
				values = ValueList(source.id)
				q = g.model("user").findAll(where = "id IN (#values#)")

				expect(q.recordCount).toBe(3)
			})

			it("works with custom query and orm query in transaction", () => {
				transaction {
					actual = g.model("user").findAll(select = "id")
					expected = g.$query(datasource = application.wheels.dataSourceName, sql = "SELECT id FROM c_o_r_e_users")
				}

				expect(actual.recordCount).toBe(expected.recordCount)
			})

			it("works with IN operator wih spaces", () => {
				authors = g.model("author").findAll(
					where = ArrayToList(
						["id != 0", "id IN (1, 2, 3)", "firstName IN ('Per', 'Tony')", "lastName IN ('Djurner', 'Petruzzi')"],
						" AND "
					)
				)

				expect(authors.recordCount).toBe(2)
			})

			it("works with IN operator with spaces and equals comma value combo with brackets", () => {
				authors = g.model("author").findAll(
					where = ArrayToList(["id IN (8)", "(lastName = 'Chapman, Duke of Surrey')"], " AND ")
				)

				expect(authors.recordCount).toBe(1)
			})

			it("is moving aggregate functions in where to having", () => {
				results1 = g.model("user").findAll(
					select = "state, salesTotal",
					group = "state",
					where = "salesTotal > 10",
					order = "salesTotal DESC"
				)
				expect(results1.RecordCount).toBe(2)
				expect(results1['salesTotal'][1]).toBe(20)

				results2 = g.model("user").findAll(
					select = "state, salesTotal",
					group = "state",
					where = "username <> 'perd' AND salesTotal > 10",
					order = "salesTotal DESC"
				)
				expect(results2.RecordCount).toBe(2)
				expect(results2['salesTotal'][1]).toBe(11)

				results3 = g.model("user").findAll(select = "state, salesTotal", group = "state", where = "salesTotal < 10")
				expect(results3.RecordCount).toBe(1)
				expect(results3['salesTotal'][1]).toBe(6)
			})

			it("is working with uppercase table name containing or substring", () => {
				actual = g.model("category").findAll(where = "c_o_r_e_CATEGORIES.ID > 0")

				expect(actual.recordCount).toBe(2)
			})

			it("is converting handle to allowed variable", () => {
				actual = g.model("author").findAll(handle = "dot.notation test")

				expect(actual.recordCount).toBe(10)
			})

			it("is working with returnas SQL", () => {
				actual = g.model("author").findAll(select = "id", returnAs = "sql")
				// remove line breaks
				actual = ReplaceList(actual, "#Chr(13)#,#Chr(10)#", " , ")
				// remove double spaces
				actual = ReplaceList(actual, "  ", " ", "all")
				// trim extra whitespace
				actual = Trim(actual)

				expected = "SELECT c_o_r_e_authors.id FROM c_o_r_e_authors"

				expect(actual).toBe(expected)
			})

			it("is selecting calculated property when implicitly selecting fields", () => {
				posts = g.model("Post").findAll(select="c_o_r_e_posts.id,c_o_r_e_posts.title,c_o_r_e_posts.authorid,c_o_r_e_comments.id AS commentid,c_o_r_e_comments.name,titleAlias", include="c_o_r_e_comments")

				expect(isDefined("posts.titleAlias")).toBeTrue()
			})

			it("is selecting ambiguous column name using alias", () => {
				loc.query = g.model("Post").findAll(select="createdat,c_o_r_e_commentcreatedat,c_o_r_e_commentbody", include="c_o_r_e_comments")
	    		loc.columnList = ListSort(loc.query.columnList, "text")

				info = g.$dbinfo(datasource = application.wheels.dataSourceName, type = "version")
				db = LCase(Replace(info.database_productname, " ", "", "all"))

	    		// BoxLang compatibility: ListSort behaves differently in BoxLang
	    		if (StructKeyExists(server, "boxlang") && db != "oracle") {
	    			expect(loc.columnList).toBe("c_o_r_e_commentbody,c_o_r_e_commentcreatedat,createdat")
	    		} else {
	    			expect(loc.columnList).toBe("createdat,c_o_r_e_commentbody,c_o_r_e_commentcreatedat")
	    		}
			})
		})

		describe("Tests that finders", () => {

			beforeEach(() => {
				user = g.model("user")
				shop = g.model("shop")
				isACF2016 = application.wheels.serverName == "Adobe Coldfusion" && application.wheels.serverVersionMajor == 2016
				isACF2018 = application.wheels.serverName == "Adobe Coldfusion" && application.wheels.serverVersionMajor == 2018
				isACF2021 = application.wheels.serverName == "Adobe Coldfusion" && application.wheels.serverVersionMajor == 2021
				isACF2023 = application.wheels.serverName == "Adobe Coldfusion" && application.wheels.serverVersionMajor == 2023
				isACF2025 = application.wheels.serverName == "Adobe Coldfusion" && application.wheels.serverVersionMajor == 2025
			})

			it("is selecting distinct addresses", () => {
				q = user.findAll(select = "address", distinct = "true", order = "address")

				expect(q.recordcount).toBe(4)

				e = "123 Petruzzi St.|456 Peters Dr.|789 Djurner Ave.|987 Riera Blvd."
				r = ValueList(q.address, "|")

				expect(e).toBe(r)
			})

			it("is selecting users groupby addresses", () => {
				q = user.findAll(select = "address", group = "address", order = "address", result = "result")

				expect(q.recordcount).toBe(4)

				e = "123 Petruzzi St.|456 Peters Dr.|789 Djurner Ave.|987 Riera Blvd."
				r = ValueList(q.address, "|")

				expect(e).toBe(r)
			})

			it("function findByKey works", () => {
				e = user.findOne(where = "lastname = 'Petruzzi'")
				q = user.findByKey(e.id)

				expect(q.id).toBe(e.id)
			})

			it("function findByKey returns object when key has leading space", () => {
				e = shop.findByKey(" shop6")

				expect(e).toBeInstanceOf("shop")
			})

			it("function findByKey returns false when record not found", () => {
				q = user.findByKey(999999999)

				expect(q).toBeFalse()
			})

			it("function findByKey returns false when passed blank string", () => {
				q = user.findByKey("")
				expect(q).toBeFalse()
			})

			it("function findByKey returns empty query when record not found with return as equal query", () => {
				q = user.findByKey(key = 999999999, returnAs = "query")

				expect(q.recordcount).toBeFalse()
			})

			it("function findByKey returns empty array when record not found with return as equal array", () => {
				q = user.findByKey(key = 999999999, returnAs = "array")

				expect(q).toBeArray()
				expect(arrayLen(q)).toBe(0)
			})

			it("function findByKey returns empty struct when record not found with return as equal struct", () => {
				q = user.findByKey(key = 999999999, returnAs = "struct")

				expect(q).toBeStruct()
				expect(structIsEmpty(q)).toBeTrue()
			})

			it("function findByKey returns SQL when record not found with return as equal sql", () => {
				q = user.findByKey(key = 999999999, returnAs = "sql")

				expect(q).toBeString()
				expect(q).toInclude("SELECT")
			})

			it("function findByKey returns empty object when record not found with return as equal object", () => {
				q = user.findByKey(key = 999999999, returnAs = "object")

				expect(q).toBeFalse()
			})


			it("function findOne works", () => {
				e = user.findOne(where = "lastname = 'Petruzzi'")

				expect(e).toBeInstanceOf("user")
			})

			it("function findOne returns false when record not found", () => {
				e = user.findOne(where = "lastname = 'somenamenotfound'")

				expect(e).toBeFalse()
			})

			it("function findOne returns empty query when record not found with return as equal query", () => {
				e = user.findOne(where = "lastname = 'somenamenotfound'", returnAs = "query")

				expect(e.recordCount).toBeFalse()
			})

			it("function findOne returns empty array when record not found with return as equal array", () => {
				e = user.findOne(where = "lastname = 'somenamenotfound'", returnAs = "array")

				expect(e).toBeArray()
				expect(arrayLen(e)).toBe(0)
			})

			it("function findOne returns empty struct when record not found with return as equal struct", () => {
				e = user.findOne(where = "lastname = 'somenamenotfound'", returnAs = "struct")

				expect(e).toBeStruct()
				expect(structIsEmpty(e)).toBeTrue()
			})

			it("function findOne returns SQL string when record not found with return as equal sql", () => {
				e = user.findOne(where = "lastname = 'somenamenotfound'", returnAs = "sql")

				expect(e).toBeString()
				expect(e).toInclude("SELECT") // SQL is returned regardless of record presence
			})

			it("function findOne returns null when record not found with return as equal object", () => {
				e = user.findOne(where = "lastname = 'somenamenotfound'", returnAs = "object")

				expect(e).toBeFalse()
			})

			it("function findOne returns false when record not found with inner join include", () => {
				e = user.findOne(where = "lastname = 'somenamenotfound'", include = "galleries")

				expect(e).toBeFalse()
			})

			it("function findOne returns false when record not found with outer join include", () => {
				e = user.findOne(where = "lastname = 'somenamenotfound'", include = "outerjoinphotogalleries")

				expect(e).toBeFalse()
			})

			it("function findAll works", () => {
				q = user.findAll()

				expect(q.recordcount).toBe(5)

				q = user.findAll(where = "lastname = 'Petruzzi' OR lastname = 'Peters'", order = "lastname")

				expect(q.recordcount).toBe(2)
				expect(valuelist(q.lastname)).toBe("peters,Petruzzi")
			})

			it("function findAllByXXX works", () => {
				q = user.findAllByZipcode(value = "22222", order = "id")

				expect(q.recordcount).toBe(2)

				q = user.findAllByZipcode(value = "11111", order = "id")

				expect(q.recordcount).toBe(1)

				q = user.findAllByZipcode(zipCode = "11111")

				expect(q.recordcount).toBe(1)

				q = user.findAllByZipcode("11111")

				expect(q.recordcount).toBe(1)

				q = user.findAllByZipcodeAndBirthDayMonth(values = "22222,11")

				expect(q.recordcount).toBe(1)

				q = user.findAllByZipcodeAndBirthDayMonth(zipCode = "22222", birthDayMonth = "11")

				expect(q.recordcount).toBe(1)
			})

			it("function findByKey returns correct type when no records", () => {
				q = user.findByKey("0")
				
				expect(q).toBeBoolean()
				expect(q).toBeFalse()

				q = user.findByKey(key = "0", returnas = "query")
				
				expect(q).toBeQuery()
				expect(q.recordcount).toBe(0)

				q = user.findByKey(key = "0", returnas = "object")
				
				expect(q).toBeBoolean()
				expect(q).toBeFalse()

				q = user.findByKey(key = "0", returnas = "struct")
				
				expect(q).toBeStruct()
				expect(q).toBeEmpty()

				q = user.findByKey(key = "0", returnas = "array")
				
				expect(q).toBeArray()
				expect(q).toBeEmpty()

				/* readd when we have implemented the code to throw an error when an incorrect returnAs value is passed in
				q = raised('user.findByKey(key="0", returnas="objects")')
				r = "Wheels.IncorrectArgumentValue"
				debug('q', false)
				assert('q eq r') */
			})

			it("function findOne returns correct type when no records", () => {
				q = user.findOne(where = "id = 0")

				expect(q).toBeBoolean()
				expect(q).toBeFalse()

				q = user.findOne(where = "id = 0", returnas = "query")

				expect(q).toBeQuery()
				expect(q.recordcount).toBe(0)

				q = user.findOne(where = "id = 0", returnas = "object")

				expect(q).toBeBoolean()
				expect(q).toBeFalse()

				q = user.findOne(where = "id = 0", returnas = "struct")

				expect(q).toBeStruct()
				expect(q).toBeEmpty()

				q = user.findOne(where = "id = 0", returnas = "array")

				expect(q).toBeArray()
				expect(q).toBeEmpty()

				/* readd when we have implemented the code to throw an error when an incorrect returnAs value is passed in
				q = raised('user.findOne(where="id = 0", returnas="objects")')
				r = "Wheels.IncorrectArgumentValue"
				debug('q', false)
				assert('q eq r') */
			})

			it("function findAll returns correct type when returnAs is query when no records", () => {
				q = user.findAll(where = "id = 0", returnas = "query")

				expect(q).toBeQuery()
				expect(q.recordcount).toBe(0)
			})

			it("function findAll returns correct type when returnAs is struct when no records", () => {
				q = user.findAll(where = "id = 0", returnas = "structs")

				expect(q).toBeStruct()
				expect(q).toBeEmpty()
			})

			it("function findAll returns correct type when returnAs is array when no records", () => {
				q = user.findAll(where = "id = 0", returnas = "array")

				expect(q).toBeArray()
				expect(q).toBeEmpty()
			})

			it("function findAll returns correct type when returnAs is objects when no records", () => {
				q = user.findAll(where = "id = 0", returnas = "object")

				expect(q).toBeArray()
				expect(q).toBeEmpty()
			})

			it("throws error when findAll returnAs is invalid", () => {
				expect(() => {
					user.findAll(where="id = 1", returnas="notvalid")
				}).toThrow("Wheels.IncorrectArgumentValue")
			})

			it("function findAll supports inbuilt returnType", () => {
				// returnType wasn't supported until ACF2021
				if (isACF2016 || isACF2018) {
					return
				}
				actual = user.findAll(returnType = "struct", keyColumn = "id")

				expect(actual).toBeStruct()

				if (isACF2021 || isACF2023 || isACF2025) {
					expect(actual.resultset['1']).toBeStruct()
				} else if (structKeyExists(server, "boxlang")) {
					expect(actual['1']['1']).toBeStruct()
				} else {
					expect(actual['1']).toBeStruct()
				}
			})

			it("function findAll inbuilt returnType takes precedence over returnAs", () => {
				if (isACF2016 || isACF2018) {
					return
				}
				actual = user.findAll(returnType = "array", returnAs = "query")

				expect(actual).toBeArray()
			})

			it("function exists for valid key", () => {
				e = user.findOne(where = "lastname = 'Petruzzi'")
				r = user.exists(e.id)

				expect(r).toBeTrue()
			})

			it("function exists for invalid key", () => {
				r = user.exists(0)

				expect(r).toBeFalse()
			})

			it("function exists when one record is valid", () => {
				r = user.exists(where = "lastname = 'Petruzzi'")

				expect(r).toBeTrue()
			})

			it("function exists when one record is invalid", () => {
				r = user.exists(where = "lastname = 'someoneelse'")

				expect(r).toBeFalse()
			})

			it("function exists when two records is valid", () => {
				r = user.exists(where = "zipcode = '22222'")

				expect(r).toBeTrue()
			})

			it("function exists for any record", () => {
				r = user.exists()

				expect(r).toBeTrue()
			})

			it("function exists for no records", () => {
				transaction action="begin" {
					user.deleteAll()
					r = user.exists()
					transaction action="rollback";
				}

				expect(r).toBeFalse()
			})

			it("function exists allows negative values in where clause", () => {
				r = user.exists(where = "id = -1")

				expect(r).toBeFalse()
			})

			it("function findByKey with include soft deletes", () => {
				transaction action="begin" {
					post1 = g.model("Post").findOne()
					post1.delete(transaction = "none")
					post2 = g.model("Post").findByKey(key = post1.id, includeSoftDeletes = true)
					transaction action="rollback";
				}

				expect(post2).toBeInstanceOf("post")
			})

			it("function findOne with include soft deletes", () => {
				transaction action="begin" {
					post1 = g.model("Post").findOne()
					post1.delete(transaction = "none")
					post2 = g.model("Post").findOne(where = "id=#post1.id#", includeSoftDeletes = true)
					transaction action="rollback";
				}

				expect(post2).toBeInstanceOf("post")
			})

			it("function findAll with include soft deletes", () => {
				transaction action="begin" {
					g.model("Post").deleteAll()
					allPosts = g.model("Post").findAll(includeSoftDeletes = true)
					transaction action="rollback";
				}

				expect(allPosts.recordcount).toBe(5)
			})

			it("function findOne returns empty array for included model when none exist", () => {
				e = g.model("author").findOne(where = "lastname = 'Bellenie'", include = "posts")

				expect(e.posts).toBeArray()
				expect(e.posts).toBeEmpty()
			})

			it("function findAll with softdeleted associated rows", () => {
				transaction action="begin" {
					g.model("Post").deleteAll()
					posts = g.model("Author").findByKey(key = 1, include = "Posts", returnAs = "query")
					transaction action="rollback";
				}

				expect(posts.recordcount).toBe(1)
			})
		})

		describe("Tests that findOne", () => {

			beforeEach(() => {
				tagModel = g.model("tag")
				postModel = g.model("post")
			})

			it("should clear request query cache after change", () => {
				local.oldCacheQueriesDuringRequest = application.wheels.cacheQueriesDuringRequest
				application.wheels.cacheQueriesDuringRequest = true

				transaction action="begin" {
					authorBefore = g.model("author").findByKey(1)
					authorBefore.update(lastName = "D")
					authorAfter = g.model("author").findByKey(1)
					transaction action="rollback";
				}
				
				expect(authorAfter.lastName).toBe("D")

				application.wheels.cacheQueriesDuringRequest = local.oldCacheQueriesDuringRequest
			})

			it("should self join", () => {
				tag = tagModel.findOne(where = "name = 'pear'", include = "parent", order = "id, id")

				expect(tag).toBeInstanceOf("tag")
				expect(tag.parent).toBeInstanceOf("tag")
			})

			it("should self join with other associations", () => {
				post = postModel.findByKey(key = 1, include = "classifications(tag(parent))", returnAs = "query")

				expect(post).toBeQuery()
				expect(post.recordcount).toBeGT(0)
			})

			it("does not use query param for nulls", () => {
				result = g.model("author").findOne(where = "lastName IS NULL")

				expect(result).toBeFalse()
				
				result = g.model("author").findOne(where = "lastName IS NOT NULL")
				
				expect(result).toBeInstanceOf("author")
			})

			it("is parsing number in where", () => {
				result = g.model("author").findOne(where = "firstName = 1")

				expect(result).toBeFalse()

				result = g.model("author").findOne(where = "firstName = 1.0")

				expect(result).toBeFalse()

				result = g.model("author").findOne(where = "firstName = +1")

				expect(result).toBeFalse()

				result = g.model("author").findOne(where = "firstName = -1")

				expect(result).toBeFalse()

			})
		})

		describe("Tests that findOneByXXX", () => {

			beforeEach(() => {
				results = {}
			})

			it("works with one value", () => {
				results.user = g.model("user").findOneByFirstname('Per')

				expect(results.user).toBeInstanceOf("user")
			})

			it("works with explicit arguments", () => {
				results.user = g.model("user").findOneByZipCode(value = "22222", select = "id,lastName,zipCode", order = "id")

				expect(results.user).toBeInstanceOf("user")
				expect(results.user.lastName).toBe("Peters")
				expect(results.user).notToHaveKey('firstName')
			})

			it("works with pass through order", () => {
				results.user = g.model("user").findOneByIsActive(value = "1", order = "zipCode DESC")

				expect(results.user).toBeInstanceOf("user")
				expect(results.user.lastName).toBe("Riera")
			})

			it("works with two values", () => {
				results.user = g.model("user").findOneByFirstNameAndLastName("Per,Djurner")

				expect(results.user).toBeInstanceOf("user")
				expect(results.user.lastName).toBe("Djurner")
			})

			it("works with two values with named arguments", () => {
				results.user = g.model("user").findOneByFirstNameAndLastName(firstName = "Per", lastName = "Djurner")

				expect(results.user).toBeInstanceOf("user")
				expect(results.user.lastName).toBe("Djurner")
			})

			it("works with two values with space", () => {
				results.user = g.model("user").findOneByFirstNameAndLastName("Per, Djurner")

				expect(results.user).toBeInstanceOf("user")
				expect(results.user.lastName).toBe("Djurner")
			})

			it("works with two values with explicit arguments", () => {
				results.user = g.model("user").findOneByFirstNameAndLastName(values = "Per,Djurner")

				expect(results.user).toBeInstanceOf("user")
				expect(results.user.lastName).toBe("Djurner")
			})

			it("works with text data type", () => {
				results.profile = g.model("profile").findOneByBio("ColdFusion Developer")

				expect(results.profile).toBeInstanceOf("profile")
			})

			it("works with unlimited properties for dynamic finders", () => {
				post = g.model("Post").findOneByTitleAndAuthoridAndViews(values = "Title for first test post|1|5", delimiter = "|")

				expect(post).toBeInstanceOf("post")
			})

			it("is passing array", () => {
				args = ["Title for first test post", 1, 5]
				post = g.model("Post").findOneByTitleAndAuthoridAndViews(values = args)

				expect(post).toBeInstanceOf("post")
			})

			it("can change delimiter for dynamic finders", () => {
				title = "Testing to make, to make sure, commas work"
				transaction action="begin" {
					post = g.model("Post").findOne(where = "id = 1")
					post.title = title
					post.save()
					post = g.model("Post").findOneByTitleAndAuthorid(values = "#title#|1", delimiter = "|")
					transaction action="rollback";
				}

				expect(post).toBeInstanceOf("post")
			})

			it("is passing where clause", () => {
				post = g.model("Post").findOneByTitle(value = "Title for first test post", where = "authorid = 1 AND views = 5")

				expect(post).toBeInstanceOf("post")
			})

			it("can pass in commas", () => {
				title = "Testing to make, to make sure, commas work"
				transaction action="begin" {
					post = g.model("Post").findOne(where = "id = 1")
					post.title = title
					post.save()
					post = g.model("Post").findOneByTitle(values = "#title#")
					transaction action="rollback";
				}

				expect(post).toBeInstanceOf("post")
			})
		})

		describe("Tests that $fromClause", () => {

			it("is working", () => {
				result = g.model("author").$fromClause(include = "")

				expect(result).toBe("FROM c_o_r_e_authors")
			})

			it("is working with mapped table", () => {
				g.model("author").table("tbl_authors")
				result = g.model("author").$fromClause(include = "")
				g.model("author").table("c_o_r_e_authors")

				expect(result).toBe("FROM tbl_authors")
			})

			it("is working with include", () => {
				result = g.model("author").$fromClause(include = "posts")

				expect(result).toBe("FROM c_o_r_e_authors LEFT OUTER JOIN c_o_r_e_posts ON c_o_r_e_authors.id = c_o_r_e_posts.authorid AND c_o_r_e_posts.deletedat IS NULL")
			})

			it("$indexHint", () => {
				actual = g.model("author").$indexHint(
					useIndex = {author = "idx_authors_123"},
					modelName = "author",
					adapterName = "MySQL"
				)

				expect(actual).toBe("USE INDEX(idx_authors_123)")
			})

			it("is working with index hint mysql", () => {
				actual = g.model("author").$fromClause(include = "", useIndex = {author = "idx_authors_123"}, adapterName = "MySQL")

				expect(actual).toBe("FROM c_o_r_e_authors USE INDEX(idx_authors_123)")
			})

			it("is working with index hint sqlserver", () => {
				actual = g.model("author").$fromClause(include = "", useIndex = {author = "idx_authors_123"}, adapterName = "SQLServer")

				expect(actual).toBe("FROM c_o_r_e_authors WITH (INDEX(idx_authors_123))")
			})

			it("is working with index hint on unsupportive db", () => {
				actual = g.model("author").$fromClause(
					include = "",
					useIndex = {author = "idx_authors_123"},
					adapterName = "PostgreSQL"
				)

				expect(actual).toBe("FROM c_o_r_e_authors")
			})

			it("is working with include and index hints", () => {
				actual = g.model("author").$fromClause(
					include = "posts",
					useIndex = {author = "idx_authors_123", post = "idx_posts_123"},
					adapterName = "MySQL"
				)

				expect(actual).toBe("FROM c_o_r_e_authors USE INDEX(idx_authors_123) LEFT OUTER JOIN c_o_r_e_posts USE INDEX(idx_posts_123) ON c_o_r_e_authors.id = c_o_r_e_posts.authorid AND c_o_r_e_posts.deletedat IS NULL")
			})
		})

		describe("Tests that group", () => {

			it("is working simple", () => {
				r = g.model("tag").findAll(select = "parentId, COUNT(*) AS groupCount", group = "parentId")

				expect(r.recordcount).toBe(4)
			})

			it("is working in calculated property", () => {
				r = g.model("user2").findAll(select = "firstLetter, groupCount", group = "firstLetter", order = "groupCount DESC")

				expect(r.recordcount).toBe(2)
			})

			it("is working with distinct", () => {
				r = g.model("post").findAll(select = "views", distinct = true)

				expect(r.recordcount).toBe(4)

				r = g.model("post").findAll(select = "views", group = "views")

				expect(r.recordcount).toBe(4)
			})

			it("is working with max", () => {
				r = g.model("post").findAll(
					select = "id, authorid, title, MAX(c_o_r_e_posts.views) AS maxView",
					group = "id, authorid, title"
				)

				expect(r.recordcount).toBe(5)
			})

			it("is working with pagination", () => {
				r = g.model("post").findAll(
					select = "id, authorid, title, MAX(c_o_r_e_posts.views) AS maxView",
					group = "id, authorid, title",
					page = 1,
					perPage = 2
				)

				expect(r.recordcount).toBe(2)
			})
		})

		describe("Tests that new", () => {

			it("is overriding created at with allow explicit timestamps", () => {
				author = g.model("author").findOne(order = "id")

				transaction {
					twentyDaysAgo = DateAdd("d", -20, Now())

					newPost = g.model("post").new(allowExplicitTimestamps = true)
					newPost.authorId = author.id
					newPost.title = "New title"
					newPost.body = "New Body"
					newPost.createdAt = twentyDaysAgo
					newPost.updatedAt = twentyDaysAgo

					newPost.save(transaction = "none")

					expect(newPost.createdAt).toBe(twentyDaysAgo)

					transaction action="rollback";
				}
			})

			it("is overriding updated at with allow explicit timestamps", () => {
				author = g.model("author").findOne(order = "id")

				transaction {
					twentyDaysAgo = DateAdd("d", -20, Now())

					newPost = g.model("post").new(allowExplicitTimestamps = true)
					newPost.authorId = author.id
					newPost.title = "New title"
					newPost.body = "New Body"
					newPost.createdAt = twentyDaysAgo
					newPost.updatedAt = twentyDaysAgo

					newPost.save(transaction = "none")

					expect(newPost.updatedAt).toBe(twentyDaysAgo)

					transaction action="rollback";
				}
			})
		})

		describe("Tests that order", () => {

			it("is working with maxrows and calculated property", () => {
				result = g.model("photo").findOne(order = "DESCRIPTION1 DESC", maxRows = 1)

				expect(result.fileName).toBe("Gallery 9 Photo Test 9")
			})

			it("is working with no sort", () => {
				result = g.model("author").findOne(order = "lastName")

				expect(result.lastname).toBe("Amiri")
			})

			it("is working with ASC sort", () => {
				result = g.model("author").findOne(order = "lastName ASC")

				expect(result.lastname).toBe("Amiri")
			})

			it("is working with DESC sort", () => {
				result = g.model("author").findOne(order = "lastName DESC")

				expect(result.lastname).toBe("Riera")
			})

			it("is working with include", () => {
				result = g.model("post").findAll(include = "c_o_r_e_comments", order = "createdAt DESC,id DESC,name")

				expect(result['title'][1]).toBe("Title for fifth test post")
			})

			it("is working with include and identical columns", () => {
				result = g.model("post").findAll(include = "c_o_r_e_comments", order = "createdAt,createdAt")

				expect(result['title'][1]).toBe("Title for first test post")
			})

			it("is working with paginated include and ambiguous columns", () => {
				actual = g.model("shop").findAll(
					select = "id, name",
					include = "trucks",
					page = 1,
					perPage = 3
				)

				expect(actual.recordCount).toBeGT(0)
			})

			it("is working with paginated include and identical columns", () => {
				result = g.model("post").findAll(page = 1, perPage = 3, include = "c_o_r_e_comments", order = "createdAt")

				expect(result['title'][1]).toBe("Title for first test post")
			})

			it("is working with paginated include and identical columns desc sort with specified table names", () => {
				result = g.model("post").findAll(
					page = 1,
					perPage = 3,
					include = "c_o_r_e_comments",
					order = "c_o_r_e_posts.createdAt DESC,c_o_r_e_posts.id DESC"
				)

				expect(result['title'][1]).toBe("Title for fifth test post")
			})
		})

		describe("Tests that pagination", () => {

			beforeEach(() => {
				user = g.model("user")
				photo = g.model("photo")
				gallery = g.model("gallery")
			})

			it("exists early if no recordss match where clause", () => {
				e = user.findAll(
					where = "firstname = 'somemoron'",
					perpage = "2",
					page = "1",
					handle = "pagination_test_1",
					order = "id"
				)

				expect(request.wheels.pagination_test_1.CURRENTPAGE).toBe(1)
				expect(request.wheels.pagination_test_1.TOTALPAGES).toBe(0)
				expect(request.wheels.pagination_test_1.TOTALRECORDS).toBe(0)
				expect(request.wheels.pagination_test_1.ENDROW).toBe(1)
				expect(e.recordcount).toBe(0)
			})

			it("works with 5 records 2 perpage 3 pages", () => {
				r = user.findAll(select = "id", order = "id")

				/* 1st page */
				e = user.findAll(select = "id", perpage = "2", page = "1", handle = "pagination_test_2", order = "id")

				expect(request.wheels.pagination_test_2.CURRENTPAGE).toBe(1)
				expect(request.wheels.pagination_test_2.TOTALPAGES).toBe(3)
				expect(request.wheels.pagination_test_2.TOTALRECORDS).toBe(5)
				expect(request.wheels.pagination_test_2.ENDROW).toBe(2)
				expect(e.recordcount).toBe(2)
				expect(e.id[1]).toBe(r.id[1])
				expect(e.id[2]).toBe(r.id[2])

				/* 2nd page */
				e = user.findAll(perpage = "2", page = "2", handle = "pagination_test_3", order = "id")

				expect(request.wheels.pagination_test_3.CURRENTPAGE).toBe(2)
				expect(request.wheels.pagination_test_3.TOTALPAGES).toBe(3)
				expect(request.wheels.pagination_test_3.TOTALRECORDS).toBe(5)
				expect(request.wheels.pagination_test_3.ENDROW).toBe(4)
				expect(e.recordcount).toBe(2)
				expect(e.id[1]).toBe(r.id[3])
				expect(e.id[2]).toBe(r.id[4])

				/* 3rd page */
				e = user.findAll(perpage = "2", page = "3", handle = "pagination_test_4", order = "id")

				expect(request.wheels.pagination_test_4.CURRENTPAGE).toBe(3)
				expect(request.wheels.pagination_test_4.TOTALPAGES).toBe(3)
				expect(request.wheels.pagination_test_4.TOTALRECORDS).toBe(5)
				expect(request.wheels.pagination_test_4.ENDROW).toBe(5)
				expect(e.recordcount).toBe(1)
				expect(e.id[1]).toBe(r.id[5])
			})

			it("works when specify where on joined table", () => {
				q = gallery.findOne(include = "user", where = "c_o_r_e_users.lastname = 'Petruzzi'", order = "id")

				/* 10 records, 2 perpage, 5 pages */
				args = {
					perpage = "2",
					page = "1",
					handle = "pagination_test",
					order = "id",
					include = "gallery",
					where = "galleryid = #q.id#"
				}

				args2 = Duplicate(args)
				StructDelete(args2, "perpage", false)
				StructDelete(args2, "page", false)
				StructDelete(args2, "handle", false)
				r = photo.findAll(argumentCollection = args2)

				/* page 1 */
				e = photo.findAll(argumentCollection = args)

				expect(e.galleryid[1]).toBe(r.galleryid[1])
				expect(e.galleryid[2]).toBe(r.galleryid[2])

				/* page 3 */
				args.page = "3"
				e = photo.findAll(argumentCollection = args)

				expect(e.galleryid[1]).toBe(r.galleryid[5])
				expect(e.galleryid[2]).toBe(r.galleryid[6])

				/* page 5 */
				args.page = "5"
				e = photo.findAll(argumentCollection = args)

				expect(e.galleryid[1]).toBe(r.galleryid[9])
				expect(e.galleryid[2]).toBe(r.galleryid[10])
			})

			it("makes sure that remapped columns containing desc and asc work", () => {
				result = g.model("photo").findAll(
					page = 1,
					perPage = 20,
					order = 'DESCription1 DESC',
					handle = "pagination_order_test_1"
				)

				expect(request.wheels.pagination_order_test_1.CURRENTPAGE).toBe(1)
				expect(request.wheels.pagination_order_test_1.TOTALPAGES).toBe(13)
				expect(request.wheels.pagination_order_test_1.TOTALRECORDS).toBe(250)
				expect(request.wheels.pagination_order_test_1.ENDROW).toBe(20)
			})

			it("works with renamed primary key", () => {
				photo = g.model("photo2").findAll(page = 1, perpage = 3, where = "DESCRIPTION1 LIKE '%test%'")

				expect(photo.recordcount).toBe(3)
			})

			it("works with parameterize set to false with string", () => {
				if (structKeyExists(server, "boxlang")) return;
				result = g.model("photo").findAll(
					page = 1,
					perPage = 20,
					handle = "pagination_order_test_1",
					parameterize = "false",
					where = "description1 LIKE '%photo%'"
				)

				expect(request.wheels.pagination_order_test_1.CURRENTPAGE).toBe(1)
				expect(request.wheels.pagination_order_test_1.TOTALPAGES).toBe(13)
				expect(request.wheels.pagination_order_test_1.TOTALRECORDS).toBe(250)
				expect(request.wheels.pagination_order_test_1.ENDROW).toBe(20)
			})

			it("works with parameterize set to false with numeric", () => {
				if (structKeyExists(server, "boxlang")) return;
				result = g.model("photo").findAll(
					page = 1,
					perPage = 20,
					handle = "pagination_order_test_1",
					parameterize = "false",
					where = "id = 1"
				)

				expect(request.wheels.pagination_order_test_1.CURRENTPAGE).toBe(1)
				expect(request.wheels.pagination_order_test_1.TOTALPAGES).toBe(1)
				expect(request.wheels.pagination_order_test_1.TOTALRECORDS).toBe(1)
				expect(request.wheels.pagination_order_test_1.ENDROW).toBe(1)
			})

			it("works with compound keys", () => {
				result = g.model("combikey").findAll(page = 2, perPage = 4, order = "id2")

				expect(result.recordcount).toBe(4)
			})

			it("works with incorrect number of record returned when where clause satisfies records beyond the first identifier value", () => {
				q = g.model("author").findAll(include = "posts", where = "c_o_r_e_posts.views > 2", page = 1, perpage = 5)

				expect(q.recordcount).toBe(3)
			})
		})

		describe("Tests that properties", () => {

			it("function updateProperty works", () => {
				transaction action="begin" {
					author = g.model("Author").findOne(where = "firstName='Andy'")
					saved = author.updateProperty("firstName", "Frog")
					transaction action="rollback";
				}

				expect(saved).toBeTrue()
				expect(author.firstName).toBe("Frog")
			})

			it("function updateProperty with dynamic args works", () => {
				transaction action="begin" {
					author = g.model("Author").findOne(where = "firstName='Andy'")
					saved = author.updateProperty(firstName = "Frog")
					transaction action="rollback";
				}

				expect(saved).toBeTrue()
				expect(author.firstName).toBe("Frog")
			})

			it("function updateProperty dynamic method works", () => {
				transaction action="begin" {
					author = g.model("Author").findOne(where = "firstName='Andy'")
					saved = author.updateFirstName(value = "Frog")
					transaction action="rollback";
				}

				expect(saved).toBeTrue()
				expect(author.firstName).toBe("Frog")
			})

			it("is updating properties", () => {
				transaction action="begin" {
					author = g.model("Author").findOne(where = "firstName='Andy'")
					saved = author.update(firstName = "Kirmit", lastName = "Frog")
					transaction action="rollback";
				}

				expect(saved).toBeTrue()
				expect(author.firstName).toBe("Kirmit")
				expect(author.lastName).toBe("Frog")
			})
		})

		describe("Tests that select", () => {

			it("table name with star translates to all fields", () => {
				postModel = g.model("post")
				r = postModel.$createSQLFieldList(clause = "select", list = "c_o_r_e_posts.*", include = "", returnAs = "query")
				props = postModel.$classData().properties

				expect(ListLen(r)).toBe(StructCount(props))
			})

			it("throws error when wrong table alias", () => {
				postModel = g.model("post")

				expect(function() {
					postModel.$createSQLFieldList(list="comments.*", include="", returnAs="query")
				}).toThrow()
			})

			it("works with association with expanded aliases enabled", () => {
				columnList = ListSort(
					g.model("Author").$createSQLFieldList(
						clause = "select",
						list = "",
						include = "Posts",
						returnAs = "query",
						useExpandedColumnAliases = true
					),
					"text"
				)

				expect(columnList).toBe("c_o_r_e_authors.firstname,c_o_r_e_authors.id,c_o_r_e_authors.id AS Authorid,c_o_r_e_authors.lastname,c_o_r_e_posts.averagerating AS postaveragerating,c_o_r_e_posts.body AS postbody,c_o_r_e_posts.createdat AS postcreatedat,c_o_r_e_posts.deletedat AS postdeletedat,c_o_r_e_posts.id AS postid,c_o_r_e_posts.title AS posttitle,c_o_r_e_posts.updatedat AS postupdatedat,c_o_r_e_posts.views AS postviews")
			})

			it("works with association with expanded aliases disabled", () => {
				columnList = ListSort(
					g.model("Author").$createSQLFieldList(
						clause = "select",
						list = "",
						include = "Posts",
						returnAs = "query",
						useExpandedColumnAliases = false
					),
					"text"
				)

				expect(columnList).toBe("c_o_r_e_authors.firstname,c_o_r_e_authors.id,c_o_r_e_authors.id AS Authorid,c_o_r_e_authors.lastname,c_o_r_e_posts.averagerating,c_o_r_e_posts.body,c_o_r_e_posts.createdat,c_o_r_e_posts.deletedat,c_o_r_e_posts.id AS postid,c_o_r_e_posts.title,c_o_r_e_posts.updatedat,c_o_r_e_posts.views")
			})

			it("works on calculated property", () => {
				columnList = ListSort(g.model("AuthorSelectArgument").findAll(returnAs = "query").columnList, "text")

				expect(columnList).toBe("firstname,id,lastname,selectargdefault,selectargtrue")
			})
		})

		describe("Tests that updates", () => {

			it("works", () => {
				transaction action="begin" {
					author = g.model("Author").findOne();
					author.update(firstName = "Kermit", lastName = "Frog")
					allKermits = g.model("Author").findAll(where = "firstName='Kermit' AND lastName='Frog'")
					transaction action="rollback";
				}

				expect(allKermits.recordcount).toBe(1)
			})

			it("dynamic update with named argument works", () => {
				transaction action="begin" {
					author = g.model("author").findOne(where = "firstName='Andy'");
					profile = g.model("profile").findOne(where = "bio LIKE 'ColdFusion Developer'")
					author.setProfile(profile = profile)
					updatedProfile = g.model("profile").findByKey(profile.id)
					transaction action="rollback";
				}

				expect(updatedProfile.authorId).toBe(author.id)
			})

			it("dynamic update with unnamed argument works", () => {
				transaction action="begin" {
					author = g.model("author").findOne(where = "firstName='Andy'");
					profile = g.model("profile").findOne(where = "bio LIKE 'ColdFusion Developer'")
					author.setProfile(profile)
					updatedProfile = g.model("profile").findByKey(profile.id)
					transaction action="rollback";
				}

				expect(updatedProfile.authorId).toBe(author.id)
			})

			it("function updateOne works", () => {
				transaction action="begin" {
					g.model("Author").updateOne(where = "firstName='Andy'", firstName = "Kermit", lastName = "Frog");
					allKermits = g.model("Author").findAll(where = "firstName='Kermit' AND lastName='Frog'")
					transaction action="rollback";
				}

				expect(allKermits.recordcount).toBe(1)
			})

			it("function updateOne works for soft deleted records", () => {
				transaction action="begin" {
					post = g.model("Post").deleteOne(where = "views=0");
					g.model("Post").updateOne(where = "views=0", title = "This is a new title", includeSoftDeletes = true)
					changedPosts = g.model("Post").findAll(where = "title='This is a new title'", includeSoftDeletes = true)
					transaction action="rollback";
				}

				expect(changedPosts.recordcount).toBe(1)
			})

			it("function updateByKey works", () => {
				transaction action="begin" {
					author = g.model("Author").findOne();
					g.model("Author").updateByKey(key = author.id, firstName = "Kermit", lastName = "Frog")
					allKermits = g.model("Author").findAll(where = "firstName='Kermit' AND lastName='Frog'")
					transaction action="rollback";
				}

				expect(allKermits.recordcount).toBe(1)
			})

			it("function updateByKey works for soft deleted records", () => {
				transaction action="begin" {
					post = g.model("Post").findOne(where = "views=0");
					g.model("Post").updateByKey(key = post.id, title = "This is a new title", includeSoftDeletes = true)
					changedPosts = g.model("Post").findAll(where = "title='This is a new title'", includeSoftDeletes = true)
					transaction action="rollback";
				}

				expect(changedPosts.recordcount).toBe(1)
			})

			it("function updateAll works", () => {
				transaction action="begin" {
					g.model("Author").updateAll(firstName = "Kermit", lastName = "Frog");
					allKermits = g.model("Author").findAll(where = "firstName='Kermit' AND lastName='Frog'")
					transaction action="rollback";
				}

				expect(allKermits.recordcount).toBe(10)
			})

			it("function updateAll works for soft delete records", () => {
				transaction action="begin" {
					g.model("Post").updateAll(title = "This is a new title", includeSoftDeletes = true);
					changedPosts = g.model("Post").findAll(where = "title='This is a new title'", includeSoftDeletes = true)
					transaction action="rollback";
				}

				expect(changedPosts.recordcount).toBe(5)
			})

			it("columns that are not null should allow for blank string during update", () => {
				info = g.$dbinfo(datasource = application.wheels.dataSourceName, type = "version")
				db = LCase(Replace(info.database_productname, " ", "", "all"))

				transaction action="begin" {
					author = g.model("author").findOne(where = "firstName='Tony'")
					author.lastName = " "
					author.save()
					author = g.model("author").findOne(where = "firstName='Tony'")
					transaction action="rollback";
				}

				expect(author).toBeInstanceOf("author")
				expect(trim(author.lastname)).toHaveLength(0)
			})

			// Issue#1273: Added this test for includes in the updateAll function
			it("updateall with include", () => {
				transaction action="begin"	{
					loc.query0 = g.model("Post").findAll(where="averagerating = '5.0'")
					expect(loc.query0.recordcount).toBe(0)
					loc.query1 = g.model("Post").updateAll(averagerating = "5.0", where = "c_o_r_e_comments.postid = '1'", include = "c_o_r_e_comments")
					loc.query2 = g.model("Post").findAll(where="averagerating = '5.0'")
					transaction action="rollback";
				}
				expect(loc.query2.recordcount).toBe(1)
			})
		})

		describe("Tests that where", () => {

			it("should not strip extra whitespace from values", () => {
				r = g.model("user").findAll(where = "address = '123     Petruzzi St.'")

				expect(r.recordcount).toBe(0)

				r = g.model("user").findAll(where = "address = '123 Petruzzi St.'")

				expect(r.recordcount).toBe(2)
			})

			it("should not throw error when using IN statemment", () => {
				$assert.notThrows(function(){
					r = g.model("user").findAll(
						where = "username IN('tonyp','perd','chrisp') AND (firstname = 'Tony' OR firstname = 'Per' OR firstname = 'Chris') OR id IN(1,2,3)"
					)
				})
			})

			it("should respect parenthesis commas and single quotes when using IN statement", () => {
				r = g.model("user").findAll(where = "username IN('tony''s','pe''(yo,yo)rd','chrisp')")

				expect(r.recordcount).toBe(1)
			})

			it("works with numeric value for string property", () => {
				actual = g.model("Post").$keyWhereString(properties = "title", values = "1")

				expect(actual).toBe("title='1'")
			})
		})
	}
}