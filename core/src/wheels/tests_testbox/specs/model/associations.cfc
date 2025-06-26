component extends="testbox.system.BaseSpec" {

	function run() {

		g = application.wo

		describe("Tests that belongsTo", () => {

			it("is getting parent", () => {
				obj = g.model("post").findOne(order = "id")
				dynamicResult = obj.author()
				coreResult = g.model("author").findByKey(obj.authorId)

				expect(dynamicResult.key()).toBe(coreResult.key())
				
				dynamicResult = obj.author(select = "lastName", returnAs = "query")
				coreResult = g.model("author").findByKey(key = obj.authorId, select = "lastName", returnAs = "query")

				expect(dynamicResult).toBeTypeOf("query")
				expect(ListLen(dynamicResult.columnList)).toBe(1)
				expect(coreResult).toBeTypeOf("query")
				expect(ListLen(coreResult.columnList)).toBe(1)
				expect(dynamicResult.lastName).toBe(coreResult.lastName)
			})

			it("is checking if parent exists", () => {
				obj = g.model("post").findOne(order = "id")
				dynamicResult = obj.hasAuthor()
				coreResult = g.model("author").exists(obj.authorId)

				expect(dynamicResult).toBe(coreResult)
			})

			it("is getting parent on new object", () => {
				authorByFind = g.model("author").findOne(order = "id")
				newPost = g.model("post").new(authorId = authorByFind.id)
				authorByAssociation = newPost.author()

				expect(authorByFind.key()).toBe(authorByAssociation.key())
			})

			it("is checking if parent exists on new object", () => {
				authorByFind = g.model("author").findOne(order = "id")
				newPost = g.model("post").new(authorId = authorByFind.id)
				authorExistsByAssociation = newPost.hasAuthor()

				expect(authorExistsByAssociation).toBeTrue()
			})

			it("is getting parent with join key", () => {
				obj = g.model("author").findOne(order = "id", include = "user")

				expect(obj.firstName).toBe(obj.user.firstName)
			})
		})

		describe("Tests that hasMany", () => {

			it("is getting children", () => {
				author = g.model("author").findOne(order = "id")
				dynamicResult = author.posts()
				coreResult = g.model("post").findAll(where = "authorId=#author.id#")

				expect(dynamicResult['title'][1]).toBe(coreResult['title'][1])
			})

			it("is getting children with include", () => {
				author = g.model("author").findOne(order = "id", include = "posts")

				expect(author).toBeInstanceOf("author")
				expect(author.posts).toHaveLength(3)

				author = g.model("author").findOne(order = "id", include = "posts", returnAs = "query")
				expect(author.recordcount).toBe(3)
			})

			it("is counting children", () => {
				author = g.model("author").findOne(order = "id")
				dynamicResult = author.postCount()
				coreResult = g.model("post").count(where = "authorId=#author.id#")

				expect(dynamicResult).toBe(coreResult)
			})

			it("is checking if children exists", () => {
				author = g.model("author").findOne(order = "id")
				dynamicResult = author.hasPosts()
				coreResult = g.model("post").exists(where = "authorId=#author.id#")

				expect(dynamicResult).toBe(coreResult)
			})

			it("is getting one child", () => {
				author = g.model("author").findOne(order = "id")
				dynamicResult = author.findOnePost()
				coreResult = g.model("post").findOne(where = "authorId=#author.id#")

				expect(dynamicResult.title).toBe(coreResult.title)
			})

			it("is adding child by setting foreign key", () => {
				author = g.model("author").findOne(order = "id")
				post = g.model("post").findOne(order = "id DESC")
				transaction {
					author.addPost(post = post, transaction = "none")
					/* we need to test if authorId is set on the post object as well and not just in the database!*/
					post.reload()
					transaction action="rollback";
				}

				expect(author.id).toBe(post.authorId)

				post.reload()
				transaction {
					author.addPost(key = post.id, transaction = "none")
					post.reload()
					transaction action="rollback";
				}

				expect(author.id).toBe(post.authorId)
				
				post.reload()
				transaction {
					g.model("post").updateByKey(key = post.id, authorId = author.id, transaction = "none")
					post.reload()
					transaction action="rollback";
				}

				expect(author.id).toBe(post.authorId)
			})

			it("is removing child by nullifying foreign key", () => {
				author = g.model("author").findOne(order = "id")
				post = g.model("post").findOne(order = "id DESC")
				transaction {
					author.removePost(post = post, transaction = "none")
					/* we need to test if authorId is set to blank on the post object as well and not just in the database!*/
					post.reload()
					transaction action="rollback";
				}

				expect(post.authorId).toBe("")

				post.reload()
				transaction {
					author.removePost(key = post.id, transaction = "none")
					post.reload()
					transaction action="rollback";
				}

				expect(post.authorId).toBe("")

				post.reload()
				transaction {
					g.model("post").updateByKey(key = post.id, authorId = "", transaction = "none")
					post.reload()
					transaction action="rollback";
				}

				expect(post.authorId).toBe("")
			})

			it("is deleting child", () => {
				author = g.model("author").findOne(order = "id")
				post = g.model("post").findOne(order = "id DESC")
				transaction {
					author.deletePost(post = post, transaction = "none")
					/* should we also set post to false here? */
					expect(g.model('post').exists(post.id)).toBeFalse()
					transaction action="rollback";
				}
				transaction {
					author.deletePost(key = post.id, transaction = "none")
					expect(g.model('post').exists(post.id)).toBeFalse()
					transaction action="rollback";
				}
				transaction {
					g.model("post").deleteByKey(key = post.id, transaction = "none")
					expect(g.model('post').exists(post.id)).toBeFalse()
					transaction action="rollback";
				}
			})

			it("is removing all children by nullifying foreign keys", () => {
				author = g.model("author").findOne(order = "id")
				transaction {
					author.removeAllPosts(transaction = "none")
					dynamicResult = author.postCount()
					remainingCount = g.model("post").count()
					transaction action="rollback";
				}
				transaction {
					g.model("post").updateAll(authorId = "", where = "authorId=#author.id#", transaction = "none")
					coreResult = author.postCount()
					transaction action="rollback";
				}

				expect(dynamicResult).toBe(0)
				expect(coreResult).toBe(0)
				expect(remainingCount).toBe(5)
			})

			it("is deleting all children", () => {
				author = g.model("author").findOne(order = "id")
				transaction {
					author.deleteAllPosts(transaction = "none")
					dynamicResult = author.postCount()
					remainingCount = g.model("post").count()
					transaction action="rollback";
				}
				transaction {
					g.model("post").deleteAll(where = "authorId=#author.id#", transaction = "none")
					coreResult = author.postCount()
					transaction action="rollback";
				}

				expect(dynamicResult).toBe(0)
				expect(coreResult).toBe(0)
				expect(remainingCount).toBe(2)
			})

			it("is creating new child", () => {
				author = g.model("author").findOne(order = "id")
				newPost = author.newPost(title = "New Title")
				dynamicResult = newPost.authorId
				newPost = g.model("post").new(authorId = author.id, title = "New Title")
				coreResult = newPost.authorId

				expect(dynamicResult).toBe(coreResult)
			})

			it("is creating new child and saving it", () => {
				author = g.model("author").findOne(order = "id")
				transaction {
					newPost = author.createPost(title = "New Title", body = "New Body", transaction = "none")
					dynamicResult = newPost.authorId
					transaction action="rollback";
				}
				transaction {
					newPost = g.model("post").create(authorId = author.id, title = "New Title", body = "New Body", transaction = "none")
					coreResult = newPost.authorId
					transaction action="rollback";
				}
				expect(dynamicResult).toBe(coreResult)
			})

			it("is working with dependency delete", () => {
				transaction {
					postWithAuthor = g.model("post").findOne(order = "id")
					author = g.model("author").findByKey(key = postWithAuthor.authorId)
					author.hasMany(name = "posts", dependent = "delete")
					author.delete()
					posts = g.model("post").findAll(where = "authorId=#author.id#")
					transaction action="rollback";
				}

				expect(posts.recordcount).toBe(0)
			})

			it("is working with dependency deleteAll", () => {
				transaction {
					postWithAuthor = g.model("post").findOne(order = "id")
					author = g.model("author").findByKey(key = postWithAuthor.authorId)
					author.hasMany(name = "posts", dependent = "deleteAll")
					author.delete()
					posts = g.model("post").findAll(where = "authorId=#author.id#")
					transaction action="rollback";
				}

				expect(posts.recordcount).toBe(0)
			})

			it("is working with dependency removeAll", () => {
				transaction {
					postWithAuthor = g.model("post").findOne(order = "id")
					author = g.model("author").findByKey(key = postWithAuthor.authorId)
					author.hasMany(name = "posts", dependent = "removeAll")
					author.delete()
					posts = g.model("post").findAll(where = "authorId=#author.id#")
					transaction action="rollback";
				}

				expect(posts.recordcount).toBe(0)
			})

			it("is getting children with join key", () => {
				obj = g.model("user").findOne(order = "id", include = "authors")
				expect(obj.firstName).toBe(obj.authors[1].firstName)
			})

			it("is getting calculated property without distinct", () => {
				authors = g.model("author").findAll(select = "id, firstName, lastName, numberofitems")
				expect(authors.recordcount).toBe(10)
			})

			it("is selecting aggregate calculated property with distinct", () => {
				authors = g.model("author").findAll(select = "id, firstName, lastName, numberofitems", distinct = true)
				expect(authors.recordcount).toBe(10)
			})

			it("is getting aggregate calculated property with distinct", () => {
				posts = g.model("post").findAll(select = "id, authorId, firstId", distinct = true)
				expect(posts.recordcount).toBe(5)
			})

			it("is getting non aggregate calculated property with distinct", () => {
				posts = g.model("post").findAll(select = "id, authorId, titleAlias", distinct = true)
				expect(posts.recordcount).toBe(5)
			})

			it("is getting calculated properties with included model with distinct", () => {
				authors = g.model("author").findAll(
					select = "id, firstName, lastName, numberofitems, titlealias",
					include = "posts",
					distinct = true
				)
				expect(authors.recordcount).toBe(13)
			})
		})

		describe("Tests that hasOne", () => {

			it("is getting child", () => {
				author = g.model("author").findOne(order = "id")
				dynamicResult = author.profile()
				coreResult = g.model("profile").findOne(where = "authorId=#author.id#")

				expect(dynamicResult.bio).toBe(coreResult.bio)
			})

			it("is checking if child exists", () => {
				author = g.model("author").findOne(order = "id")
				dynamicResult = author.hasProfile()
				coreResult = g.model("profile").exists(where = "authorId=#author.id#")

				expect(dynamicResult).toBe(coreResult)
			})

			it("is adding child by setting foregin key", () => {
				author = g.model("author").findOne(order = "id DESC")
				profile = g.model("profile").findOne(order = "id")
				transaction {
					author.setProfile(profile = profile, transaction = "none")
					profile.reload()
					transaction action="rollback";
				}

				expect(author.id).toBe(profile.authorId)

				profile.reload()
				transaction {
					author.setProfile(key = profile.id, transaction = "none")
					profile.reload()
					transaction action="rollback";
				}
				
				expect(author.id).toBe(profile.authorId)

				profile.reload()
				transaction {
					g.model("profile").updateByKey(key = profile.id, authorId = author.id, transaction = "none")
					profile.reload()
					transaction action="rollback";
				}

				expect(author.id).toBe(profile.authorId)
			})

			it("is removing child by nullifying foreign key", () => {
				author = g.model("author").findOne(order = "id")
				transaction {
					author.removeProfile(transaction = "none")
					expect(g.model('profile').findOne().authorId).toBe("")
					transaction action="rollback";
				}
				transaction {
					g.model("profile").updateOne(authorId = "", where = "authorId=#author.id#", transaction = "none")
					expect(g.model('profile').findOne().authorId).toBe("")
					transaction action="rollback";
				}
			})

			it("is deleting child", () => {
				author = g.model("author").findOne(order = "id")
				profileCount = g.model("profile").count()
				transaction {
					author.deleteProfile(transaction = "none")
					expect(g.model('profile').count()).toBe(profileCount - 1)
					transaction action="rollback";
				}
				transaction {
					g.model("profile").deleteOne(where = "authorId=#author.id#", transaction = "none")
					expect(g.model('profile').count()).toBe(profileCount - 1)
					transaction action="rollback";
				}
			})

			it("is creating new child", () => {
				author = g.model("author").findOne(order = "id")
				newProfile = author.newProfile(dateOfBirth = "17/12/1981")
				dynamicResult = newProfile.authorId
				newProfile = g.model("profile").new(authorId = author.id, dateOfBirth = "17/12/1981")
				coreResult = newProfile.authorId

				expect(dynamicResult).toBe(coreResult)
			})

			it("is creating new child and saving it", () => {
				author = g.model("author").findOne(order = "id")
				transaction {
					newProfile = author.createProfile(dateOfBirth = "17/12/1981", transaction = "none")
					dynamicResult = newProfile.authorId
					transaction action="rollback";
				}
				transaction {
					newProfile = g.model("profile").create(authorId = author.id, dateOfBirth = "17/12/1981", transaction = "none")
					coreResult = newProfile.authorId
					transaction action="rollback";
				}

				expect(dynamicResult).toBe(coreResult)
			})

			it("is getting child with join key", () => {
				obj = g.model("user").findOne(order = "id", include = "author")
				expect(obj.firstName).toBe(obj.author.firstName)
			})
		})
	}
}