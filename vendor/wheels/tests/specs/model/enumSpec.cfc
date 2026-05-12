component extends="wheels.WheelsTest" {

	function run() {

		describe("Enum Support", () => {

			describe("is*() boolean checkers", () => {

				it("isDraft() returns true for a draft post", () => {
					var post = model("postWithEnum").findOne(where = "status = 'draft'", order = "id");
					expect(IsObject(post)).toBeTrue();
					expect(post.isDraft()).toBeTrue();
				})

				it("isDraft() returns false for a published post", () => {
					var post = model("postWithEnum").findOne(where = "status = 'published'", order = "id");
					expect(post.isDraft()).toBeFalse();
				})

				it("isPublished() returns true for a published post", () => {
					var post = model("postWithEnum").findOne(where = "status = 'published'", order = "id");
					expect(post.isPublished()).toBeTrue();
				})

				it("isArchived() returns true for an archived post", () => {
					var post = model("postWithEnum").findOne(where = "status = 'archived'", order = "id");
					expect(post.isArchived()).toBeTrue();
				})

				it("isArchived() returns false for a draft post", () => {
					var post = model("postWithEnum").findOne(where = "status = 'draft'", order = "id");
					expect(post.isArchived()).toBeFalse();
				})

			})

			describe("validation", () => {

				it("rejects invalid enum values", () => {
					var post = model("postWithEnum").findOne(order = "id");
					post.status = "invalid_status";
					expect(post.valid()).toBeFalse();
				})

				it("passes validation for valid enum values", () => {
					var post = model("postWithEnum").findOne(order = "id");
					post.status = "published";
					post.valid();
					var errors = post.errorsOn("status");
					expect(ArrayLen(errors)).toBe(0);
				})

			})

			describe("auto-generated scopes", () => {

				it("draft() returns only draft posts", () => {
					var result = model("postWithEnum").draft().findAll();
					expect(result.recordcount).toBeGT(0);
					expect(result.status).toBe("draft");
				})

				it("published() returns only published posts", () => {
					var result = model("postWithEnum").published().findAll();
					expect(result.recordcount).toBeGT(0);
					expect(result.status).toBe("published");
				})

				it("archived() returns only archived posts", () => {
					var result = model("postWithEnum").archived().findAll();
					expect(result.recordcount).toBeGT(0);
					expect(result.status).toBe("archived");
				})

				it("scope counts sum to total count", () => {
					var draftCount = model("postWithEnum").draft().count();
					var publishedCount = model("postWithEnum").published().count();
					var archivedCount = model("postWithEnum").archived().count();
					var totalCount = model("postWithEnum").count();
					expect(draftCount + publishedCount + archivedCount).toBe(totalCount);
				})

			})

		})

	}
}
