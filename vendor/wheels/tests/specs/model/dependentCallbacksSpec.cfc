/**
 * delete(callbacks = false) covers the dependent deletes and removes it triggers (the children's
 * find, write and transaction callbacks, for hasMany and hasOne), and an invalid
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
				request.$depLog = [];
				author.delete(callbacks = false, transaction = "rollback");
				expect(ArrayLen(request.$depLog)).toBe(0);
			});

			it("removes dependents without their callbacks when callbacks = false", () => {
				var author = variables.g.model("depAuthorRemove").findByKey(variables.authorId);
				request.$depLog = [];
				author.delete(callbacks = false, transaction = "rollback");
				expect(ArrayLen(request.$depLog)).toBe(0);
			});

			it("skips a hasOne dependent's callbacks with callbacks = false, for every dependent value", () => {
				var parents = ["depAuthorOneDelete", "depAuthorOneDeleteAll", "depAuthorOneRemove", "depAuthorOneRemoveAll"];
				var logged = {};
				for (var parent in parents) {
					var author = variables.g.model(parent).findByKey(variables.authorId);
					request.$depLog = [];
					author.delete(callbacks = false, transaction = "rollback");
					logged[parent] = ArrayToList(request.$depLog);
				}
				for (var parent in parents) {
					expect(logged[parent]).toBe("", parent);
				}
			});

			it("still runs the dependents' callbacks with callbacks = true", () => {
				var deleting = variables.g.model("depAuthorDelete").findByKey(variables.authorId);
				request.$depLog = [];
				deleting.delete(transaction = "rollback");
				var deleted = ArrayToList(request.$depLog);
				expect(deleted).toInclude("find");
				expect(deleted).toInclude("delete");
				expect(deleted).toInclude("rollback");
				var removing = variables.g.model("depAuthorRemove").findByKey(variables.authorId);
				request.$depLog = [];
				removing.delete(transaction = "rollback");
				expect(ArrayToList(request.$depLog)).toInclude("save");
				var one = variables.g.model("depAuthorOneDeleteAll").findByKey(variables.authorId);
				request.$depLog = [];
				one.delete(transaction = "rollback");
				var oneLogged = ArrayToList(request.$depLog);
				expect(oneLogged).toInclude("find");
				expect(oneLogged).toInclude("delete");
				expect(oneLogged).toInclude("rollback");
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
