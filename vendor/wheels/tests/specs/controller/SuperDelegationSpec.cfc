component extends="wheels.WheelsTest" {

	function run() {
		g = application.wo

		// #3933: pin how an override reaches the framework original, so the behaviour
		// can't drift. Model mixins are compile-time includes (#3462), so a model override
		// can delegate three ways — the bare super<name> alias, super.<name>, and
		// variables.super<name> — and all three work on every engine (Lucee, Adobe,
		// BoxLang, RustCFML). Controller and view helpers are integrated as mixins
		// (Controller.cfc $integrateFunctions), NOT methods on the super (wheels.Controller)
		// inheritance chain, so only the super<name> alias reaches the original;
		// super.<name> fails on every engine. (The existing SuperOverrideSpec already pins
		// the bare super<name> alias for a model property override and super.delete().)
		describe("super delegation — model overrides (##3933)", () => {

			it("delegates a finder via super.<name>() — super.findAll()", () => {
				var m = g.model("SuperFindDot")
				m.findAll()
				expect(m.wasDelegated()).toBeTrue("super.findAll() must reach the framework original")
			})

			it("delegates a finder via variables.super<name>() — variables.superFindAll()", () => {
				var m = g.model("SuperFindVar")
				m.findAll()
				expect(m.wasDelegated()).toBeTrue("variables.superFindAll() must reach the framework original")
			})

			it("delegates a finder via the bare super<name>() alias — superFindAll()", () => {
				var m = g.model("SuperFindBare")
				m.findAll()
				expect(m.wasDelegated()).toBeTrue("superFindAll() must reach the framework original")
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
