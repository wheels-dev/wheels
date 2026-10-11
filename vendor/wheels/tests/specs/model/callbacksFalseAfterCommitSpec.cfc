/**
 * `callbacks = false` on save() / delete() also skips afterCommit and afterRollback, like every other
 * callback. A save that changes nothing still queues afterCommit (unchanged, documented). The test
 * runner uses transactionMode = "none", so specs pass `transaction` explicitly.
 */
component extends="wheels.WheelsTest" {

	function beforeAll() {
		variables.g = application.wo;
	}

	function run() {

		describe("callbacks = false and the commit callbacks", () => {

			beforeEach(() => {
				request.$acLog = [];
				variables.g.model("tag").$registerCallback(type = "afterCommit", methods = "recordAfterCommit");
				variables.g.model("tag").$registerCallback(type = "afterRollback", methods = "recordAfterRollback");
			});

			afterEach(() => {
				variables.g.model("tag").$clearCallbacks(type = "afterCommit");
				variables.g.model("tag").$clearCallbacks(type = "afterRollback");
				variables.g.model("tag").deleteAll(where = "name LIKE 'cbfalse-%'", instantiate = false, callbacks = false, transaction = "commit");
			});

			it("skips afterCommit on a create with callbacks = false", () => {
				variables.g.model("tag").new(name = "cbfalse-create").save(callbacks = false, transaction = "commit");
				expect(ArrayLen(request.$acLog)).toBe(0);
			});

			it("skips afterCommit on an update with callbacks = false", () => {
				var t = variables.g.model("tag").new(name = "cbfalse-update");
				t.save(callbacks = false, transaction = "commit");
				t.name = "cbfalse-update-2";
				t.save(callbacks = false, transaction = "commit");
				expect(ArrayLen(request.$acLog)).toBe(0);
			});

			it("skips afterCommit on a delete with callbacks = false", () => {
				var t = variables.g.model("tag").new(name = "cbfalse-delete");
				t.save(callbacks = false, transaction = "commit");
				t.delete(callbacks = false, transaction = "commit");
				expect(ArrayLen(request.$acLog)).toBe(0);
			});

			it("skips afterRollback on a rolled-back save with callbacks = false", () => {
				variables.g.model("tag").new(name = "cbfalse-rollback").save(callbacks = false, transaction = "rollback");
				expect(ArrayLen(request.$acLog)).toBe(0);
			});

			it("still puts back savedChanges() when a callbacks = false save rolls back", () => {
				var t = variables.g.model("tag").new(name = "cbfalse-saved");
				t.save(callbacks = false, transaction = "commit");
				var before = Duplicate(t.savedChanges());
				t.name = "cbfalse-saved-undone";
				t.save(callbacks = false, transaction = "rollback");
				expect(t.savedChanges()).toBe(before);
				expect(ArrayLen(request.$acLog)).toBe(0);
			});

			it("still runs them with callbacks = true", () => {
				var t = variables.g.model("tag").new(name = "cbfalse-on");
				t.save(transaction = "commit");
				t.delete(transaction = "commit");
				variables.g.model("tag").new(name = "cbfalse-on-rb").save(transaction = "rollback");
				expect(ArrayToList(request.$acLog)).toBe("commit:cbfalse-on,commit:cbfalse-on,rollback:cbfalse-on-rb");
			});

			it("still queues afterCommit for a save that changes nothing", () => {
				var t = variables.g.model("tag").new(name = "cbfalse-nochange");
				t.save(transaction = "commit");
				request.$acLog = [];
				t.save(transaction = "commit");
				expect(ArrayLen(request.$acLog)).toBe(1);
			});

		});

	}

}
