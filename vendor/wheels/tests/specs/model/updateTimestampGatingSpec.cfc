component extends="wheels.WheelsTest" {

	function run() {

		g = application.wo

		describe("Tests that updatedAt stamping on update ignores the create-only setUpdatedAtOnCreate setting", () => {

			it("bumps updatedAt on update even when setUpdatedAtOnCreate is false", () => {
				var oldSetting = application.wheels.setUpdatedAtOnCreate
				var twentyDaysAgo = DateAdd("d", -20, Now())

				transaction {
					try {
						var author = g.model("author").findOne(order = "id")
						var newPost = g.model("post").create(
							authorId = author.id,
							title = "Original title",
							body = "Original body",
							transaction = "none"
						)

						// Backdate updatedAt so the stamped value is unambiguous.
						newPost.updatedAt = twentyDaysAgo

						// The setting only gates the create path; updates must keep stamping.
						application.wheels.setUpdatedAtOnCreate = false
						newPost.update(title = "Changed title", transaction = "none")

						expect(DateDiff("d", twentyDaysAgo, newPost.updatedAt)).toBeGTE(19)
					} finally {
						application.wheels.setUpdatedAtOnCreate = oldSetting
					}
					transaction action="rollback";
				}
			})

			it("bumps updatedAt on update when setUpdatedAtOnCreate is true", () => {
				var twentyDaysAgo = DateAdd("d", -20, Now())

				transaction {
					var author = g.model("author").findOne(order = "id")
					var newPost = g.model("post").create(
						authorId = author.id,
						title = "Original title",
						body = "Original body",
						transaction = "none"
					)

					newPost.updatedAt = twentyDaysAgo
					newPost.update(title = "Changed title", transaction = "none")

					expect(DateDiff("d", twentyDaysAgo, newPost.updatedAt)).toBeGTE(19)

					transaction action="rollback";
				}
			})

		})
	}
}
