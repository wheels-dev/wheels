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
	}

}
