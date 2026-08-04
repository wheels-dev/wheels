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
				job = CreateObject("component", "wheels.tests._assets.jobs.ProbeJob")
				meta = GetMetadata(job)

				fileName = ListFirst(ListLast(Replace(meta.path, "\", "/", "all"), "/"), ".")

				// case-sensitive comparison — Compare(), not CompareNoCase()
				expect(Compare(ListLast(meta.name, "."), fileName)).toBe(0)
			})

			it("reports the same metadata name however the component was instantiated", () => {
				// on a case-insensitive filesystem BOTH of these resolve, so if the engine
				// echoed back the path it was handed rather than deriving it from the file,
				// the persisted string would carry whatever casing the caller happened to
				// type — and that string is what a Linux worker later has to resolve
				canonical = CreateObject("component", "wheels.tests._assets.jobs.ProbeJob")
				lowercased = CreateObject("component", "wheels.tests._assets.jobs.probejob")

				expect(Compare(GetMetadata(canonical).name, GetMetadata(lowercased).name)).toBe(0)
			})

			it("re-instantiates from its own persisted metadata name", () => {
				// the actual enqueue -> drain round trip, without touching the queue table
				original = CreateObject("component", "wheels.tests._assets.jobs.ProbeJob")
				persisted = GetMetadata(original).name

				revived = (new wheels.Job()).$instantiateJobClass(jobClass = persisted)

				expect(Compare(GetMetadata(revived).name, persisted)).toBe(0)
			})
		})

		describe("Tests that an unresolvable jobClass", () => {

			it("throws Wheels.JobClassNotFound naming the row and the class", () => {
				thrown = {type: "", message: ""}

				try {
					(new wheels.Job()).$instantiateJobClass(jobClass = "app.jobs.NoSuchJob", jobId = "abc-123")
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

			it("throws Wheels.InvalidJobClass when the path resolves to something that is not a job", () => {
				thrown = {type: ""}

				try {
					// a real component with no perform()
					(new wheels.Job()).$instantiateJobClass(jobClass = "wheels.tests._assets.models.Post")
				} catch (any e) {
					thrown.type = e.type
				}

				expect(thrown.type).toBe("Wheels.InvalidJobClass")
			})
		})
	}

}
