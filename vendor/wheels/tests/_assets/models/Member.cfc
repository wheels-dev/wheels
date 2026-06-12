component extends="Model" {

	function config() {
		table("c_o_r_e_members");
		// Many-to-many shortcut: `member.teams()` reaches Team objects through the
		// memberteams join model. Declaring `shortcut` must NOT break the plain
		// `member.memberTeams()` association or `include="memberTeams"` (issue #3109).
		hasMany(name = "memberTeams", shortcut = "teams");
		// Explicit `through` override (see the @through docstring in associations.cfc):
		// a second association over the same join table whose names don't follow
		// singular/plural convention. The chain runs from the opposite side
		// ("squad" on MemberTeam, then "rosterEntries" on Team), so include
		// expansion must leave `rosterSpots` untouched — "squad" is not an
		// association on Member (issue #3109, explicit-override form).
		hasMany(
			name = "rosterSpots",
			modelName = "MemberTeam",
			shortcut = "squads",
			through = "squad,rosterEntries"
		);
	}

}
