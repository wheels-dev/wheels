/**
 * Test-only job whose perform() calls model() exactly as the background-jobs guide shows,
 * and records what the lookup returned so specs can verify the delegation end to end.
 */
component extends="wheels.Job" {

	public void function perform(struct data = {}) {
		local.author = model("Author").findOne(where = "firstName = '#arguments.data.firstName#'");
		request.$wheelsJobModelProbe = {
			found = IsObject(local.author),
			firstName = IsObject(local.author) ? local.author.firstName : ""
		};
	}
}
