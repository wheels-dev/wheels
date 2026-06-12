component extends="Model" {

	function config() {
		table("c_o_r_e_members");
		// Many-to-many shortcut: `member.teams()` reaches Team objects through the
		// memberteams join model. Declaring `shortcut` must NOT break the plain
		// `member.memberTeams()` association or `include="memberTeams"` (issue #3109).
		hasMany(name = "memberTeams", shortcut = "teams");
	}

}
