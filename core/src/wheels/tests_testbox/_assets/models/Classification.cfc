component extends="Model" {

	function config() {
		belongsTo("post");
		belongsTo("tag");
	}

}
