/**
 * Soft delete is reversible and a permanent delete is a real DELETE.
 *
 * - Soft-deleting a parent never destroys or unlinks its dependents: children that can be
 *   soft-deleted are, everything else is left alone (4370).
 * - `softDelete=false` reaches rows that are already soft-deleted, including dependents (4371).
 * - An instance tracks its own soft delete: reload() finds a soft-deleted row, a second soft
 *   delete is refused, and the object holds the deletedAt it wrote (4372).
 */
component extends="wheels.WheelsTest" {

	function run() {

		g = application.wo;

		describe("Soft-deleting a parent", () => {

			it("leaves dependent=delete children that can't be soft-deleted in place", () => {
				var state = {};
				transaction {
					var postId = g.model("comment").findOne(order = "id").postId;
					state.before = g.model("comment").count(where = "postId = #postId#");
					var post = g.model("SoftDeletePostDependentComments").findByKey(postId);
					state.deleted = post.delete();
					state.after = g.model("comment").count(where = "postId = #postId#");
					state.postStillThere = g.model("post").count(where = "id = #postId#", includeSoftDeletes = true);
					transaction action="rollback";
				}
				expect(state.before).toBeGT(0);
				expect(state.deleted).toBeTrue();
				expect(state.after).toBe(state.before);
				expect(state.postStillThere).toBe(1);
			});

			it("leaves dependent=removeAll children linked to it", () => {
				var state = {};
				transaction {
					var postId = g.model("comment").findOne(order = "id").postId;
					state.before = g.model("comment").count(where = "postId = #postId#");
					var post = g.model("SoftDeletePostRemovedComments").findByKey(postId);
					state.deleted = post.delete();
					state.after = g.model("comment").count(where = "postId = #postId#");
					transaction action="rollback";
				}
				expect(state.deleted).toBeTrue();
				expect(state.after).toBe(state.before);
			});

			it("soft-deletes dependents that can be soft-deleted", () => {
				var state = {};
				transaction {
					var parentId = g.model("post").findOne(where = "authorId IS NOT NULL", order = "id").authorId;
					state.children = g.model("post").count(where = "authorId = #parentId# AND id <> #parentId#");
					var parent = g.model("SoftDeletePostChildPosts").findByKey(parentId);
					state.deleted = parent.delete();
					state.liveChildren = g.model("post").count(where = "authorId = #parentId# AND id <> #parentId#");
					state.allChildren = g.model("post").count(where = "authorId = #parentId# AND id <> #parentId#", includeSoftDeletes = true);
					transaction action="rollback";
				}
				expect(state.children).toBeGT(0);
				expect(state.deleted).toBeTrue();
				expect(state.liveChildren).toBe(0);
				expect(state.allChildren).toBe(state.children);
			});

			it("leaves dependents alone when a stale copy's soft delete changes nothing, inside a caller's transaction", () => {
				var state = {};
				transaction {
					var parentId = g.model("post").findOne(where = "authorId IS NOT NULL", order = "id").authorId;
					state.children = g.model("post").count(where = "authorId = #parentId# AND id <> #parentId#");
					var stale = g.model("SoftDeletePostChildPosts").findByKey(parentId);
					// Soft-delete the parent row alone, behind the stale copy's back.
					g.model("post").updateAll(where = "id = #parentId#", deletedAt = Now(), includeSoftDeletes = true);
					state.deleted = stale.delete(transaction = "none");
					state.liveChildren = g.model("post").count(where = "authorId = #parentId# AND id <> #parentId#");
					transaction action="rollback";
				}
				expect(state.deleted).toBeFalse();
				expect(state.liveChildren).toBe(state.children);
			});

			it("still runs dependent= on a permanent delete", () => {
				var state = {};
				transaction {
					var postId = g.model("comment").findOne(order = "id").postId;
					var post = g.model("SoftDeletePostDependentComments").findByKey(postId);
					state.deleted = post.delete(softDelete = false);
					state.after = g.model("comment").count(where = "postId = #postId#");
					state.postLeft = g.model("post").count(where = "id = #postId#", includeSoftDeletes = true);
					transaction action="rollback";
				}
				expect(state.deleted).toBeTrue();
				expect(state.after).toBe(0);
				expect(state.postLeft).toBe(0);
			});

		});

		describe("A permanent delete", () => {

			it("deleteAll(softDelete=false) removes rows that are already soft-deleted", () => {
				var state = {};
				transaction {
					var post = g.model("post").findOne(order = "id");
					post.delete();
					state.removed = g.model("post").deleteAll(where = "id = #post.id#", softDelete = false);
					state.left = g.model("post").count(where = "id = #post.id#", includeSoftDeletes = true);
					transaction action="rollback";
				}
				expect(state.removed).toBe(1);
				expect(state.left).toBe(0);
			});

			it("deleteByKey(softDelete=false) removes a row that is already soft-deleted", () => {
				var state = {};
				transaction {
					var post = g.model("post").findOne(order = "id");
					post.delete();
					state.removed = g.model("post").deleteByKey(key = post.id, softDelete = false);
					state.left = g.model("post").count(where = "id = #post.id#", includeSoftDeletes = true);
					transaction action="rollback";
				}
				expect(state.removed).toBeTrue();
				expect(state.left).toBe(0);
			});

			it("reaches dependent children that are already soft-deleted", () => {
				var state = {};
				transaction {
					var authorId = g.model("post").findOne(where = "authorId IS NOT NULL", order = "id").authorId;
					state.posts = g.model("post").count(where = "authorId = #authorId#");
					g.model("post").findOne(where = "authorId = #authorId#", order = "id").delete();
					var author = g.model("AuthorDependentPosts").findByKey(authorId);
					state.deleted = author.delete(softDelete = false);
					state.left = g.model("post").count(where = "authorId = #authorId#", includeSoftDeletes = true);
					transaction action="rollback";
				}
				expect(state.posts).toBeGT(0);
				expect(state.deleted).toBeTrue();
				expect(state.left).toBe(0);
			});

		});

		describe("An instance on a soft-deleted row", () => {

			it("holds the deletedAt its soft delete wrote", () => {
				var state = {};
				transaction {
					var post = g.model("post").findOne(order = "id");
					post.delete();
					state.inMemory = post.deletedAt;
					state.changed = post.hasChanged("deletedAt");
					state.stored = g.model("post").findByKey(key = post.id, includeSoftDeletes = true).deletedAt;
					transaction action="rollback";
				}
				expect(IsDate(state.inMemory)).toBeTrue("deletedAt on the object: [" & state.inMemory & "]");
				// A DATETIME column without fractional seconds can round the stored value to the next second.
				expect(Abs(DateDiff("s", state.inMemory, state.stored))).toBeLTE(1);
				expect(state.changed).toBeFalse();
			});

			it("refuses a second soft delete and keeps the first deletedAt", () => {
				var state = {};
				transaction {
					var post = g.model("post").findOne(order = "id");
					post.delete();
					state.first = g.model("post").findByKey(key = post.id, includeSoftDeletes = true).deletedAt;
					state.again = post.delete();
					state.second = g.model("post").findByKey(key = post.id, includeSoftDeletes = true).deletedAt;
					transaction action="rollback";
				}
				expect(state.again).toBeFalse();
				expect(DateCompare(state.first, state.second, "s")).toBe(0);
			});

			it("deletes an object whose deletedAt was only set in memory", () => {
				var state = {};
				transaction {
					var post = g.model("post").findOne(order = "id");
					post.deletedAt = Now();
					state.deleted = post.delete();
					state.live = g.model("post").count(where = "id = #post.id#");
					transaction action="rollback";
				}
				expect(state.deleted).toBeTrue();
				expect(state.live).toBe(0);
			});

			it("lets a soft delete that was rolled back be retried", () => {
				var post = g.model("post").findOne(order = "id");
				var state = {};
				state.first = post.delete(transaction = "rollback");
				state.afterRollback = post.deletedAt;
				state.changed = post.hasChanged("deletedAt");
				state.retry = post.delete(transaction = "rollback");
				state.live = g.model("post").count(where = "id = #post.id#");
				expect(state.first).toBeTrue();
				expect(state.afterRollback).toBe("");
				expect(state.changed).toBeFalse();
				expect(state.retry).toBeTrue();
				expect(state.live).toBe(1, "both deletes were rolled back");
			});

			it("puts deletedAt back when afterDelete vetoes the soft delete", () => {
				var post = g.model("SoftDeletePostVetoedDelete").findOne(order = "id");
				var state = {};
				state.deleted = post.delete(transaction = "commit");
				state.inMemory = post.deletedAt;
				state.live = g.model("post").count(where = "id = #post.id#");
				expect(state.deleted).toBeFalse();
				expect(state.inMemory).toBe("");
				expect(state.live).toBe(1, "the vetoed delete was rolled back");
			});

			it("refuses a soft delete from a stale copy of a row soft-deleted elsewhere", () => {
				var state = {};
				transaction {
					var first = g.model("post").findOne(order = "id");
					var stale = g.model("post").findByKey(first.id);
					first.delete();
					state.again = stale.delete();
					transaction action="rollback";
				}
				expect(state.again).toBeFalse();
			});

			it("reloads the soft-deleted row instead of blanking the object", () => {
				var state = {};
				transaction {
					var post = g.model("post").findOne(order = "id");
					state.title = post.title;
					post.delete();
					post.reload();
					state.reloadedTitle = post.title;
					state.reloadedDeletedAt = post.deletedAt;
					transaction action="rollback";
				}
				expect(state.reloadedTitle).toBe(state.title);
				expect(IsDate(state.reloadedDeletedAt)).toBeTrue();
			});

			it("throws from reload() when the row no longer exists", () => {
				var state = {type = ""};
				transaction {
					var post = g.model("post").findOne(order = "id");
					post.delete(softDelete = false);
					try {
						post.reload();
					} catch (any e) {
						state.type = e.type;
					}
					transaction action="rollback";
				}
				expect(state.type).toBe("Wheels.RecordNotFound");
			});

		});

	}

}
