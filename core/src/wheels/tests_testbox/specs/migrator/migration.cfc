component extends="wheels.Testbox" {

	include "helperFunctions.cfm"

	function beforeAll() {
		migration = CreateObject("component", "wheels.migrator.Migration").init()
		originalMigratorObjectCase = Duplicate(application.wheels.migratorObjectCase)
	}

	function afterAll() {
		application.wheels.migratorObjectCase = originalMigratorObjectCase
	}

	function run() {

		g = application.wo

		describe("Tests column BIG INTEGER", () => {

			it("is being added", () => {
				if(!isDbCompatibleFor_H2_MySQL()) {
					return
				}

				tableName = "dbm_add_big_integer_tests"
				columnName = "bigIntegerCOLUMN"
				t = migration.createTable(name = tableName, force = true)
				t.bigInteger(columnNames = columnName)
				t.create()

				info = g.$dbinfo(datasource = application.wheels.dataSourceName, table = tableName, type = "columns")
				actual = ListToArray(ValueList(info.TYPE_NAME))[2]
				migration.dropTable(tableName)
				
				expected = getBigIntegerType()

				expect(actual).toBe(expected)
			})

			it("is being added multiple", () => {
				if(!isDbCompatibleFor_H2_MySQL()) {
					return
				}

				tableName = "dbm_add_big_integer_tests"
				columnNames = "bigIntegerA,bigIntegerB"
				t = migration.createTable(name = tableName, force = true)
				t.bigInteger(columnNames = columnNames)
				t.create()

				info = g.$dbinfo(datasource = application.wheels.dataSourceName, table = tableName, type = "columns")
				actual = ListToArray(ValueList(info.TYPE_NAME))
				migration.dropTable(tableName)
				
				expected = getBigIntegerType()

				expect(actual[2]).toBe(expected)
				expect(actual[3]).toBe(expected)
			})
		})

		describe("Tests column BINARY", () => {

			it("is being added", () => {
				if (!isDbCompatible()) {
					return
				}

				tableName = "dbm_add_binary_tests"
				columnName = "binaryCOLUMN"
				t = migration.createTable(name = tableName, force = true)
				t.binary(columnName = columnName)
				t.create()

				info = g.$dbinfo(datasource = application.wheels.dataSourceName, table = tableName, type = "columns")
				actual = ListToArray(ValueList(info.TYPE_NAME))[2]
				migration.dropTable(tableName)

				expected = getBinaryType()

				expect(actual).toBe(expected)
			})

			it("is being added multiple", () => {
				if (!isDbCompatible()) {
					return
				}

				tableName = "dbm_add_binary_tests"
				columnNames = "binaryA,binaryB"
				t = migration.createTable(name = tableName, force = true)
				t.binary(columnNames = columnNames)
				t.create()

				info = g.$dbinfo(datasource = application.wheels.dataSourceName, table = tableName, type = "columns")
				actual = ListToArray(ValueList(info.TYPE_NAME))
				migration.dropTable(tableName)

				expected = getBinaryType()

				expect(actual[2]).toBe(expected)
				expect(actual[3]).toBe(expected)
			})
		})

		describe("Tests column BOOLEAN", () => {

			it("is being added", () => {
				if (!isDbCompatible()) {
					return
				}

				tableName = "dbm_add_boolean_tests"
				columnName = "booleanCOLUMN"
				t = migration.createTable(name = tableName, force = true)
				t.boolean(columnName = columnName)
				t.create()

				info = g.$dbinfo(datasource = application.wheels.dataSourceName, table = tableName, type = "columns")
				actual = ListToArray(ValueList(info.TYPE_NAME))[2]
				migration.dropTable(tableName)

				expected = getBooleanType()

				expect(listContainsNoCase(expected,actual)).toBeTrue()
			})

			it("is being added multiple", () => {
				if (!isDbCompatible()) {
					return
				}

				tableName = "dbm_add_boolean_tests"
				columnNames = "booleanA,booleanB"
				t = migration.createTable(name = tableName, force = true)
				t.boolean(columnNames = columnNames)
				t.create()

				info = g.$dbinfo(datasource = application.wheels.dataSourceName, table = tableName, type = "columns")
				actual = ListToArray(ValueList(info.TYPE_NAME))
				migration.dropTable(tableName)

				expected = getBooleanType()

				expect(listContainsNoCase(expected,actual[2])).toBeTrue()
				expect(listContainsNoCase(expected,actual[3])).toBeTrue()
			})
		})

		describe("Tests column CHAR", () => {

			it("is being added", () => {
				if (!isDbCompatibleFor_SQLServer()) {
					return
				}

				tableName = "dbm_add_char_tests"
				columnName = "charCOLUMN"
				t = migration.createTable(name = tableName, force = true)
				t.char(columnName = columnName)
				t.create()

				info = g.$dbinfo(datasource = application.wheels.dataSourceName, table = tableName, type = "columns")
				actual = ListToArray(ValueList(info.TYPE_NAME))[2]
				migration.dropTable(tableName)

				expected = getCharType()

				expect(actual).toBe(expected)
			})

			it("is being added multiple", () => {
				if (!isDbCompatibleFor_SQLServer()) {
					return
				}

				tableName = "dbm_add_char_tests"
				columnNames = "charA,charB"
				t = migration.createTable(name = tableName, force = true)
				t.char(columnNames = columnNames)
				t.create()

				info = g.$dbinfo(datasource = application.wheels.dataSourceName, table = tableName, type = "columns")
				actual = ListToArray(ValueList(info.TYPE_NAME))
				migration.dropTable(tableName)

				expected = getCharType()

				expect(actual[2]).toBe(expected)
				expect(actual[3]).toBe(expected)
			})
		})

		describe("Tests column DATE", () => {

			it("is being added", () => {
				if (!isDbCompatible()) {
					return
				}

				tableName = "dbm_add_date_tests"
				columnName = "dateCOLUMN"
				t = migration.createTable(name = tableName, force = true)
				t.date(columnName = columnName)
				t.create()

				info = g.$dbinfo(datasource = application.wheels.dataSourceName, table = tableName, type = "columns")
				actual = ListToArray(ValueList(info.TYPE_NAME))[2]
				migration.dropTable(tableName)

				expected = getDateType()

				expect(actual).toBe(expected)
			})

			it("is being added multiple", () => {
				if (!isDbCompatible()) {
					return
				}

				tableName = "dbm_add_date_tests"
				columnNames = "dateA,dateB"
				t = migration.createTable(name = tableName, force = true)
				t.date(columnNames = columnNames)
				t.create()

				info = g.$dbinfo(datasource = application.wheels.dataSourceName, table = tableName, type = "columns")
				actual = ListToArray(ValueList(info.TYPE_NAME))
				migration.dropTable(tableName)

				expected = getDateType()

				expect(actual[2]).toBe(expected)
				expect(actual[3]).toBe(expected)
			})
		})

		describe("Tests column DATETIME", () => {

			it("is being added", () => {
				if (!isDbCompatible()) {
					return
				}

				tableName = "dbm_add_datetime_tests"
				columnName = "datetimeCOLUMN"
				t = migration.createTable(name = tableName, force = true)
				t.datetime(columnName = columnName)
				t.create()

				info = g.$dbinfo(datasource = application.wheels.dataSourceName, table = tableName, type = "columns")
				actual = ListToArray(ValueList(info.TYPE_NAME))[2]
				migration.dropTable(tableName)

				expected = getDatetimeType()

				expect(actual).toBe(expected)
			})

			it("is being added multiple", () => {
				if (!isDbCompatible()) {
					return
				}

				tableName = "dbm_add_datetime_tests"
				columnNames = "datetimeA,datetimeB"
				t = migration.createTable(name = tableName, force = true)
				t.datetime(columnNames = columnNames)
				t.create()

				info = g.$dbinfo(datasource = application.wheels.dataSourceName, table = tableName, type = "columns")
				actual = ListToArray(ValueList(info.TYPE_NAME))
				migration.dropTable(tableName)

				expected = getDatetimeType()

				expect(actual[2]).toBe(expected)
				expect(actual[3]).toBe(expected)
			})
		})

		describe("Tests column DECIMAL", () => {

			it("is being added", () => {
				if (!isDbCompatible()) {
					return
				}

				tableName = "dbm_add_decimal_tests"
				columnName = "decimalCOLUMN"
				t = migration.createTable(name = tableName, force = true)
				t.decimal(columnName = columnName)
				t.create()

				info = g.$dbinfo(datasource = application.wheels.dataSourceName, table = tableName, type = "columns")
				actual = ListToArray(ValueList(info.TYPE_NAME))[2]
				migration.dropTable(tableName)

				expected = getDecimalType()

				expect(actual).toBe(expected)
			})

			it("is being added multiple", () => {
				if (!isDbCompatible()) {
					return
				}

				tableName = "dbm_add_decimal_tests"
				columnNames = "decimalA,decimalB"
				t = migration.createTable(name = tableName, force = true)
				t.decimal(columnNames = columnNames)
				t.create()

				info = g.$dbinfo(datasource = application.wheels.dataSourceName, table = tableName, type = "columns")
				actual = ListToArray(ValueList(info.TYPE_NAME))
				migration.dropTable(tableName)

				expected = getDecimalType()

				expect(actual[2]).toBe(expected)
				expect(actual[3]).toBe(expected)
			})
		})

		describe("Tests column FLOAT", () => {

			it("is being added", () => {
				if (!isDbCompatible()) {
					return
				}

				tableName = "dbm_add_float_tests"
				columnName = "floatCOLUMN"
				t = migration.createTable(name = tableName, force = true)
				t.float(columnName = columnName)
				t.create()

				info = g.$dbinfo(datasource = application.wheels.dataSourceName, table = tableName, type = "columns")
				actual = ListToArray(ValueList(info.TYPE_NAME))[2]
				migration.dropTable(tableName)

				expected = getFloatType()

				expect(ListFindNoCase(expected, actual)).toBeTrue()
			})

			it("is being added multiple", () => {
				if (!isDbCompatible()) {
					return
				}

				tableName = "dbm_add_float_tests"
				columnNames = "floatA,floatB"
				t = migration.createTable(name = tableName, force = true)
				t.float(columnNames = columnNames)
				t.create()

				info = g.$dbinfo(datasource = application.wheels.dataSourceName, table = tableName, type = "columns")
				actual = ListToArray(ValueList(info.TYPE_NAME))
				migration.dropTable(tableName)

				expected = getFloatType()

				expect(ListFindNoCase(expected, actual[2])).toBeTrue()
				expect(ListFindNoCase(expected, actual[3])).toBeTrue()
			})
		})

		describe("Tests column INTEGER", () => {

			it("is being added", () => {
				if (!isDbCompatible()) {
					return
				}

				tableName = "dbm_add_integer_tests"
				columnName = "integerCOLUMN"
				t = migration.createTable(name = tableName, force = true)
				t.integer(columnNames = columnName)
				t.create()

				info = g.$dbinfo(datasource = application.wheels.dataSourceName, table = tableName, type = "columns")
				actual = ListToArray(ValueList(info.TYPE_NAME))[2]
				migration.dropTable(tableName)

				expected = getIntegerType()

				expect(ListFindNoCase(expected, actual)).toBeTrue()
			})

			it("is being added multiple", () => {
				if (!isDbCompatible()) {
					return
				}

				tableName = "dbm_add_integer_tests"
				columnNames = "integerA,integerB"
				t = migration.createTable(name = tableName, force = true)
				t.integer(columnNames = columnNames)
				t.create()

				info = g.$dbinfo(datasource = application.wheels.dataSourceName, table = tableName, type = "columns")
				actual = ListToArray(ValueList(info.TYPE_NAME))
				migration.dropTable(tableName)

				expected = getIntegerType()

				expect(ListFindNoCase(expected, actual[2])).toBeTrue()
				expect(ListFindNoCase(expected, actual[3])).toBeTrue()
			})
		})

		describe("Tests column STRING", () => {

			it("is being added", () => {
				if (!isDbCompatible()) {
					return
				}

				tableName = "dbm_add_string_tests"
				columnName = "stringCOLUMN"
				t = migration.createTable(name = tableName, force = true)
				t.string(columnName = columnName)
				t.create()

				info = g.$dbinfo(datasource = application.wheels.dataSourceName, table = tableName, type = "columns")
				actual = ListToArray(ValueList(info.TYPE_NAME))[2]
				migration.dropTable(tableName)

				expected = getStringType()

				expect(actual).toBe(expected)
			})

			it("is being added multiple", () => {
				if (!isDbCompatible()) {
					return
				}

				tableName = "dbm_add_string_tests"
				columnNames = "stringA,stringB"
				t = migration.createTable(name = tableName, force = true)
				t.string(columnNames = columnNames)
				t.create()

				info = g.$dbinfo(datasource = application.wheels.dataSourceName, table = tableName, type = "columns")
				actual = ListToArray(ValueList(info.TYPE_NAME))
				migration.dropTable(tableName)

				expected = getStringType()

				expect(ListFindNoCase(expected, actual[2])).toBeTrue()
				expect(ListFindNoCase(expected, actual[3])).toBeTrue()
			})
		})

		describe("Tests column TEXT", () => {

			it("is being added", () => {
				if (!isDbCompatible()) {
					return
				}

				tableName = "dbm_add_text_tests"
				columnName = "textCOLUMN"
				t = migration.createTable(name = tableName, force = true)
				t.text(columnName = columnName)
				t.create()

				info = g.$dbinfo(datasource = application.wheels.dataSourceName, table = tableName, type = "columns")
				actual = ListToArray(ValueList(info.TYPE_NAME))[2]
				migration.dropTable(tableName)

				expected = getTextType()

				expect(ArrayContainsNoCase(expected, actual)).toBeTrue()
			})

			it("is being added multiple", () => {
				if (!isDbCompatible()) {
					return
				}

				tableName = "dbm_add_text_tests"
				columnNames = "textA,textB"
				t = migration.createTable(name = tableName, force = true)
				t.text(columnNames = columnNames)
				t.create()

				info = g.$dbinfo(datasource = application.wheels.dataSourceName, table = tableName, type = "columns")
				actual = ListToArray(ValueList(info.TYPE_NAME))
				migration.dropTable(tableName)

				expected = getTextType()

				expect(ArrayContainsNoCase(expected, actual[2])).toBeTrue()
				expect(ArrayContainsNoCase(expected, actual[3])).toBeTrue()
			})
		})

		describe("Tests column TIME", () => {

			it("is being added", () => {
				if (!isDbCompatible()) {
					return
				}

				tableName = "dbm_add_time_tests"
				columnName = "timeCOLUMN"
				t = migration.createTable(name = tableName, force = true)
				t.time(columnName = columnName)
				t.create()

				info = g.$dbinfo(datasource = application.wheels.dataSourceName, table = tableName, type = "columns")
				actual = ListToArray(ValueList(info.TYPE_NAME))[2]
				migration.dropTable(tableName)

				expected = getTimeType()

				expect(actual).toBe(expected)
			})

			it("is being added multiple", () => {
				if (!isDbCompatible()) {
					return
				}

				tableName = "dbm_add_time_tests"
				columnNames = "timeA,timeB"
				t = migration.createTable(name = tableName, force = true)
				t.time(columnNames = columnNames)
				t.create()

				info = g.$dbinfo(datasource = application.wheels.dataSourceName, table = tableName, type = "columns")
				actual = ListToArray(ValueList(info.TYPE_NAME))
				migration.dropTable(tableName)

				expected = getTimeType()

				expect(actual[2]).toBe(expected)
				expect(actual[3]).toBe(expected)
			})
		})

		describe("Tests column TIMESTAMP", () => {

			it("is being added", () => {
				if (!isDbCompatible()) {
					return
				}

				tableName = "dbm_add_timestamp_tests"
				columnName = "timestampCOLUMN"
				t = migration.createTable(name = tableName, force = true)
				t.timestamp(columnName = columnName)
				t.create()

				info = g.$dbinfo(datasource = application.wheels.dataSourceName, table = tableName, type = "columns")
				actual = ListToArray(ValueList(info.TYPE_NAME))[2]
				migration.dropTable(tableName)

				expected = getTimestampType()

				expect(actual).toBe(expected)
			})

			it("is being added multiple", () => {
				if (!isDbCompatible()) {
					return
				}

				tableName = "dbm_add_timestamp_tests"
				columnNames = "timestampA,timestampB"
				t = migration.createTable(name = tableName, force = true)
				t.timestamp(columnNames = columnNames)
				t.create()

				info = g.$dbinfo(datasource = application.wheels.dataSourceName, table = tableName, type = "columns")
				actual = ListToArray(ValueList(info.TYPE_NAME))
				migration.dropTable(tableName)

				expected = getTimestampType()

				expect(actual[2]).toBe(expected)
				expect(actual[3]).toBe(expected)
			})
		})

		describe("Tests column UNIQUEIDENTIFIER", () => {

			it("is being added", () => {
				if (!isDbCompatibleFor_SQLServer()) {
					return
				}

				tableName = "dbm_add_uniqueidentifier_tests"
				columnName = "uniqueidentifierCOLUMN"
				t = migration.createTable(name = tableName, force = true)
				t.uniqueidentifier(columnName = columnName)
				t.create()

				info = g.$dbinfo(datasource = application.wheels.dataSourceName, table = tableName, type = "columns")
				actual = ListToArray(ValueList(info.TYPE_NAME))[2]
				migration.dropTable(tableName)

				expected = getUniqueIdentifierType()

				expect(actual).toBe(expected)
			})

			it("is being added multiple", () => {
				if (!isDbCompatibleFor_SQLServer()) {
					return
				}

				tableName = "dbm_add_uniqueidentifier_tests"
				columnNames = "uniqueidentifierA,uniqueidentifierB"
				t = migration.createTable(name = tableName, force = true)
				t.uniqueidentifier(columnNames = columnNames)
				t.create()

				info = g.$dbinfo(datasource = application.wheels.dataSourceName, table = tableName, type = "columns")
				actual = ListToArray(ValueList(info.TYPE_NAME))
				migration.dropTable(tableName)

				expected = getUniqueIdentifierType()

				expect(actual[2]).toBe(expected)
				expect(actual[3]).toBe(expected)
			})
		})

		describe("Tests addColumn", () => {

			// it's tricky to test the objectCase as some db engines support mixed case database object names (MSSQL does)
			it("is creating new column", () => {
				application.wheels.migratorObjectCase = "" // keep the specified case
				tableName = "dbm_addcolumn_tests"
				columnName = "integerCOLUMN"
				t = migration.createTable(name = tableName, force = true)
				t.string(columnNames = "stringcolumn")
				t.create()

				migration.addColumn(table = tableName, columnType = 'integer', columnName = columnName, allowNull = true)
				info = g.$dbinfo(datasource = application.wheels.dataSourceName, table = tableName, type = "columns")
				actual = ValueList(info.column_name)
				expected = columnName
				migration.dropTable(tableName)

				expect(ListFindNoCase(actual, expected)).toBeTrue()
			})
		})

		describe("Tests addForeignKey", () => {

			it("creates a foregin key constraint", () => {
				tableName = "dbm_afk_foos"
				referenceTableName = "dbm_afk_bars"

				t = migration.createTable(name = tableName, force = true)
				t.integer(columnNames = "barid")
				t.create()

				t = migration.createTable(name = referenceTableName, force = true)
				t.integer(columnNames = "integercolumn")
				t.create()

				migration.addForeignKey(
					table = tableName,
					referenceTable = referenceTableName,
					column = 'barid',
					referenceColumn = "id"
				)

				info = g.$dbinfo(datasource = application.wheels.dataSourceName, table = referenceTableName, type = "foreignkeys")

				migration.dropTable(tableName)
				migration.dropTable(referenceTableName)

				sql = "SELECT * FROM query WHERE LOWER(pkcolumn_name) = 'id' AND LOWER(fktable_name) = '#tableName#' AND LOWER(fkcolumn_name) = 'barid'"

				actual = g.$query(query = info, dbtype = "query", sql = sql)

				expect(actual.recordcount).toBe(1)
			})
		})

		describe("Tests addIndex", () => {

			beforeEach(() => {
				isACF2016 = application.wheels.serverName == "Adobe Coldfusion" && application.wheels.serverVersionMajor == 2016
				isPostgres = migration.adapter.adapterName() == "PostgreSQL"
				isLucee = application.wheels.serverName == "Lucee"
				isBoxLang = application.wheels.serverName == "BoxLang"
			})

			it("creates an index", () => {
				if (isACF2016 && isPostgres) {
					return
				}

				tableName = "dbm_addindex_tests"
				indexName = "idx_to_add"
				t = migration.createTable(name = tableName, force = true)
				t.integer(columnNames = "integercolumn")
				t.create()

				migration.addIndex(table = tableName, columnName = 'integercolumn', indexName = indexName)
				info = g.$dbinfo(datasource = application.wheels.dataSourceName, table = tableName, type = "index")

				migration.dropTable(tableName)

				sql = "SELECT * FROM query WHERE index_name = '#indexName#'"

				actual = g.$query(query = info, dbtype = "query", sql = "SELECT * FROM query WHERE LOWER(index_name) = '#indexName#'")

				expect(actual.recordcount).toBe(1)
				expect(actual.non_unique).toBeTrue()
			})

			it("creates an index on multiple columns", () => {
				if (isACF2016 && isPostgres) {
					return
				}

				tableName = "dbm_addindex_tests"
				indexName = "idx_to_add_to_multiple_columns"
				t = migration.createTable(name = tableName, force = true)
				t.integer(columnNames = "integercolumn,datecolumn")
				t.create()

				migration.addIndex(table = tableName, columnNames = 'integercolumn,datecolumn', indexName = indexName)
				info = g.$dbinfo(datasource = application.wheels.dataSourceName, table = tableName, type = "index")

				migration.dropTable(tableName)

				sql = "SELECT * FROM query WHERE LOWER(index_name) = '#indexName#'"

				actual = g.$query(query = info, dbtype = "query", sql = sql)

				// Added the ListLen check here for CF2018 because its cfdbinfo behaves a little differently.
				// It returns the index for multiple columns in one record where as Lucee or Boxlang returns multiple.
				if(isLucee || isBoxLang) {
					expect(actual.recordCount).toBe(2)
				} else {
					expect(ListLen(actual['column_name'][1])).toBe(2)
				}

				expect(actual.non_unique).toBeTrue()
			})
		})

		describe("Tests addRecord", () => {
			
			it("inserts row into table", () => {
				tableName = "dbm_addrecord_tests"
				recordValue = "#RandRange(0, 99)# bottles of beer on the wall..."

				t = migration.createTable(name = tableName, force = true)
				t.string(columnNames = "beers")
				t.timeStamps()
				t.create()
				migration.addRecord(table = tableName, beers = recordValue)
				actual = g.$query(
					datasource = application.wheels.dataSourceName,
					sql = "SELECT * FROM #tableName# WHERE beers = '#recordValue#'"
				)

				migration.dropTable(tableName)
				expect(actual.recordcount).toBe(1)
			})
		})

		describe("Tests announce", () => {

			it("is appending announcements", () => {
				request.$wheelsMigrationOutput = ""

				napalm = "I love the smell of napalm in the morning!"
				truth = "You can't handle the truth!"

				migration.announce(napalm)
				migration.announce(truth)

				actual = request.$wheelsMigrationOutput
				expected = napalm & Chr(13) & truth & Chr(13)

				expect(actual).toBe(expected)
			})
		})

		describe("Tests changeColumn", () => {

			it("is changing column", () => {
				tableName = "dbm_changecolumn_tests"
				columnName = "stringcolumn"

				t = migration.createTable(name = tableName, force = true)
				t.string(columnNames = columnName, limit = 10, allowNull = true)
				t.create()

				migration.changeColumn(
					table = tableName,
					columnName = columnName,
					columnType = 'string',
					limit = 50,
					allowNull = false,
					default = "foo"
				)

				info = g.$dbinfo(datasource = application.wheels.dataSourceName, table = tableName, type = "columns")
				migration.dropTable(tableName)
				sql = "SELECT * FROM query WHERE LOWER(column_name) = '#columnName#'"
				actual = g.$query(query = info, dbtype = "query", sql = sql)

				expect(actual.column_size).toBe(50)

				if (ListFindNoCase(actual.columnList, "is_nullable")) {
					expect(actual.is_nullable).toBeFalse()
				} else {
					expect(actual.nullable).toBeFalse()
				}
				if (ListFindNoCase(actual.columnList, "default_value")) {
					expect(actual.default_value).toInclude("bar")
				} else if (structKeyExists(server, "boxlang")) {
					expect(actual.COLUMN_DEF).toInclude("foo")
				} else {
					expect(actual.column_default_value).toInclude("foo")
				}
			})
		})

		describe("Tests createTable", () => {

			it("generates table", () => {
				tableName = "dbm_createtable_tests"
				t = migration.createTable(name = tableName, force = true)
				t.string(columnNames = 'stringcolumn, secondstringcolumn ', limit = 255) // notice the untrimmed column name
				t.text(columnNames = 'textcolumn')
				t.boolean(columnNames = 'booleancolumn', default = false, allowNull = false)
				t.integer(columnNames = 'integercolumn', default = 0)
				t.binary(columnNames = "binarycolumn")
				t.date(columnNames = "datecolumn")
				t.dateTime(columnNames = "datetimecolumn")
				t.time(columnNames = "timecolumn")
				t.decimal(columnNames = "decimalcolumn")
				t.float(columnNames = "floatcolumn")
				// TODO: this datatype doesnt work on sqlserver
				// t.bigInteger(columnNames="bigintegercolumn", default=0)
				t.timeStamps()
				t.create()

				actual = ListSort(g.model(tableName).findAll().columnList, "text")
				expected = ListSort(
					"id,stringcolumn,secondstringcolumn,textcolumn,booleancolumn,integercolumn,binarycolumn,datecolumn,datetimecolumn,timecolumn,decimalcolumn,floatcolumn,createdat,updatedat,deletedat",
					"text"
				)

				migration.dropTable(tableName)

				expect(actual).toBe(expected)
			})

			it("generates table using MicrosoftSQLServer_datatypes", () => {
				tableName = "dbm_createtable_sqlserver_tests"
				if (migration.adapter.adapterName() eq "MicrosoftSQLServer") {
					t = migration.createTable(name = tableName, force = true)
					t.char(columnNames = "charcolumn")
					t.uniqueIdentifier(columnNames = "uniqueidentifiercolumn")
					t.create()
					actual = ListSort(g.model(tableName).findAll().columnList, "text")
					expected = ListSort("id,charcolumn,uniqueidentifiercolumn", "text")
					migration.dropTable(tableName)

					expect(actual).toBe(expected)
				}
			})
		})

		describe("Tests createView", () => {

			it("generates view", () => {
				viewName = "dbm_createview"
				// only supported with these adapters
				if (ListFindNoCase("MicrosoftSQLServer", migration.adapter.adapterName())) {
					v = migration.createView(name = viewName)
					v.selectStatement(sql = "SELECT * FROM c_o_r_e_users")
					v.create()

					info = g.$dbinfo(datasource = application.wheels.dataSourceName, type = "tables")
					migration.dropView(viewName)

					actual = g.$query(
						query = info,
						dbtype = "query",
						sql = "SELECT * FROM query WHERE table_name = '#viewName#' AND table_type = 'VIEW'"
					)

					expect(actual.recordcount).toBe(1)
				}
			})
		})

		describe("Tests dropForeignKey", () => {

			it("drops a foreign key constraint", () => {
				tableName = "dbm_dfk_foos"
				referenceTableName = "dbm_dfk_bars"

				t = migration.createTable(name = tableName, force = true)
				t.integer(columnNames = "barid")
				t.create()

				t = migration.createTable(name = referenceTableName, force = true)
				t.integer(columnNames = "integercolumn")
				t.create()

				migration.addForeignKey(
					table = tableName,
					referenceTable = referenceTableName,
					column = 'barid',
					referenceColumn = "id"
				)

				info = g.$dbinfo(datasource = application.wheels.dataSourceName, table = referenceTableName, type = "foreignkeys")


				sql = "SELECT * FROM query WHERE LOWER(fktable_name) = '#tableName#' AND LOWER(fkcolumn_name) = 'barid' AND LOWER(pkcolumn_name) = 'id'"

				created = g.$query(query = info, dbtype = "query", sql = sql)

				migration.dropForeignKey(table = tableName, keyName = "FK_#tableName#_#referenceTableName#")
				info = g.$dbinfo(datasource = application.wheels.dataSourceName, table = referenceTableName, type = "foreignkeys")
				dropped = g.$query(query = info, dbtype = "query", sql = sql)

				migration.dropTable(tableName)
				migration.dropTable(referenceTableName)

				expect(created.recordcount).toBe(1)
				expect(dropped.recordcount).toBe(0)
			})
		})

		describe("Tests dropTable", () => {

			it("drops table", () => {
				tableName = "dbm_droptable_tests"

				t = migration.createTable(name = tableName, force = true)
				t.string(columnNames = "foo")
				t.timeStamps()
				t.create()

				migration.dropTable(name = tableName)

				expect(function() {
					g.$query(datasource = application.wheels.dataSourceName, sql = "SELECT * FROM #tableName#")
				}).toThrow("database")
			})
		})

		describe("Tests dropView", () => {

			it("drops view", () => {
				viewName = "dbm_dropview"
				// only supported with these adapters
				if (ListFindNoCase("MicrosoftSQLServer", migration.adapter.adapterName())) {
					v = migration.createView(name = viewName)
					v.selectStatement(sql = "SELECT * FROM c_o_r_e_users")
					v.create()
					info = g.$dbinfo(datasource = application.wheels.dataSourceName, type = "tables")
					created = g.$query(
						query = info,
						dbtype = "query",
						sql = "SELECT * FROM query WHERE table_name = '#viewName#' AND table_type = 'VIEW'"
					)

					migration.dropView(viewName)
					info = g.$dbinfo(datasource = application.wheels.dataSourceName, type = "tables")
					dropped = g.$query(
						query = info,
						dbtype = "query",
						sql = "SELECT * FROM query WHERE table_name = '#viewName#' AND table_type = 'VIEW'"
					)

					expect(created.recordcount).toBe(1)
					expect(dropped.recordcount).toBe(0)
				}
			})
		})

		describe("Tests execute", () => {

			it("runs query", () => {
				tableName = "dbm_execute_tests"

				t = migration.createTable(name = tableName, force = true)
				t.string(columnNames = "film")
				t.timeStamps()
				t.create()

				migration.addRecord(table = tableName, film = "The Phantom Menace")
				migration.addRecord(table = tableName, film = "The Clone Wars")
				migration.addRecord(table = tableName, film = "Revenge of the Sith")

				migration.execute("DELETE FROM #tableName#")

				actual = g.$query(datasource = application.wheels.dataSourceName, sql = "SELECT * FROM #tableName#")

				migration.dropTable(tableName)

				expect(actual.recordcount).toBe(0)
			})
		})

		describe("Tests removeColumn", () => {

			it("drops column from table", () => {
				tableName = "dbm_removecolumn_tests"
				t = migration.createTable(name = tableName, force = true)
				t.string(columnNames = "stringcolumn")
				t.date(columnNames = "datecolumn")
				t.create()

				migration.removeColumn(table = tableName, columnName = 'datecolumn')
				info = g.$dbinfo(datasource = application.wheels.dataSourceName, table = tableName, type = "columns")
				actual = ValueList(info.column_name)
				expected = "datecolumn"
				migration.dropTable(tableName)

				expect(ListFindNoCase(actual, expected)).toBeFalse()
			})
		})

		describe("Tests removeIndex", () => {

			beforeEach(() => {
				isACF2016 = application.wheels.serverName == "Adobe Coldfusion" && application.wheels.serverVersionMajor == 2016
				isPostgres = migration.adapter.adapterName() == "PostgreSQL"
				isLucee = application.wheels.serverName == "Lucee"
				isBoxLang = application.wheels.serverName == "BoxLang"
			})

			it("removes an index", () => {
				if (isACF2016 && isPostgres) {
					return
				}
				tableName = "dbm_removeindex_tests"
				indexName = "idx_to_remove"
				t = migration.createTable(name = tableName, force = true)
				t.integer(columnNames = "integercolumn")
				t.create()

				migration.addIndex(table = tableName, columnNames = 'integercolumn', indexName = indexName)
				info = g.$dbinfo(datasource = application.wheels.dataSourceName, table = tableName, type = "index")
				sql = "SELECT * FROM query WHERE LOWER(index_name) = '#indexName#'"
				created = g.$query(query = info, dbtype = "query", sql = sql)

				migration.removeIndex(table = tableName, indexName = indexName)
				info = g.$dbinfo(datasource = application.wheels.dataSourceName, table = tableName, type = "index")
				removed = g.$query(query = info, dbtype = "query", sql = sql)

				migration.dropTable(tableName)

				expect(created.recordcount).toBe(1)
				expect(removed.recordcount).toBe(0)
			})
		})

		describe("Tests removeRecord", () => {

			it("deletes rows from table", () => {
				tableName = "dbm_removerecord_tests"

				t = migration.createTable(name = tableName, force = true)
				t.string(columnNames = "beatle")
				t.timeStamps()
				t.create()

				migration.addRecord(table = tableName, beatle = "John")
				migration.addRecord(table = tableName, beatle = "Paul")
				migration.addRecord(table = tableName, beatle = "George")
				migration.addRecord(table = tableName, beatle = "Ringo")

				migration.removeRecord(table = tableName, where = "beatle IN ('John','George')")

				actual = g.$query(datasource = application.wheels.dataSourceName, sql = "SELECT * FROM #tableName#")

				migration.dropTable(tableName)

				expect(actual.recordcount).toBe(2)
			})
		})

		describe("Tests renameColumn", () => {

			it("renames column", () => {
				tableName = "dbm_renamecolumn_tests"
				oldColumnName = "oldcolumn"
				newColumnName = "newcolumn"
				t = migration.createTable(name = tableName, force = true)
				t.string(columnNames = oldColumnName)
				t.create()
				migration.renameColumn(table = tableName, columnName = oldColumnName, newColumnName = newColumnName)

				actual = g.model(tableName).findAll().columnList

				migration.dropTable(tableName)

				expected = newColumnName

				expect(ListFindNoCase(actual, expected)).toBeTrue()
			})
		})

		describe("Tests renameTable", () => {

			it("renames table", () => {
				oldTableName = "dbm_renametable_tests"
				newTableName = "dbm_new_renametable_tests"

				t = migration.createTable(name = oldTableName, force = true)
				t.string(columnNames = "stringcolumn")
				t.create()
				migration.renameTable(oldName = oldTableName, newName = newTableName)

				expect(function() {
					g.model(oldTableName).findAll()
				}).toThrow("Wheels.TableNotFound")

				result = g.model(newTableName).findAll()
				migration.dropTable(newTableName)

				expect(result.recordcount).toBe(0)
			})
		})

		describe("Tests updateRecord", () => {

			it("updates a table row", () => {
				tableName = "dbm_updaterecord_tests"
				oldValue = "All you need is love"
				newValue = "Love is all you need"

				t = migration.createTable(name = tableName, force = true)
				t.string(columnNames = "lyric")
				t.timeStamps()
				t.create()

				migration.addRecord(table = tableName, lyric = oldValue)
				migration.updateRecord(table = tableName, lyric = newValue, where = "lyric = '#oldValue#'")

				actual = g.$query(datasource = application.wheels.dataSourceName, sql = "SELECT lyric FROM #tableName#")
				expected = newValue

				migration.dropTable(tableName)

				expect(actual.lyric).toBe(expected)
			})
		})
	}
}