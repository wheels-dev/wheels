component extends="Model" {

	function config() {
		afterFind("afterFindCallback");
	}

	function afterFindCallback() {
		arguments.method = "done";
		return arguments;
	}

}
