component extends="wheels.tests.Test" {

	function setup() {
		// we can only test h2 as the alt dsn.. the tables are not created in populate.cfm otherwise
		altDatasource = "wheelstestdb_h2";
		isTestable = true;
		if (application.wheels.dataSourceName eq altDatasource) {
			isTestable = false;
		} else if (application.wheels.serverName contains "Coldfusion") {
			// seems ACF can't handle H2 datasources
			isTestable = false;
		}
	}

	function db_setup() {
		// ensure the authors table exists in the alt datasource
		$query(
			sql = "
				CREATE TABLE IF NOT EXISTS authors
				(
					id int NOT NULL IDENTITY
					,firstname varchar(100) NOT NULL
					,lastname varchar(100) NOT NULL
					,PRIMARY KEY(id)
				);
			",
			datasource = altDatasource
		);
		firstName = "Troll";
		$query(
			sql = "INSERT INTO authors (firstName, lastName) VALUES ('#firstName#', 'Dolls');",
			datasource = altDatasource
		);
		finderArgs = {where = "firstName = '#firstName#'", datasource = altDatasource};
	}

	function test_findall_respects_model_config_datasource() {
		if (!isTestable) return;
		transaction {
			this.db_setup();
			// ensure this is using the wheelstestdb_h2 as defined in the model config
			actual = model("AuthorAlternateDatasource").findAll(where = "firstName = '#firstName#'");
			TransactionRollback();
		}
		assert("actual.recordCount");
	}

	function test_findall_with_datasource_argument() {
		if (!isTestable) return;
		transaction {
			this.db_setup();
			defaultDBRows = model("Author").findAll(where = "firstName = '#firstName#'");
			actual = model("Author").findAll(argumentCollection = finderArgs);
			TransactionRollback();
		}
		assert("actual.recordCount");
		// sanity check that there are no rows in the default db
		assert("defaultDBRows.recordCount eq 0");
	}

	function test_findOne_with_datasource_argument() {
		if (!isTestable) return;
		transaction {
			this.db_setup();
			actual = model("Author").findOne(argumentCollection = finderArgs);
			TransactionRollback();
		}
		assert("IsObject(actual)");
	}

	function test_findFirst_with_datasource_argument() {
		if (!isTestable) return;
		transaction {
			this.db_setup();
			actual = model("Author").findFirst(argumentCollection = finderArgs);
			TransactionRollback();
		}
		assert("IsObject(actual)");
	}

	function test_findLastOne_with_datasource_argument() {
		if (!isTestable) return;
		transaction {
			this.db_setup();
			actual = model("Author").findLastOne(argumentCollection = finderArgs);
			TransactionRollback();
		}
		assert("IsObject(actual)");
	}

	function test_count_with_datasource_argument() {
		if (!isTestable) return;
		transaction {
			this.db_setup();
			actual = model("Author").count(argumentCollection = finderArgs);
			TransactionRollback();
		}
		assert("actual gt 0");
	}

	function test_exists_with_datasource_argument() {
		if (!isTestable) return;
		transaction {
			this.db_setup();
			actual = model("Author").exists(argumentCollection = finderArgs);
			TransactionRollback();
		}
		assert("actual eq true");
	}

}
