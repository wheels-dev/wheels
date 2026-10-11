/**
 * A post whose "child posts" are the posts with authorId = this post's id. The fixtures only have one
 * soft-delete table, so this pairs it with itself to give a soft-delete parent soft-delete children.
 */
component extends="Model" {

	function config() {
		table("c_o_r_e_posts");
		hasMany(name = "childPosts", modelName = "post", foreignKey = "authorId", dependent = "delete");
	}

}
