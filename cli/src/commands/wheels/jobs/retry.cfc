/**
 * Retry failed jobs by resetting them to pending status.
 *
 * {code:bash}
 * wheels jobs retry
 * wheels jobs retry --queue=mailers
 * wheels jobs retry --limit=10
 * {code}
 */
component extends="../base" {

	property name="detailOutput" inject="DetailOutputService@wheels-cli";

	/**
	 * @queue Filter by queue name (default: all queues)
	 * @limit Maximum number of jobs to retry (default: 0 = all)
	 */
	public void function run(
		string queue = "",
		numeric limit = 0
	) {
		local.appPath = getCWD();

		if (!isWheelsApp(local.appPath)) {
			error("This command must be run from a Wheels application directory");
			return;
		}

		detailOutput.header("Retry Failed Jobs");

		// Build URL parameters
		local.urlParams = "&command=jobsRetry";
		if (Len(arguments.queue)) {
			local.urlParams &= "&queue=#arguments.queue#";
		}
		if (arguments.limit > 0) {
			local.urlParams &= "&limit=#arguments.limit#";
		}

		local.result = $sendToCliCommand(urlstring = local.urlParams);
		if (!local.result.success) {
			return;
		}

		if (StructKeyExists(local.result, "retried")) {
			if (local.result.retried > 0) {
				detailOutput.success("Retried #local.result.retried# failed job(s).");
				detailOutput.output("Jobs have been reset to 'pending' and will be processed on the next cycle.");
			} else {
				detailOutput.output("No failed jobs to retry.");
			}
		}
	}

}
