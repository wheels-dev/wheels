component extends="wheels.WheelsTest" {

	function run() {

		// Issue #3351. `enqueue()` persists `GetMetadata(this).name` into
		// `wheels_jobs.jobClass`, and the drain re-instantiates with
		// `CreateObject("component", jobRow.jobClass)`. So a string produced by ENGINE
		// METADATA is stored and later resolved as a component path, and the round trip is
		// only safe if that string keeps the casing of the file on disk — component paths are
		// case-sensitive on Linux and not on macOS or Windows, which is exactly the shape of
		// bug that passes locally and fails on a production redeploy.
		//
		// The issue calls the invariant unverified across engines. Rather than guess at a fix,
		// these specs assert it. They run on every engine × database leg, so lucee6, lucee7,
		// adobe2023, adobe2025 and boxlang each answer the question directly: if any engine
		// reports a name that does not match the file, this fails there and names it.
		describe("Tests that the persisted jobClass round-trips", () => {

			it("reports a metadata name whose last segment matches the .cfc file name exactly", () => {
				local.job = CreateObject("component", "wheels.tests._assets.jobs.ProbeJob")
				local.meta = GetMetadata(local.job)

				local.fileName = ListFirst(ListLast(Replace(local.meta.path, "\", "/", "all"), "/"), ".")

				// case-sensitive comparison — Compare(), not CompareNoCase()
				expect(Compare(ListLast(local.meta.name, "."), local.fileName)).toBe(0)
			})

			it("never persists a caller's miscased path", () => {
				// The risk is the persisted string carrying whatever casing the caller happened
				// to type, because that string is what a Linux worker later has to resolve.
				//
				// Whether a miscased path even constructs depends on the FILESYSTEM, not only
				// the engine: on case-sensitive Linux every engine throws "could not find
				// ... probejob"; on a case-insensitive one (macOS, Windows, a macOS checkout
				// bind-mounted into Docker) it resolves. And once it resolves, Adobe 2025
				// reports GetMetadata().name with the CALLER's casing (#3731) where Lucee and
				// BoxLang report the file's. So this asserts the framework's persisted value
				// — $persistableJobClass(), what enqueue() writes — not raw engine metadata.
				// The deterministic specs below exercise the canonicalization on any filesystem.
				local.canonical = GetMetadata(CreateObject("component", "wheels.tests._assets.jobs.ProbeJob")).name
				local.resolved = {miscasedConstructed = false, persisted = ""}

				try {
					local.miscased = CreateObject("component", "wheels.tests._assets.jobs.probejob")
					local.resolved.miscasedConstructed = true
					local.resolved.persisted = local.miscased.$persistableJobClass()
				} catch (any e) {
					// case-sensitive filesystem — nothing can be persisted because nothing
					// can be constructed
				}

				if (local.resolved.miscasedConstructed) {
					expect(Compare(local.resolved.persisted, local.canonical)).toBe(0)
				} else {
					expect(local.resolved.persisted).toBe("")
				}
			})

			it("persists the canonical name for a correctly cased instance", () => {
				local.job = CreateObject("component", "wheels.tests._assets.jobs.ProbeJob")
				local.canonical = GetMetadata(local.job).name
				expect(Compare(local.job.$persistableJobClass(), local.canonical)).toBe(0)
			})
		})

		describe("Tests that $canonicalJobClass", () => {

			it("restores the file's casing when metadata echoes a miscased path", () => {
				// The shape Adobe reports on a case-insensitive filesystem: name AND path carry
				// the caller's casing. The real directory exists, so its listing is authoritative.
				local.bridge = new wheels.Job()
				local.realPath = Replace(GetMetadata(CreateObject("component", "wheels.tests._assets.jobs.ProbeJob")).path, "\", "/", "all")
				local.echoedPath = Left(local.realPath, Len(local.realPath) - Len("ProbeJob.cfc")) & "probejob.cfc"

				local.rv = local.bridge.$canonicalJobClass(name = "wheels.tests._assets.jobs.probejob", path = local.echoedPath)

				expect(Compare(local.rv, "wheels.tests._assets.jobs.ProbeJob")).toBe(0)
			})

			it("restores package directory casing too", () => {
				local.bridge = new wheels.Job()
				local.realPath = GetMetadata(CreateObject("component", "wheels.tests._assets.jobs.ProbeJob")).path

				local.rv = local.bridge.$canonicalJobClass(name = "wheels.tests._assets.JOBS.PROBEJOB", path = local.realPath)

				expect(Compare(local.rv, "wheels.tests._assets.jobs.ProbeJob")).toBe(0)
			})

			it("leaves segments above a mapping boundary untouched", () => {
				// `someMapping` does not name its directory, so the walk stops there rather
				// than rewriting a mapping root to a directory name.
				local.bridge = new wheels.Job()
				local.realPath = GetMetadata(CreateObject("component", "wheels.tests._assets.jobs.ProbeJob")).path

				local.rv = local.bridge.$canonicalJobClass(name = "someMapping.jobs.probejob", path = local.realPath)

				expect(Compare(local.rv, "someMapping.jobs.ProbeJob")).toBe(0)
			})

			it("returns the name unchanged when there is no usable path", () => {
				local.bridge = new wheels.Job()

				expect(Compare(local.bridge.$canonicalJobClass(name = "app.jobs.someJob", path = ""), "app.jobs.someJob")).toBe(0)
				expect(Compare(local.bridge.$canonicalJobClass(name = "app.jobs.someJob", path = "/no/such/dir/someJob.cfc"), "app.jobs.someJob")).toBe(0)
			})
		})

		describe("Tests that the persisted jobClass re-instantiates", () => {

			it("re-instantiates from its own persisted metadata name", () => {
				// the actual enqueue -> drain round trip (what enqueue() persists), without the queue table
				local.original = CreateObject("component", "wheels.tests._assets.jobs.ProbeJob")
				local.persisted = local.original.$persistableJobClass()

				// Hoisted receiver. A parenthesized `new` in receiver position — `(new X()).m()`
				// — is rejected by Adobe's parser with `Invalid construct: Either argument or
				// name is missing`, the same MissingNameException family as cross-engine
				// invariant 16. Adobe blames the enclosing describe() line and the whole engine
				// leg reports tests=0. Caught by the compat matrix; Lucee and BoxLang accept it.
				local.bridge = new wheels.Job()
				local.revived = local.bridge.$instantiateJobClass(jobClass = local.persisted)

				expect(Compare(GetMetadata(local.revived).name, local.persisted)).toBe(0)
			})
		})

		describe("Tests that an unresolvable jobClass", () => {

			it("throws Wheels.JobClassNotFound naming the row and the class", () => {
				// NOT `local.`-scoped, deliberately. Cross-engine invariant 11: a catch body
				// runs under a nested `local` on BoxLang, so `thrown.type = e.type`
				// inside the catch writes to a struct that is discarded on exit and the
				// assertion below reads the untouched outer value. The blessed form is a
				// `var`-declared struct accessed WITHOUT the `local.` prefix. Scoping this
				// one for consistency cost two BoxLang failures on every database
				// (`Expected [Wheels.JobClassNotFound] but received []`) — caught by the
				// compat matrix, invisible on Lucee.
				var thrown = {type: "", message: ""}

				local.bridge = new wheels.Job()

				try {
					local.bridge.$instantiateJobClass(jobClass = "app.jobs.NoSuchJob", jobId = "abc-123")
				} catch (any e) {
					thrown.type = e.type
					thrown.message = e.message
				}

				// the raw engine error is "component not found" for a class that plainly
				// exists, which points investigators at mappings and deployment
				expect(thrown.type).toBe("Wheels.JobClassNotFound")
				expect(thrown.message).toInclude("app.jobs.NoSuchJob")
				expect(thrown.message).toInclude("abc-123")
			})

			it("throws Wheels.JobClassNotAllowed for an off-path component even if it exists", () => {
				var thrown = {type: ""}

				local.bridge = new wheels.Job()

				try {
					local.bridge.$instantiateJobClass(jobClass = "wheels.tests._assets.models.Post")
				} catch (any e) {
					thrown.type = e.type
				}

				expect(thrown.type).toBe("Wheels.JobClassNotAllowed")
			})

			it("throws Wheels.InvalidJobClass when an allowlisted path is not a job", () => {
				var thrown = {type: ""}

				local.bridge = new wheels.Job()

				try {
					local.bridge.$instantiateJobClass(jobClass = "wheels.tests._assets.jobs.NoPerformStub")
				} catch (any e) {
					thrown.type = e.type
				}

				expect(thrown.type).toBe("Wheels.InvalidJobClass")
			})
		})
	}

}
