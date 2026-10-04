/**
 * A date object passed to the query builder or a dynamic finder compares as a date on a
 * datetime column, on every database. (A CFML date used to reach the SQL as its
 * `{ts '...'}` literal, which matches nothing where the column is compared as text.)
 *
 * Each check creates its own rows from date objects, in a year no fixture uses, and rolls
 * them back.
 */
component extends="wheels.WheelsTest" {

	function run() {

		g = application.wo;

		describe("query builder and dynamic finders with date values", () => {

			it("where() with a date and >= / < finds the rows on each side", () => {
				var state = {onOrAfter = -1, before = -1};
				transaction action="begin" {
					seedProfiles();
					state.onOrAfter = g.model("profile")
						.where("dateOfBirth", ">=", CreateDateTime(2031, 6, 1, 0, 0, 0))
						.where("dateOfBirth", "<", CreateDateTime(2032, 1, 1, 0, 0, 0))
						.count();
					state.before = g.model("profile")
						.where("dateOfBirth", ">=", CreateDateTime(2031, 1, 1, 0, 0, 0))
						.where("dateOfBirth", "<", CreateDateTime(2031, 6, 1, 0, 0, 0))
						.count();
					transaction action="rollback";
				}
				expect(state.onOrAfter).toBe(1);
				expect(state.before).toBe(1);
			});

			it("whereBetween() with dates finds the row in the range", () => {
				var state = {bio = []};
				transaction action="begin" {
					seedProfiles();
					var rows = g.model("profile").whereBetween("dateOfBirth", CreateDate(2031, 6, 1), CreateDate(2031, 7, 1)).get();
					for (var row in rows) {
						ArrayAppend(state.bio, row.bio);
					}
					transaction action="rollback";
				}
				expect(state.bio).toBe(["dated June 2031"]);
			});

			it("whereIn() with dates finds the matching row", () => {
				var state = {count = -1};
				transaction action="begin" {
					seedProfiles();
					state.count = g.model("profile")
						.whereIn("dateOfBirth", [CreateDateTime(2031, 5, 10, 10, 0, 0), CreateDateTime(2031, 5, 11, 10, 0, 0)])
						.count();
					transaction action="rollback";
				}
				expect(state.count).toBe(1);
			});

			it("a dynamic finder with a date finds the row", () => {
				var state = {bio = ""};
				transaction action="begin" {
					seedProfiles();
					var profile = g.model("profile").findOneByDateOfBirth(CreateDateTime(2031, 6, 15, 12, 0, 0));
					state.bio = IsObject(profile) ? profile.bio : "(not found)";
					transaction action="rollback";
				}
				expect(state.bio).toBe("dated June 2031");
			});

			it("leaves a date written as a string unchanged", () => {
				var state = {count = -1};
				transaction action="begin" {
					seedProfiles();
					state.count = g.model("profile")
						.where("dateOfBirth", ">=", DateTimeFormat(CreateDateTime(2031, 6, 1, 0, 0, 0), "yyyy-mm-dd HH:nn:ss"))
						.where("dateOfBirth", "<", DateTimeFormat(CreateDateTime(2032, 1, 1, 0, 0, 0), "yyyy-mm-dd HH:nn:ss"))
						.count();
					transaction action="rollback";
				}
				expect(state.count).toBe(1);
			});

		});

	}

	private void function seedProfiles() {
		g.model("profile").create(dateOfBirth = CreateDateTime(2031, 5, 10, 10, 0, 0), bio = "dated May 2031");
		g.model("profile").create(dateOfBirth = CreateDateTime(2031, 6, 15, 12, 0, 0), bio = "dated June 2031");
	}

}
