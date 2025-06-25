component extends="Controller" {

	author = model("author").findOne(where = "lastname = 'Djurner'", include = "profile");
	author.posts = author.posts(include = "_c_o_r_e_comments", returnAs = "objects");

}
