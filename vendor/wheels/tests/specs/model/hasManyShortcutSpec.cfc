component extends="wheels.WheelsTest" {

	function run() {
		g = application.wo;

		describe("hasMany shortcut association (issue ##3109)", () => {

			it("leaves a shortcut's own through-chain out of include expansion", () => {
				// The `shortcut` default stores an opposite-side chain in `through`
				// ("team,memberTeams") that the shortcut dispatcher consumes — it is
				// NOT a this-model through-include. $expandThroughAssociations must
				// return the plain include unchanged because `team` is not an
				// association on Member; rewriting it to "team(memberTeams)" was the
				// root cause of the AssociationNotFound throw.
				var expanded = g.model("member").$expandThroughAssociations("memberTeams");
				expect(expanded).toBe("memberTeams");
			});

			it("resolves the plain hasMany method when a shortcut is declared", () => {
				var alice = g.model("member").findOne(where = "name = 'Alice'");
				expect(alice.memberTeams().recordCount).toBe(2);
			});

			it("eager-loads the plain hasMany via include when a shortcut is declared", () => {
				var members = g.model("member").findAll(include = "memberTeams", order = "id");
				// Alice has two join rows, Bob has one — the include join must not throw.
				expect(members.recordCount).toBe(3);
			});

			it("returns the far-side records through the shortcut method", () => {
				var alice = g.model("member").findOne(where = "name = 'Alice'");
				var teams = alice.teams();
				expect(teams.recordCount).toBe(2);
				expect(ListSort(ValueList(teams.name), "textnocase")).toBe("Blue,Red");

				var bob = g.model("member").findOne(where = "name = 'Bob'");
				expect(bob.teams().recordCount).toBe(1);
			});
		});

		describe("hasMany shortcut with an explicit through= override (issue ##3109)", () => {

			it("leaves the explicit override's through-chain out of include expansion", () => {
				// `rosterSpots` declares `through="squad,rosterEntries"` explicitly (the
				// @through override documented in associations.cfc). "squad" is an
				// association on the JOIN model, not on Member, so the gate must return
				// the plain include unchanged — exactly like the conventional default.
				var expanded = g.model("member").$expandThroughAssociations("rosterSpots");
				expect(expanded).toBe("rosterSpots");
			});

			it("resolves the plain hasMany method when an explicit through override is declared", () => {
				var alice = g.model("member").findOne(where = "name = 'Alice'");
				expect(alice.rosterSpots().recordCount).toBe(2);
			});

			it("eager-loads the plain hasMany via include when an explicit through override is declared", () => {
				var members = g.model("member").findAll(include = "rosterSpots", order = "id");
				// Alice has two join rows, Bob has one — the include join must not throw.
				expect(members.recordCount).toBe(3);
			});

			it("returns the far-side records through the overridden shortcut method", () => {
				var alice = g.model("member").findOne(where = "name = 'Alice'");
				var squads = alice.squads();
				expect(squads.recordCount).toBe(2);
				expect(ListSort(ValueList(squads.name), "textnocase")).toBe("Blue,Red");

				var bob = g.model("member").findOne(where = "name = 'Bob'");
				expect(bob.squads().recordCount).toBe(1);
				expect(bob.squads().name).toBe("Green");
			});
		});

		describe("hasMany shortcut name as an include (issue ##3208)", () => {

			it("expands a shortcut name into the nested bridge include", () => {
				// `memberTeams` declares `shortcut="teams"`, so the convenience name
				// "teams" is NOT an association on Member — it only exists as a dynamic
				// accessor. Used in `include`, it must expand into the this-model bridge
				// include "memberTeams(team)" (Member -> memberTeams -> Team) instead of
				// throwing Wheels.AssociationNotFound. ListFirst(through) ("team") is the
				// bridge model's association to the far side.
				var expanded = g.model("member").$expandThroughAssociations("teams");
				expect(expanded).toBe("memberTeams(team)");
			});

			it("eager-loads the far side through a shortcut include", () => {
				// Alice carries two join rows, Bob one — joining through the bridge to
				// Team yields one row per join row, and must not throw.
				var members = g.model("member").findAll(include = "teams", order = "id");
				expect(members.recordCount).toBe(3);
			});

			it("expands a shortcut declared with an explicit through override", () => {
				// `rosterSpots` declares `shortcut="squads"` with an explicit
				// `through="squad,rosterEntries"`. ListFirst(through) ("squad") is the
				// bridge model's association to Team, so "squads" expands to the nested
				// this-model include "rosterSpots(squad)".
				var expanded = g.model("member").$expandThroughAssociations("squads");
				expect(expanded).toBe("rosterSpots(squad)");
			});
		});

		describe("$expandThroughAssociations this-model rewrite (preserved PR ##449 behavior)", () => {

			it("rewrites a 2-element through whose first segment IS an association on the model", () => {
				// Team declares `squadMembers` with `through="memberTeams,member"`.
				// "memberTeams" IS an association on Team, so the IF-side of the
				// issue #3109 gate must keep rewriting the include into the nested
				// this-model form — the contract PR #449 introduced.
				var expanded = g.model("team").$expandThroughAssociations("squadMembers");
				expect(expanded).toBe("memberTeams(member)");
			});

			it("eager-loads via the rewritten nested include", () => {
				// Red, Blue and Green each carry exactly one join row, so the
				// rewritten "memberTeams(member)" include returns one row per team.
				var teams = g.model("team").findAll(include = "squadMembers", order = "id");
				expect(teams.recordCount).toBe(3);
			});
		});
	}

}
