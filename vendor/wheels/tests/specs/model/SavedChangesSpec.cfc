/**
 * Saved-change functions (F49): savedChanges(), hasSavedChange(), savedChangeFrom() and
 * savedChangedProperties() report what the last successful save wrote, after allChanges() and its
 * siblings have been reset by that save. Each afterCommit sees the save that queued it, so two saves
 * of one object in a transaction are told apart, and an afterRollback sees the save that was undone.
 */
component extends="wheels.WheelsTest" {

	function run() {

		g = application.wo;

		describe("Saved changes", () => {

			beforeEach(() => {
				request.$scLog = [];
				request.$scAnnounced = 0;
			});

			afterEach(() => {
				g.model("tag").$clearCallbacks(type = "afterCommit");
				g.model("tag").$clearCallbacks(type = "afterRollback");
				g.model("tag").$clearCallbacks(type = "afterSave");
				g.model("tag").deleteAll(where = "name LIKE 'savedch-%'", instantiate = false, callbacks = false, transaction = "commit");
				StructDelete(request, "$scTag");
				StructDelete(request, "$scNames");
			});

			it("is empty for an object that was never saved", () => {
				var t = g.model("tag").new(name = "savedch-new");
				expect(t.savedChanges()).toBe({});
				expect(t.hasSavedChange()).toBeFalse();
				expect(t.hasSavedChange("name")).toBeFalse();
				expect(t.savedChangeFrom("name")).toBe("");
				expect(t.savedChangedProperties()).toBe("");
			});

			it("reports what a create wrote, from empty values", () => {
				var t = g.model("tag").new(name = "savedch-create");
				expect(t.save(transaction = "none")).toBeTrue();
				var saved = t.savedChanges();
				expect(saved).toHaveKey("name");
				expect(saved.name.changedFrom).toBe("");
				expect(saved.name.changedTo).toBe("savedch-create");
				expect(saved).toHaveKey("id");
				expect(saved).notToHaveKey("description", "a property the object never set wasn't written");
				expect(t.hasSavedChange("name")).toBeTrue();
				expect(ListFindNoCase(t.savedChangedProperties(), "name")).toBeGT(0);
				// The unsaved-change functions are reset by the save, as before.
				expect(t.allChanges()).toBe({});
				expect(t.hasChanged()).toBeFalse();
			});

			it("reports only the properties an update changed", () => {
				var t = g.model("tag").create(name = "savedch-before", transaction = "none");
				t.name = "savedch-after";
				t.save(transaction = "none");
				expect(StructKeyList(t.savedChanges())).toBe("name");
				expect(t.savedChangeFrom("name")).toBe("savedch-before");
				expect(t.savedChanges().name.changedTo).toBe("savedch-after");
				expect(t.hasSavedChange("description")).toBeFalse();
				expect(t.savedChangedProperties()).toBe("name");
			});

			it("is empty after a save that changed nothing", () => {
				var t = g.model("tag").create(name = "savedch-noop", transaction = "none");
				t.save(transaction = "none");
				expect(t.savedChanges()).toBe({});
				expect(t.hasSavedChange()).toBeFalse();
			});

			it("keeps the previous state when a save fails after the write", () => {
				var t = g.model("tag").create(name = "savedch-kept", transaction = "none");
				var before = Duplicate(t.savedChanges());
				g.model("tag").$registerCallback(type = "afterSave", methods = "callbackThatReturnsFalse");
				t.name = "savedch-vetoed";
				expect(t.save(transaction = "commit")).toBeFalse();
				expect(t.savedChanges()).toBe(before);
			});

			it("is cleared by reload() and clearChangeInformation(), and kept by save(reload = true)", () => {
				var t = g.model("tag").create(name = "savedch-clear", transaction = "none");
				t.reload();
				expect(t.savedChanges()).toBe({});

				t.name = "savedch-clear2";
				t.description = "d";
				t.save(transaction = "none");
				t.clearChangeInformation("description");
				expect(StructKeyList(t.savedChanges())).toBe("name");
				t.clearChangeInformation();
				expect(t.savedChanges()).toBe({});

				t.name = "savedch-clear3";
				t.save(transaction = "none", reload = true);
				expect(t.savedChangeFrom("name")).toBe("savedch-clear2");
			});

			it("is available in afterSave for the save in progress", () => {
				var t = g.model("tag").create(name = "savedch-as-before", transaction = "none");
				g.model("tag").$registerCallback(type = "afterSave", methods = "recordSavedChangesInAfterSave");
				t.name = "savedch-as-after";
				t.save(transaction = "none");
				expect(ArrayLen(request.$scLog)).toBe(1);
				expect(request.$scLog[1].changed).toBeTrue();
				expect(request.$scLog[1].from).toBe("savedch-as-before");
			});

			it("reports the inner save, outer changes included, when a callback saves the object again", () => {
				var t = g.model("tag").create(name = "savedch-nest-before", transaction = "none");
				g.model("tag").$registerCallback(type = "afterSave", methods = "saveDescriptionOnce");
				t.name = "savedch-nest-after";
				t.save(transaction = "none");
				expect(ListSort(t.savedChangedProperties(), "textnocase")).toBe("description,name");
				expect(t.savedChangeFrom("name")).toBe("savedch-nest-before");
			});

			it("shows each afterCommit the save that queued it when one object is saved twice in a transaction", () => {
				var t = g.model("tag").create(name = "savedch-a", transaction = "none");
				g.model("tag").$registerCallback(type = "afterCommit", methods = "recordSavedChangesOnCommit");
				request.$scTag = t;
				request.$scNames = ["savedch-b", "savedch-c"];
				g.model("tag").invokeWithTransaction(method = "txnRenameTwice", transaction = "commit");
				expect(ArrayLen(request.$scLog)).toBe(2, "one afterCommit per save");
				expect(request.$scLog[1].from).toBe("savedch-a");
				expect(request.$scLog[2].from).toBe("savedch-b");
				// Both run after the commit, so the object holds its final, committed state.
				expect(request.$scLog[1].name).toBe("savedch-c");
				expect(request.$scLog[2].name).toBe("savedch-c");
				// Once the callbacks are done, the object reports its last save.
				expect(t.savedChangeFrom("name")).toBe("savedch-b");
			});

			it("lets afterCommit announce a record that ends up live exactly once, with no flags", () => {
				var t = g.model("tag").create(name = "savedch-draft", transaction = "none");
				g.model("tag").$registerCallback(type = "afterCommit", methods = "announceIfLive");
				request.$scTag = t;
				// Live, then back down, in one transaction: it doesn't end up live.
				request.$scNames = ["savedch-live", "savedch-draft"];
				g.model("tag").invokeWithTransaction(method = "txnRenameTwice", transaction = "commit");
				expect(request.$scAnnounced).toBe(0);
				// Live again later: announced once.
				t.update(name = "savedch-live", transaction = "commit");
				expect(request.$scAnnounced).toBe(1);
				// Saved again while live, without the name changing: not announced again.
				t.update(description = "still live", transaction = "commit");
				expect(request.$scAnnounced).toBe(1);
			});

			it("shows afterRollback the undone save, then restores the state from before it", () => {
				var t = g.model("tag").create(name = "savedch-rb-before", transaction = "none");
				var before = Duplicate(t.savedChanges());
				g.model("tag").$registerCallback(type = "afterRollback", methods = "recordSavedChangesOnRollback");
				request.$scTag = t;
				request.$scNames = ["savedch-rb-undone"];
				var state = {threw = false};
				try {
					g.model("tag").invokeWithTransaction(method = "txnRenameThenThrow", transaction = "commit");
				} catch (any e) {
					state.threw = true;
				}
				expect(state.threw).toBeTrue();
				expect(ArrayLen(request.$scLog)).toBe(1);
				expect(request.$scLog[1].phase).toBe("rollback");
				expect(request.$scLog[1].from).toBe("savedch-rb-before");
				expect(t.savedChanges()).toBe(before);
			});

			it("restores the state from before a rolled-back save on an object without transaction callbacks", () => {
				var t = g.model("tag").create(name = "savedch-plain-before", transaction = "none");
				var before = Duplicate(t.savedChanges());
				request.$scTag = t;
				request.$scNames = ["savedch-plain-undone"];
				var state = {threw = false};
				try {
					g.model("tag").invokeWithTransaction(method = "txnRenameThenThrow", transaction = "commit");
				} catch (any e) {
					state.threw = true;
				}
				expect(state.threw).toBeTrue();
				expect(t.savedChanges()).toBe(before);
			});

		});

	}

}
