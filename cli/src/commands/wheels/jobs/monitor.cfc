/**
 * Live monitoring dashboard for the job queue.
 * Refreshes at a configurable interval showing throughput, errors, and recent jobs.
 *
 * {code:bash}
 * wheels jobs monitor
 * wheels jobs monitor --interval=5
 * wheels jobs monitor --queue=mailers
 * {code}
 */
component extends="../base" {

	property name="detailOutput" inject="DetailOutputService@wheels-cli";

	/**
	 * @interval Refresh interval in seconds (default: 3)
	 * @queue    Filter by queue name (default: all queues)
	 */
	public void function run(
		numeric interval = 3,
		string queue = ""
	) {
		local.appPath = getCWD();

		if (!isWheelsApp(local.appPath)) {
			error("This command must be run from a Wheels application directory");
			return;
		}

		detailOutput.header("Wheels Job Monitor");
		detailOutput.output("Press Ctrl+C to stop");
		detailOutput.line();

		while (true) {
			// Build URL parameters
			local.urlParams = "&command=jobsMonitor";
			if (Len(arguments.queue)) {
				local.urlParams &= "&queue=#arguments.queue#";
			}

			try {
				local.result = $sendToCliCommand(urlstring = local.urlParams);

				if (StructKeyExists(local.result, "success") && local.result.success) {
					// Clear previous output with separator
					detailOutput.divider("=", 60);
					detailOutput.getPrint().boldCyanLine("Job Queue Dashboard - #TimeFormat(Now(), "HH:mm:ss")#");
					detailOutput.divider("-", 60);

					// Queue statistics
					if (StructKeyExists(local.result, "stats") && StructKeyExists(local.result.stats, "totals")) {
						local.t = local.result.stats.totals;
						detailOutput.subHeader("Queue Summary");
						detailOutput.metric("Pending", local.t.pending);
						detailOutput.metric("Processing", local.t.processing);
						detailOutput.metric("Completed", local.t.completed);
						detailOutput.metric("Failed", local.t.failed);
						detailOutput.metric("Total", local.t.total);
					}

					// Throughput
					if (StructKeyExists(local.result, "monitor")) {
						local.m = local.result.monitor;

						detailOutput.subHeader("Throughput (last 60 min)");
						detailOutput.metric("Completed", local.m.throughput.completed);
						detailOutput.metric("Failed", local.m.throughput.failed);
						detailOutput.metric("Error rate", "#local.m.errorRate#%");

						if (Len(local.m.oldestPending)) {
							detailOutput.line();
							detailOutput.output("Oldest pending job: #DateTimeFormat(local.m.oldestPending, 'yyyy-mm-dd HH:mm:ss')#");
						}

						// Recent jobs
						if (ArrayLen(local.m.recentJobs)) {
							detailOutput.subHeader("Recent Jobs");
							local.count = Min(ArrayLen(local.m.recentJobs), 5);
							for (local.i = 1; local.i <= local.count; local.i++) {
								local.job = local.m.recentJobs[local.i];
								detailOutput.output("  [#local.job.status#] #local.job.jobClass# (#local.job.queue#) - #DateTimeFormat(local.job.updatedAt, 'HH:mm:ss')#");
							}
						}
					}

					// Timeout recoveries
					if (StructKeyExists(local.result, "timeoutsRecovered") && local.result.timeoutsRecovered > 0) {
						detailOutput.line();
						detailOutput.statusWarning("Recovered #local.result.timeoutsRecovered# timed-out job(s)");
					}
				}
			} catch (any e) {
				detailOutput.error("[#TimeFormat(Now(), "HH:mm:ss")#] Monitor error: #e.message#");
			}

			sleep(arguments.interval * 1000);
		}
	}

}
