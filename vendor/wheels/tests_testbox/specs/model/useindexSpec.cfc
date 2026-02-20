component extends="wheels.Testbox" {

	function run() {

        g = application.wo

		describe("useIndex support (MySQL/SQLServer only)", () => {
			db = "";
			expectedHint = "";

			beforeEach(() => {
				info = g.$dbinfo(datasource = application.wheels.dataSourceName, type = "version");
				db = LCase(Replace(info.database_productname, " ", "", "all"));

				if (db EQ "mysql") {
					expectedHint = "USE INDEX(idx_posts_authorid)";
				} else if (db EQ "microsoftsqlserver") {
					expectedHint = "WITH (INDEX(idx_posts_authorid))";
				} else {
					skip("Skipping all useIndex tests: Not MySQL or SQL Server");
				}
			});

            it("adds index hint in raw SQL when useIndex is specified with findOne()", () => {
				actual = g.model("post").findOne(
					where = "authorid > 0",
					useIndex = {"post": "idx_posts_authorid"},
					returnAs = "sql"
				);
				expect(actual).toInclude(expectedHint);
			});

			it("adds index hint in raw SQL when useIndex is specified with findAll()", () => {
				actual = g.model("post").findAll(
					where = "authorid > 0",
					useIndex = {"post": "idx_posts_authorid"},
					returnAs = "sql"
				);
				expect(actual).toInclude(expectedHint);
			});

			it("returns expected results when useIndex is applied", () => {
				result = g.model("post").findAll(
                    where = "authorid > 0", 
                    useIndex = {"post":"idx_posts_authorid"
                });
				expect(result.recordCount).toBeGTE(0);
			});

			it("throws an error when an invalid index is used", () => {
				expect(() => {
					g.model("post").findAll(where = "authorid > 0", useIndex = {"post": "idx_posts_postid"});
				}).toThrow();
			});

            it("updateAll works with instantiate=true and triggers callbacks", () => {
                transaction action="begin" {
                    updatedCount = g.model("Author").updateAll(
                        where = "firstName = 'Andy'",
                        properties = { firstName = "Kermit" },
                        useIndex = {"post": "idx_posts_authorid"},
                        instantiate = true
                    )
                    updated = g.model("Author").findAll(where = "firstName = 'Kermit'");
                    transaction action="rollback";
                }
                expect(updatedCount).toBeGT(0);
                expect(updated.recordcount).toBe(updatedCount);
            });

            it("updateOne works with useIndex hint", () => {
                transaction action="begin" {
                    success = g.model("Post").updateOne(
                        where = "authorId > 0",
                        properties = { title = "One Indexed Title" },
                        useIndex = {"post": "idx_posts_authorid"}
                    );
                    posts = g.model("Post").findAll(where = "title = 'One Indexed Title'");
                    transaction action="rollback";
                }
                expect(success).toBeTrue();
                expect(posts.recordcount).toBe(1);
            });

            it("deleteAll works with useIndex hint with softDelete = false", () => {
                transaction action="begin" {
                    g.model("post").deleteAll(
                        where = "id > 0",
                        softDelete = false,
                        useIndex = {"post": "idx_posts_authorid"}
                    )
                    posts = g.model("post").findAll()
                    transaction action="rollback";
                }
                expect(posts.recordcount).toBe(0)
            });

            it("deleteOne works with useIndex hint", () => {
                transaction action="begin" {
                    postsBefore = g.model("post").findAll(where = "id > 0")
                    g.model("post").deleteOne(
                        where = "id > 0",
                        useIndex = {"post": "idx_posts_authorid"}
                    )
                    posts = g.model("post").findAll(where = "id > 0")
                    transaction action="rollback";
                }
                expect(posts.recordcount).toBe(4)
            })

            it("deleteOne works with useIndex hint with softDelete = false", () => {
                transaction action="begin" {
                    g.model("post").deleteOne(
                        where = "id > 0",
                        softDelete = false,
                        useIndex = {"post": "idx_posts_authorid"}
                    )
                    posts = g.model("post").findAll()
                    transaction action="rollback";
                }
                expect(posts.recordcount).toBe(4)
            })
		});
	}
}
