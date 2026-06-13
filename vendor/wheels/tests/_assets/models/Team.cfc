component extends="Model" {

	function config() {
		table("c_o_r_e_teams");
		hasMany(name = "memberTeams");
		// Far-side leg of Member's explicit `through` override ("squad,rosterEntries").
		hasMany(name = "rosterEntries", modelName = "MemberTeam");
		// This-model through chain: ListFirst("memberTeams,member") IS an association
		// on Team, so $expandThroughAssociations rewrites the include into the nested
		// form "memberTeams(member)" (the preserved PR #449 behavior — the IF-side of
		// the issue #3109 gate).
		hasMany(name = "squadMembers", modelName = "Member", through = "memberTeams,member");
	}

}
