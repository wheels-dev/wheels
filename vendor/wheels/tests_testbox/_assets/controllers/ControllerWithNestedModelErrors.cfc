component extends="Controller" {

	user = model("user").new();
	user.author = model("author").findOne(include = "profile");

	user.addError("firstname", "firstname error1");
	user.author.addError("lastname", "lastname error1");
	user.author.profile.addError("age", "age error1");

}
