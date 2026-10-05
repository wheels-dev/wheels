/**
 * clearChangeInformation(property = "x") resets the change baseline for x only: every other property
 * keeps reporting whether it changed, and a later save writes only what really changed.
 */
component extends="wheels.WheelsTest" {

	function run() {

		g = application.wo;

		describe("clearChangeInformation() for one property", () => {

			it("leaves the other properties' change tracking alone", () => {
				var post = g.model("post").findOne(order = "id");
				post.title = "Changed title";
				post.body = "Changed body";
				post.clearChangeInformation(property = "title");
				expect(post.hasChanged("title")).toBeFalse();
				expect(post.hasChanged("body")).toBeTrue();
				expect(post.hasChanged("views")).toBeFalse("views was never touched");
				expect(post.changedProperties()).toBe("body");
			});

			it("keeps a later save to the properties that really changed", () => {
				var state = {};
				transaction {
					var post = g.model("post").findOne(order = "id");
					post.title = "Changed title " & CreateUUID();
					post.views = post.views + 1;
					post.clearChangeInformation(property = "title");
					post.save(transaction = "none");
					state.saved = ListSort(post.savedChangedProperties(), "textnocase");
					transaction action="rollback";
				}
				// views, plus the updatedAt the update sets; nothing that wasn't changed.
				expect(state.saved).toBe("updatedat,views");
			});

		});

	}

}
