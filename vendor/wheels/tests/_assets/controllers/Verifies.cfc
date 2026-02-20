component extends="Controller" {

	function config() {
		verifies(only = "actionGet", get = "true");
		verifies(only = "actionPost", post = "true");
		verifies(
			only = "actionPostWithRedirect",
			post = "true",
			action = "index",
			controller = "somewhere",
			error = "invalid"
		);
		verifies(
			only = "actionPostWithTypesValid",
			post = "true",
			params = "userid,authorid",
			paramsTypes = "integer,guid"
		);
		verifies(
			only = "actionPostWithTypesInValid",
			post = "true",
			params = "userid,authorid",
			paramsTypes = "integer,guid"
		);
		verifies(
			only = "actionPostWithString",
			post = "true",
			params = "username,password",
			paramsTypes = "string,blank"
		);
	}

	function actionGet() {
		renderText("actionGet");
	}

	function actionPost() {
		renderText("actionPost");
	}

	function actionPostWithRedirect() {
		renderText("actionPostWithRedirect");
	}

	function actionPostWithTypesValid() {
		renderText("actionPostWithTypesValid");
	}

	function actionPostWithTypesInValid() {
		renderText("actionPostWithTypesInValid");
	}

	function actionPostWithString() {
		renderText("actionPostWithString");
	}

}
