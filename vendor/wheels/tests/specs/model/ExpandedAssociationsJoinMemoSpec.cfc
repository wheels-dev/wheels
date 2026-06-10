component extends="wheels.WheelsTest" {

	function run() {
		g = application.wo;

		describe("$expandedAssociations JOIN memoization", () => {
			beforeEach(() => {
				$resetJoinMemo("author", "posts");
				$resetJoinMemo("post", "author");
			});

			afterEach(() => {
				$resetJoinMemo("author", "posts");
				$resetJoinMemo("post", "author");
			});

			it("does not serve a soft-delete-free join to a default call (true then false)", () => {
				var withDeleted = g.model("author").$expandedAssociations(include = "posts", includeSoftDeletes = true);
				expect(withDeleted[1].join).notToInclude("IS NULL");

				var withoutDeleted = g.model("author").$expandedAssociations(
					include = "posts",
					includeSoftDeletes = false
				);
				expect(withoutDeleted[1].join).toInclude("deletedat");
				expect(withoutDeleted[1].join).toInclude("IS NULL");
			});

			it("does not serve a soft-delete-filtered join to an includeSoftDeletes call (false then true)", () => {
				var withoutDeleted = g.model("author").$expandedAssociations(include = "posts");
				expect(withoutDeleted[1].join).toInclude("IS NULL");

				var withDeleted = g.model("author").$expandedAssociations(include = "posts", includeSoftDeletes = true);
				expect(withDeleted[1].join).notToInclude("IS NULL");
			});

			it("does not serve an aliased self-join to a top-level include", () => {
				// In the nested context c_o_r_e_posts is already in the table list (it is the root
				// model's table), so the posts join must be aliased as the pluralized association name.
				var nested = g.model("post").$expandedAssociations(include = "author(posts)");
				var aliasedFragment = $aliasedPostsFragment();
				expect(nested[2].join).toInclude(aliasedFragment);

				// In the top-level context there is no table collision, so no alias must be present.
				var topLevel = g.model("author").$expandedAssociations(include = "posts");
				expect(topLevel[1].join).notToInclude(aliasedFragment);
				expect(topLevel[1].join).notToBe(nested[2].join);
			});

			it("still memoizes the join string per context variant", () => {
				var first = g.model("author").$expandedAssociations(include = "posts", includeSoftDeletes = false);
				var second = g.model("author").$expandedAssociations(include = "posts", includeSoftDeletes = false);
				expect(second[1].join).toBe(first[1].join);

				var assoc = g.model("author").$classData().associations["posts"];
				expect(StructKeyExists(assoc, "joinVariants")).toBeTrue();
				expect(StructCount(assoc.joinVariants)).toBe(1);
				expect(StructKeyExists(assoc.joinVariants, "sd0_alias0")).toBeTrue();
			});
		});
	}

	/**
	 * Deletes both the legacy `join` memo key and the variant-aware `joinVariants` memo key from the
	 * shared application-scoped association struct so each case starts clean and never leaks a
	 * poisoned memo into other specs.
	 */
	private void function $resetJoinMemo(required string modelName, required string association) {
		var associations = application.wo.model(arguments.modelName).$classData().associations;
		if (StructKeyExists(associations, arguments.association)) {
			StructDelete(associations[arguments.association], "join");
			StructDelete(associations[arguments.association], "joinVariants");
		}
	}

	/**
	 * Builds the alias fragment exactly the way $expandedAssociations does (adapter-specific, e.g.
	 * Oracle uses a space instead of " AS ") so the assertions hold on every database.
	 */
	private string function $aliasedPostsFragment() {
		var adapter = application.wo.model("post").getClass().adapter;
		return adapter.$tableAlias(adapter.$quoteIdentifier("c_o_r_e_posts"), "posts");
	}

}
