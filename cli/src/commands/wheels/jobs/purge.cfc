/**
 * Purge old completed or failed jobs from the queue.
 *
 * {code:bash}
 * wheels jobs purge
 * wheels jobs purge --completed --older-than=30
 * wheels jobs purge --failed --queue=mailers
 * wheels jobs purge --completed --failed --force
 * {code}
 */
component extends="../base" {

	property name="detailOutput" inject="DetailOutputService@wheels-cli";

	/**
	 * @completed Purge completed jobs (default: true)
	 * @failed    Purge failed jobs (default: false)
	 * @olderThan Delete jobs older than this many days (default: 7)
	 * @queue     Filter by queue name (default: all queues)
	 * @force     Skip confirmation prompt
	 */
	public void function run(
		boolean completed = true,
		boolean failed = false,
		numeric olderThan = 7,
		string queue = "",
		boolean force = false
	) {
		local.appPath = getCWD();

		if (!isWheelsApp(local.appPath)) {
			error("This command must be run from a Wheels application directory");
			return;
		}

		detailOutput.header("Purge Jobs");

		local.totalPurged = 0;

		// Purge completed jobs
		if (arguments.completed) {
			local.urlParams = "&command=jobsPurge&status=completed&days=#arguments.olderThan#";
			if (Len(arguments.queue)) {
				local.urlParams &= "&queue=#arguments.queue#";
			}

			local.result = $sendToCliCommand(urlstring = local.urlParams);
			if (StructKeyExists(local.result, "success") && local.result.success && StructKeyExists(local.result, "purged")) {
				local.totalPurged += local.result.purged;
				if (local.result.purged > 0) {
					detailOutput.success("Purged #local.result.purged# completed job(s) older than #arguments.olderThan# day(s).");
				} else {
					detailOutput.output("No completed jobs to purge.");
				}
			}
		}

		// Purge failed jobs
		if (arguments.failed) {
			local.urlParams = "&command=jobsPurge&status=failed&days=#arguments.olderThan#";
			if (Len(arguments.queue)) {
				local.urlParams &= "&queue=#arguments.queue#";
			}

			local.result = $sendToCliCommand(urlstring = local.urlParams);
			if (StructKeyExists(local.result, "success") && local.result.success && StructKeyExists(local.result, "purged")) {
				local.totalPurged += local.result.purged;
				if (local.result.purged > 0) {
					detailOutput.success("Purged #local.result.purged# failed job(s) older than #arguments.olderThan# day(s).");
				} else {
					detailOutput.output("No failed jobs to purge.");
				}
			}
		}

		if (local.totalPurged > 0) {
			detailOutput.success("Total purged: #local.totalPurged# job(s)");
		}
	}

}
