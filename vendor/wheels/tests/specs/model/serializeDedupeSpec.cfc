component extends="wheels.WheelsTest" {

	function run() {

		describe("query serialization duplicate handling", () => {

			it("returns one item per query row when include is empty even if rows are identical", () => {
				model("author").create(firstName = "Dupe", lastName = "SerializeDedupeSpec");
				model("author").create(firstName = "Dupe", lastName = "SerializeDedupeSpec");
				try {
					// Without include there are no joins, so identical rows (possible here because the
					// select list excludes the primary key) must not be collapsed into one.
					var authors = model("author").findAll(
						select = "firstName,lastName",
						where = "lastName = 'SerializeDedupeSpec'",
						returnAs = "structs",
						reload = true
					);
					expect(StructCount(authors)).toBe(2);
				} finally {
					model("author").deleteAll(where = "lastName = 'SerializeDedupeSpec'");
				}
			})

			it("still removes join-duplicated rows when include is present", () => {
				// Selecting only root columns while joining a hasMany association produces identical
				// rows (one per joined child), which the duplicate detection must still collapse.
				var authors = model("author").findAll(
					select = "id,lastName",
					where = "lastName = 'Djurner'",
					include = "posts",
					returnAs = "structs",
					reload = true
				);
				expect(StructCount(authors)).toBe(1);
			})

		})

	}
}
