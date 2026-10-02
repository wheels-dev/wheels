component extends="wheels.WheelsTest" {

	function run() {
		g = application.wo

		// #3933: pin how an override reaches the framework original, so the behaviour
		// can't drift. Model mixins are compile-time includes (#3462), so a model override
		// can delegate three ways — the bare super<name> alias, super.<name>, and
		// variables.super<name> — and all three RUN (the override executes) on every
		// engine. On Lucee, Adobe and BoxLang all three also RETURN the framework finder's
		// query. RustCFML returns from the bare super<name> alias and from
		// variables.super<name>, but runs the dotted super.<name>() delegation WITHOUT
		// returning its value (returns null) — so only the super.<name>() spec pins
		// returnedQuery per engine (false on RustCFML, true plus recordCount elsewhere). Controller and view helpers are integrated as mixins
		// (Controller.cfc $integrateFunctions), NOT methods on the super (wheels.Controller)
		// inheritance chain, so only the super<name> alias reaches the original;
		// super.<name> fails on Lucee, Adobe and BoxLang (RustCFML happens to resolve it). (The existing SuperOverrideSpec already pins
		// the bare super<name> alias for a model property override and super.delete().)
		// Expected row count for the delegated finder: every post in the table.
		expected = g.model("post").count()
		describe("super delegation — model overrides (##3933)", () => {

			it("delegates a finder via super.<name>() — super.findAll()", () => {
				var m = g.model("SuperFindDot")
				m.findAll()
				expect(m.wasDelegated()).toBeTrue("super.findAll() must reach the framework original")
				// super.<name> is the one form RustCFML runs but does NOT return from (it returns
				// null); every other engine propagates the framework query. Pin both explicitly via
				// engineAdapter.isRustCFML() — a known engine bug (see the upstream note), not a
				// capability probe — so a JVM regression to null would fail here.
				if (g.$engineAdapter().isRustCFML()) {
					expect(m.returnedQuery()).toBeFalse("RustCFML drops the super.<name>() return value")
				} else {
					expect(m.returnedQuery()).toBeTrue("super.findAll() must return the framework query")
					expect(m.delegatedCount()).toBe(expected, "delegated super.findAll() must return every post")
				}
			})

			it("delegates a finder via variables.super<name>() — variables.superFindAll()", () => {
				var m = g.model("SuperFindVar")
				m.findAll()
				expect(m.wasDelegated()).toBeTrue("variables.superFindAll() must reach the framework original")
				expect(m.returnedQuery()).toBeTrue("variables.superFindAll() must return the framework query on every engine")
				expect(m.delegatedCount()).toBe(expected, "delegated variables.superFindAll() must return every post")
			})

			it("delegates a finder via the bare super<name>() alias — superFindAll()", () => {
				var m = g.model("SuperFindBare")
				m.findAll()
				expect(m.wasDelegated()).toBeTrue("superFindAll() must reach the framework original")
				expect(m.returnedQuery()).toBeTrue("superFindAll() must return the framework query on every engine")
				expect(m.delegatedCount()).toBe(expected, "delegated superFindAll() must return every post")
			})
		})

		describe("super delegation — controller/view overrides (##3933)", () => {

			it("delegates a view helper via the bare super<name>() alias — superLinkTo()", () => {
				// The superOverride fixture overrides linkTo() and delegates via superLinkTo().
				var c = g.controller(name = "superOverride")
				var result = c.linkTo(text = "Home", route = "root")
				expect(result).toStartWith("wrapped:")
				expect(result).toInclude("<a")
				expect(result).notToInclude("wrapped:wrapped:")
			})

			it("super.<name>() for a view helper is not a portable delegation form (##3933)", () => {
				var c = g.controller(name = "superLinkDot")
				// super.linkTo() resolves against wheels.Controller, where the helper exists
				// only as a mixin (not an inherited method), so it FAILS on Lucee, Adobe and
				// BoxLang. RustCFML happens to resolve it. So super.<name> is NOT portable for
				// controllers/views — the supported form is the super<name> alias (pinned
				// above). Tolerate the divergence but pin that WHERE super.<name> does resolve
				// it still delegates correctly (no infinite recursion into the override).
				var outcome = {threw = false, result = ""}
				try {
					outcome.result = c.linkTo(text = "Home", route = "root")
				} catch (any e) {
					outcome.threw = true
				}
				if (!outcome.threw) {
					expect(outcome.result).toStartWith("wrapped:")
					expect(outcome.result).notToInclude("wrapped:wrapped:")
				}
			})
		})
	}

}
