component extends="Model" {

	function config() {
		table("tags");
		afterCreate("createWelcomePost");
	}

	function createWelcomePost() {
		var objPost = model("Post").create(authorId = 1, title = "Welcome", body = "This is my first post", views = 0);
		if (IsObject(objPost)) {
			return true;
		}
		return false;
	}

	function crashMe() {
		var foo = 1 / 0;
	}

}
