component extends="Model" {

	function config() {
		hasMany(name = "galleries");
		hasOne(name = "combikey");
		hasOne(name = "author", foreignKey = "firstName", joinKey = "firstName");
		hasMany(name = "authors", foreignKey = "firstName", joinKey = "firstName");
		hasMany(name = "combikeys");
		hasMany(name = "outerjoinphotogalleries", modelName = "gallery", jointype = "outer");
		validatesPresenceOf("username, password, firstname, lastname");
		validatesUniquenessOf("username");
		validatesLengthOf(
			property = "username",
			minimum = "4",
			maximum = "20",
			when = "onCreate",
			message = "Please shorten your [property] please. [maximum] characters is the maximum length allowed."
		);
		validatesLengthOf(property = "password", minimum = "4", when = "onUpdate");
		validate("validateCalled");
		validateOnCreate("validateOnCreateCalled");
		validateOnUpdate("validateOnUpdateCalled");
		local.db_info = $dbinfo(datasource = application.wheels.dataSourceName, type = "version");
		local.db = LCase(
			Replace(
				local.db_info.database_productname,
				" ",
				"",
				"all"
			)
		);
		property(
			name = "salesTotal",
			sql = "SUM(birthDayMonth)",
			select = false,
			dataType = "int"
		);
	}

	function validateCalled() {
		this._validateCalled = true;
	}

	function validateOnCreateCalled() {
		this._validateOnCreateCalled = true;
	}

	function validateOnUpdateCalled() {
		this._validateOnUpdateCalled = true;
	}

}
