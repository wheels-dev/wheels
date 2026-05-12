component extends="Model" {

	function config() {
		table("c_o_r_e_polyarticles");
		hasMany(name="polyComments", modelName="PolyComment", as="commentable");
	}

}
