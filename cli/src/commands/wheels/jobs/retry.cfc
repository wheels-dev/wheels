/**
 * Retry failed jobs by resetting them to pending status.
 *
 * {code:bash}
 * wheels jobs retry
 * wheels jobs retry --queue=mailers
 * wheels jobs retry --limit=10
 * {code}
 */
component extends="../../base" {

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

		print.line();
		print.boldBlueLine("Retry Failed Jobs");
		print.line();

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
				print.greenLine("Retried #local.result.retried# failed job(s).");
				print.line("Jobs have been reset to 'pending' and will be processed on the next cycle.");
			} else {
				print.line("No failed jobs to retry.");
			}
		}

		print.line();
	}

}
