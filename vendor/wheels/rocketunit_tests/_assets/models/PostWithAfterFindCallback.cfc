component extends="Model" {

	function config() {
		table("c_o_r_e_posts");
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
