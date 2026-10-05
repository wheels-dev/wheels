/**
 * delete(callbacks = false) covers the dependent deletes and removes it triggers, and an invalid
 * `dependent` value fails when the association is declared rather than at the first delete. Each
 * delete runs with transaction = "rollback", so the seeded rows are kept.
 */
component extends="wheels.WheelsTest" {

	function beforeAll() {
		variables.g = application.wo;
		variables.authorId = variables.g.model("post").findOne(order = "id").authorId;
	}

	function failureOf(required any callback) {
		var state = {type = "", message = ""};
		var target = arguments.callback;
		try {
			target();
		} catch (any e) {
			state.type = e.type;
			state.message = e.message;
		}
		return state;
	}

	function run() {

		describe("Dependent records and callbacks = false", () => {

			beforeEach(() => {
				request.$depLog = [];
			});

			it("deletes dependents without their callbacks when callbacks = false", () => {
				var author = variables.g.model("depAuthorDelete").findByKey(variables.authorId);
				author.delete(callbacks = false, transaction = "rollback");
				expect(ArrayLen(request.$depLog)).toBe(0);
			});

			it("removes dependents without their callbacks when callbacks = false", () => {
				var author = variables.g.model("depAuthorRemove").findByKey(variables.authorId);
				author.delete(callbacks = false, transaction = "rollback");
				expect(ArrayLen(request.$depLog)).toBe(0);
			});

			it("still runs the dependents' callbacks with callbacks = true", () => {
				var deleting = variables.g.model("depAuthorDelete").findByKey(variables.authorId);
				deleting.delete(transaction = "rollback");
				expect(ArrayToList(request.$depLog)).toInclude("delete");
				request.$depLog = [];
				var removing = variables.g.model("depAuthorRemove").findByKey(variables.authorId);
				removing.delete(transaction = "rollback");
				expect(ArrayToList(request.$depLog)).toInclude("save");
			});

		});

		describe("An invalid dependent value", () => {

			it("fails when the association is declared", () => {
				var failure = failureOf(() => variables.g.model("depAuthorInvalid"));
				expect(failure.type).toBe("Wheels.InvalidArgument");
				expect(failure.message).toInclude("destroy");
			});

			it("accepts every documented value", () => {
				var post = variables.g.model("post");
				expect(failureOf(() => post.$validateDependent("delete")).type).toBe("");
				expect(failureOf(() => post.$validateDependent("deleteAll")).type).toBe("");
				expect(failureOf(() => post.$validateDependent("remove")).type).toBe("");
				expect(failureOf(() => post.$validateDependent("removeAll")).type).toBe("");
				expect(failureOf(() => post.$validateDependent(false)).type).toBe("");
			});

		});

	}

}
