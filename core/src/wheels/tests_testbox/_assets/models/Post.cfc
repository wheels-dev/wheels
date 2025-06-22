component extends="Model" {

	function config() {
		belongsTo("author");
		hasMany("comments");
		hasMany("classifications");
		validatesUniquenessOf("title");
		property(name = "titleAlias", sql = "title", select = false);
		property(name = "firstId", sql = "MAX(posts.id)", select = false);
		property(name = "createdAtAlias", sql = "posts.createdat", dataType = "datetime", select = false);
	}

	function afterFindCallback() {
		if (StructIsEmpty(arguments)) {
			this.title = "setTitle";
			this.views = this.views + 100;
			this.something = "hello world";
		} else {
			arguments.title = "setTitle";
			arguments.views = arguments.views + 100;
			arguments.something = "hello world";
			return arguments;
		}
	}

	function getClass() {
		return variables.wheels.class;
	};

}
