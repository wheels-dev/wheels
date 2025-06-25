component extends="testbox.system.BaseSpec" {

	function run() {

		g = application.wo

		describe("Tests that invokewithtransaction", () => {

			beforeEach(() => {
				application.wheels.transactionMode = "commit"
			})

			afterEach(() => {
				application.wheels.transactionMode = "none"
			})
			
			it("create rollbacks when callback returns false", () => {
				tag = g.model("tagFalseCallbacks").create(name = "Kermit", description = "The Frog")
				tag = g.model("tagFalseCallbacks").findOne(where = "name='Kermit'")

				expect(tag).toBeFalse()
			})
			
			it("update rollbacks when callback returns false", () => {
				tag = g.model("tagFalseCallbacks").findOne(where = "description='testdesc'")
				tag.update(name = "Kermit")
				tag = g.model("tagFalseCallbacks").findOne(where = "description='testdesc'")

				expect(tag.name).toBe("releases")
			})
			
			it("save rollbacks when callback returns false", () => {
				tag = g.model("tagFalseCallbacks").findOne(where = "description='testdesc'")
				tag.name = "Kermit"
				tag.save()
				tag = g.model("tagFalseCallbacks").findOne(where = "description='testdesc'")

				expect(tag.name).toBe("releases")
			})
			
			it("delete rollbacks when callback returns false", () => {
				tag = g.model("tagFalseCallbacks").findOne(where = "description='testdesc'")
				tag.delete()
				tag = g.model("tagFalseCallbacks").findOne(where = "description='testdesc'")

				expect(tag).toBeInstanceOf("tagFalseCallbacks")
			})
			
			it("deleteAll with instantiate rollbacks when callback returns false", () => {
				g.model("tagFalseCallbacks").deleteAll(instantiate = true)
				results = g.model("tagFalseCallbacks").findAll()

				expect(results.recordcount).toBe(8)
			})

			it("updateAll with instantiate rollbacks when callback returns false", () => {
				g.model("tagFalseCallbacks").updateAll(name = "Kermit", instantiate = true)
				results = g.model("tagFalseCallbacks").findAll(where = "name = 'Kermit'")

				expect(results.recordcount).toBe(0)
			})

			it("create with rollback", () => {
				tag = g.model("tag").create(name = "Kermit", description = "The Frog", transaction = "rollback")
				tag = g.model("tag").findOne(where = "name='Kermit'")

				expect(tag).notToBeInstanceOf("tag")
			})

			it("update with rollback", () => {
				tag = g.model("tag").findOne(where = "description='testdesc'")
				tag.update(name = "Kermit", transaction = "rollback")
				tag = g.model("tag").findOne(where = "description='testdesc'")

				expect(tag.name).toBe("releases")
			})

			it("save with rollback", () => {
				tag = g.model("tag").findOne(where = "description='testdesc'")
				tag.name = "Kermit"
				tag.save(transaction = "rollback")
				tag = g.model("tag").findOne(where = "description='testdesc'")

				expect(tag.name).toBe("releases")
			})

			it("delete with rollback", () => {
				tag = g.model("tag").findOne(where = "description='testdesc'")
				tag.delete(transaction = "rollback")
				tag = g.model("tag").findOne(where = "description='testdesc'")

				expect(tag).toBeInstanceOf("tag")
			})

			it("deleteAll with rollback", () => {
				g.model("tag").deleteAll(instantiate = true, transaction = "rollback")
				results = g.model("tag").findAll()

				expect(results.recordcount).toBe(8)
			})

			it("updateAll with rollback", () => {
				g.model("tag").updateAll(name = "Kermit", instantiate = true, transaction = "rollback")
				results = g.model("tag").findAll(where = "name = 'Kermit'")

				expect(results.recordcount).toBe(0)
			})

			it("create with transaction disabled", () => {
				transaction {
					tag = g.model("tag").create(name = "Kermit", description = "The Frog", transaction = "none")
					tag = g.model("tag").findOne(where = "name='Kermit'")

					expect(tag).toBeInstanceOf("tag")

					transaction action="rollback";
				}
			})

			it("create with transaction false", () => {
				transaction {
					tag = g.model("tag").create(name = "Kermit", description = "The Frog", transaction = false)
					tag = g.model("tag").findOne(where = "name='Kermit'")

					expect(tag).toBeInstanceOf("tag")
					
					transaction action="rollback";
				}
			})

			it("update with transaction disabled", () => {
				transaction {
					tag = g.model("tag").findOne(where = "description='testdesc'")
					tag.update(name = "Kermit", transaction = "none")
					tag.reload()

					expect(tag.name).toBe("Kermit")

					transaction action="rollback";
				}
			})

			it("save with transaction disabled", () => {
				transaction {
					tag = g.model("tag").findOne(where = "description='testdesc'")
					tag.name = "Kermit"
					tag.save(transaction = "none")
					tag.reload()

					expect(tag.name).toBe("Kermit")

					transaction action="rollback";
				}
			})

			it("delete with transaction disabled", () => {
				transaction {
					tag = g.model("tag").findOne(where = "description='testdesc'")
					tag.delete(transaction = "none")
					tag = g.model("tag").findOne(where = "description='testdesc'")

					expect(tag).notToBeInstanceOf("tag")

					transaction action="rollback";
				}
			})

			it("deleteAll with transaction disabled", () => {
				transaction {
					g.model("tag").deleteAll(instantiate = true, transaction = "none")
					results = g.model("tag").findAll()

					expect(results.recordcount).toBe(0)

					transaction action="rollback";
				}
			})

			it("updateAll with transaction disabled", () => {
				transaction {
					g.model("tag").updateAll(name = "Kermit", instantiate = true, transaction = "none")
					results = g.model("tag").findAll(where = "name = 'Kermit'")

					expect(results.recordcount).toBe(8)

					transaction action="rollback";
				}
			})

			it("nested transaction within callback respect initial transaction mode", () => {
				postsBefore = g.model('post').count(reload = true)
				tag = g.model("tagWithDataCallbacks").create(name = "Kermit", description = "The Frog", transaction = "rollback")
				postsAfter = g.model('post').count(reload = true)

				expect(tag).toBeInstanceOf("tagWithDataCallbacks")
				expect(postsBefore).toBe(postsAfter)
			})

			it("nested transaction within callback with transactions disabled", () => {
				transaction {
					tag = g.model("tagWithDataCallbacks").create(name = "Kermit", description = "The Frog", transaction = "none")
					results = g.model("tag").findAll(where = "name = 'Kermit'")
					transaction action="rollback";
				}

				expect(tag).toBeInstanceOf("tagWithDataCallbacks")
				expect(results.recordcount).toBe(1)
			})

			it("transaction closed after rollback", () => {
				hash = g.model("tag").$hashedConnectionArgs()
				tag = g.model("tagWithDataCallbacks").create(name = "Kermit", description = "The Frog", transaction = "rollback")

				expect(request.wheels.transactions[hash]).toBeFalse()
			})

			it("transaction closed after none", () => {
				hash = g.model("tag").$hashedConnectionArgs()
				transaction {
					tag = g.model("tagWithDataCallbacks").create(name = "Kermit", description = "The Frog", transaction = "none")
					transaction action="rollback";
				}

				expect(request.wheels.transactions[hash]).toBeFalse()
			})

			it("transaction closed when error raised", () => {
				hash = g.model("tag").$hashedConnectionArgs()
				try {
					tag = g.model("tag").create(id = "", name = "Kermit", description = "The Frog", transaction = "rollback")
				} catch (any e) {
				}

				expect(request.wheels.transactions[hash]).toBeFalse()
			})

			it("rollback when error raised", () => {
				tag = Duplicate(g.model("tagWithDataCallbacks").new(name = "Kermit", description = "The Frog"))
				tag.afterSave(methods = "crashMe")
				try {
					tag.save()
				} catch (any e) {
					results = g.model("tag").findAll(where = "name = 'Kermit'")
				}
				
				expect(results.recordcount).toBe(0)
			})
		})
	}
}