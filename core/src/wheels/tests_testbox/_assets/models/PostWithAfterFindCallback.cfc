component extends="Model" {

	function config() {
		table("posts");
		belongsTo("author");
		hasMany("comments");
		hasMany("classifications");
		afterFind("afterFindCallback");
	}

	function afterFindCallback() {
		arguments.title = "setTitle";
		arguments.views = arguments.views + 100;
		arguments.something = "hello world";
		return arguments;
	}

}
