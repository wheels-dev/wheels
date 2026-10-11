// A polymorphic hasMany whose child model doesn't exist, so its columns can't be read.
component extends="Model" {

	function config() {
		table("c_o_r_e_uautoposts");
		hasMany(name = "ghosts", as = "haunted", modelName = "UNoSuchChildModel");
	}

}
