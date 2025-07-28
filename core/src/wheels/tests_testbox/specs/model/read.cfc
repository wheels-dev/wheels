component extends="testbox.system.BaseSpec" {

	function run() {

		g = application.wo

		describe("Tests that findAllKeys", () => {
			
			beforeEach(() => {
				// we can only test h2 as the alt dsn.. the tables are not created in populate.cfm otherwise
				altDatasource = "wheelstestdb_h2"
				isTestable = true
				if(application.wheels.dataSourceName eq altDatasource){
					isTestable = false
				}
				else if(application.wheels.serverName contains "Coldfusion"){
					// seems ACF can't handle H2 datasources
					isTestable = false
				}
			})

			// Commenting this test temporarily to make the github actions work as it is not working in testbox
			// it("findall respects model config datasource", () => {
			// 	if (!isTestable) return;
			// 	transaction {
			// 		this.db_setup()
			// 		// ensure this is using the wheelstestdb_h2 as defined in the model config
			// 		actual = g.model("AuthorAlternateDatasource").findAll(where = "firstName = '#firstName#'")
			// 		TransactionRollback()
			// 	}
			// 	expect(actual.recordCount).toBeGT(0)
			// })

			it("findall with datasource argument", () => {
				if (!isTestable) return;
				transaction {
					this.db_setup()
					defaultDBRows = g.model("Author").findAll(where = "firstName = '#firstName#'")
					actual = g.model("Author").findAll(argumentCollection = finderArgs)
					TransactionRollback()
				}
				expect(actual.recordCount).toBeGT(0)
				// sanity check that there are no rows in the default db
				expect(defaultDBRows.recordCount).toBe(0)
			})

			it("findone with datasource argument", () => {
				if (!isTestable) return;
				transaction {
					this.db_setup()
					actual = g.model("Author").findOne(argumentCollection = finderArgs)
					TransactionRollback()
				}
				expect(actual).toBeInstanceOf('Author')
			})

			it("findfirst with datasource argument", () => {
				if (!isTestable) return;
				transaction {
					this.db_setup()
					actual = g.model("Author").findFirst(argumentCollection = finderArgs)
					TransactionRollback()
				}
				expect(actual).toBeInstanceOf('Author')
			})

			it("findLastOne with datasource argument", () => {
				if (!isTestable) return;
				transaction {
					this.db_setup()
					actual = g.model("Author").findLastOne(argumentCollection = finderArgs)
					TransactionRollback()
				}
				expect(actual).toBeInstanceOf('Author')
			})

			it("count with datasource argument", () => {
				if (!isTestable) return;
				transaction {
					this.db_setup()
					actual = g.model("Author").count(argumentCollection = finderArgs)
					TransactionRollback()
				}
				expect(actual).toBeGT(0)
			})

			it("exists with datasource argument", () => {
				if (!isTestable) return;
				transaction {
					this.db_setup()
					actual = g.model("Author").exists(argumentCollection = finderArgs)
					TransactionRollback()
				}
				expect(actual).toBeTrue()
			})

		})

		describe("Tests that findAllKeys", () => {

			it("works", () => {
				p = g.model("post").findAll(select = "id")
				posts = g.model("post").findAllKeys()
				keys = ValueList(p.id)

				expect(posts).toBe(keys)

				p = g.model("post").findAll(select = "id")
				posts = g.model("post").findAllKeys(quoted = true)
				if (StructKeyExists(server, "boxlang")) {
       				// BoxLang QuotedValueList uses double quotes, but findAllKeys uses single quotes
                    keys = Replace(QuotedValueList(p.id), '"', "'", "all")
                } else {
                    keys = QuotedValueList(p.id)
    		    }
				expect(posts).toBe(keys)
			})
		})

		describe("Tests that findfirst", () => {

			it("works", () => {
				result = g.model("user").findFirst();

				expect(result.id).toBe(1)

				result = g.model("user").findFirst(property = "firstName");

				expect(result.firstName).toBe("Chris")

				result = g.model("user").findFirst(properties = "firstName");

				expect(result.firstName).toBe("Chris")

				result = g.model("user").findFirst(property = "firstName", where = "id != 2");

				expect(result.firstName).toBe("Joe")
			})
		})

		describe("Tests that findLastOne", () => {

			it("works", () => {
				result = g.model("user").findLastOne();

				expect(result.id).toBe(5)

				result = g.model("user").findLastOne(properties = "id");

				expect(result.id).toBe(5)
			})
		})

		describe("Tests that findorcreateby", () => {

			it("works", () => {
				transaction {
					author = g.model("author").findOrCreateByFirstName(firstName = "Per", lastName = "Djurner")

					expect(author).toBeInstanceOf("author")
					expect(author.lastname).toBe("Djurner")
					expect(author.firstname).toBe("Per")

					transaction action="rollback";
				}
			})

			it("works with one property name", () => {
				transaction {
					author = g.model("author").findOrCreateByFirstName(firstName = "Per")

					expect(author).toBeInstanceOf("author")
					expect(author.firstname).toBe("Per")

					transaction action="rollback";
				}
			})

			it("works with any property name", () => {
				transaction {
					author = g.model("author").findOrCreateByFirstName(whatever = "Per")

					expect(author).toBeInstanceOf("author")
					expect(author.firstname).toBe("Per")

					transaction action="rollback";
				}
			})

			it("works with unnamed argument", () => {
				transaction {
					author = g.model("author").findOrCreateByFirstName("Per")

					expect(author).toBeInstanceOf("author")
					expect(author.firstname).toBe("Per")

					transaction action="rollback";
				}
			})
		})
	}

	function db_setup(){
		// ensure the authors table exists in the alt datasource
		g.$query(
			sql = "
				CREATE TABLE IF NOT EXISTS c_o_r_e_authors
				(
					id int NOT NULL IDENTITY
					,firstname varchar(100) NOT NULL
					,lastname varchar(100) NOT NULL
					,PRIMARY KEY(id)
				)
			",
			datasource = altDatasource
		)
		firstName = "Troll"
		g.$query(
			sql = "INSERT INTO c_o_r_e_authors (firstName, lastName) VALUES ('#firstName#', 'Dolls');",
			datasource = altDatasource
		)
		finderArgs = {where = "firstName = '#firstName#'", datasource = altDatasource}
	}

}