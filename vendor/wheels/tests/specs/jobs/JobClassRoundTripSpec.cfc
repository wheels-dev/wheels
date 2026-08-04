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
				// The risk is an engine ECHOING BACK the path it was handed instead of
				// deriving the name from the file: the persisted string would then carry
				// whatever casing the caller happened to type, and that string is what a
				// Linux worker later has to resolve.
				//
				// Engines close that off two different ways, and either is sufficient:
				//
				//   Lucee/BoxLang — a miscased path RESOLVES (the filesystem is
				//     case-insensitive here) but the metadata name comes back canonical.
				//   Adobe         — a miscased path does not resolve AT ALL. Its component
				//     resolver is case-sensitive independently of the filesystem, throwing
				//     "Could not find the ColdFusion component ... probejob". Nothing can be
				//     persisted because nothing can be constructed.
				//
				// Asserting only the first would fail on Adobe for a reason that is *safer*
				// than the one being tested, so assert the property both satisfy.
				local.canonical = GetMetadata(CreateObject("component", "wheels.tests._assets.jobs.ProbeJob")).name
				local.resolved = {miscasedConstructed = false, name = ""}

				try {
					local.resolved.name = GetMetadata(CreateObject("component", "wheels.tests._assets.jobs.probejob")).name
					local.resolved.miscasedConstructed = true
				} catch (any e) {
					// case-sensitive resolver — the stronger guarantee
				}

				if (local.resolved.miscasedConstructed) {
					expect(Compare(local.resolved.name, local.canonical)).toBe(0)
				} else {
					expect(local.resolved.name).toBe("")
				}
			})

			it("re-instantiates from its own persisted metadata name", () => {
				// the actual enqueue -> drain round trip, without touching the queue table
				local.original = CreateObject("component", "wheels.tests._assets.jobs.ProbeJob")
				local.persisted = GetMetadata(local.original).name

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
				local.thrown = {type: "", message: ""}

				local.bridge = new wheels.Job()

				try {
					local.bridge.$instantiateJobClass(jobClass = "app.jobs.NoSuchJob", jobId = "abc-123")
				} catch (any e) {
					local.thrown.type = e.type
					local.thrown.message = e.message
				}

				// the raw engine error is "component not found" for a class that plainly
				// exists, which points investigators at mappings and deployment
				expect(local.thrown.type).toBe("Wheels.JobClassNotFound")
				expect(local.thrown.message).toInclude("app.jobs.NoSuchJob")
				expect(local.thrown.message).toInclude("abc-123")
			})

			it("throws Wheels.InvalidJobClass when the path resolves to something that is not a job", () => {
				local.thrown = {type: ""}

				local.bridge = new wheels.Job()

				try {
					// a real component with no perform()
					local.bridge.$instantiateJobClass(jobClass = "wheels.tests._assets.models.Post")
				} catch (any e) {
					local.thrown.type = e.type
				}

				expect(local.thrown.type).toBe("Wheels.InvalidJobClass")
			})
		})
	}

}
