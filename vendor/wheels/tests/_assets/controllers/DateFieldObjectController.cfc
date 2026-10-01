component extends="Controller" {
	post = model("Post").findOne(order = "id");
}
