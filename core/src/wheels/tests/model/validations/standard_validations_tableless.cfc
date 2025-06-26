component extends="standard_validations" {

	function setup() {
		/* pre-load models that will be called during test */
		model('users');
		model('post');
		oldDataSourceName = application.wheels.dataSourceName;
		application.wheels.dataSourceName = "";
		StructDelete(application.wheels.models, "UserTableless", false);
		user = model("UserTableless").new();
	}

	function teardown() {
		application.wheels.dataSourceName = oldDataSourceName;
	}

}
