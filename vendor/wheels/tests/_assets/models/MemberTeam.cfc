component extends="Model" {

	function config() {
		table("c_o_r_e_memberteams");
		belongsTo("member");
		belongsTo("team");
		// Opposite-side leg of Member's explicit `through` override ("squad,rosterEntries").
		belongsTo(name = "squad", modelName = "Team", foreignKey = "teamid");
	}

}
