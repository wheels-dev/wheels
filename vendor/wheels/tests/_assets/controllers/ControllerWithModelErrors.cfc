component extends="Controller" {

	user = model("user").new();
	user.addError("firstname", "firstname error1");
	user.addError("firstname", "firstname error2");
	user.addError("firstname", "firstname error2");

}
