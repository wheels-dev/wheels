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
component extends="../../base" {

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

		print.line();
		print.boldMagentaLine("Wheels Job Monitor");
		print.line("Press Ctrl+C to stop");
		print.line();

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
					print.line(RepeatString("=", 60));
					print.boldCyanLine("Job Queue Dashboard - #TimeFormat(Now(), "HH:mm:ss")#");
					print.line(RepeatString("-", 60));

					// Queue statistics
					if (StructKeyExists(local.result, "stats") && StructKeyExists(local.result.stats, "totals")) {
						local.t = local.result.stats.totals;
						print.line();
						print.boldLine("Queue Summary:");
						print.yellowLine("  Pending:    #local.t.pending#");
						print.cyanLine("  Processing: #local.t.processing#");
						print.greenLine("  Completed:  #local.t.completed#");
						if (local.t.failed > 0) {
							print.redLine("  Failed:     #local.t.failed#");
						} else {
							print.line("  Failed:     #local.t.failed#");
						}
						print.line("  Total:      #local.t.total#");
					}

					// Throughput
					if (StructKeyExists(local.result, "monitor")) {
						local.m = local.result.monitor;

						print.line();
						print.boldLine("Throughput (last 60 min):");
						print.greenLine("  Completed: #local.m.throughput.completed#");
						if (local.m.throughput.failed > 0) {
							print.redLine("  Failed:    #local.m.throughput.failed#");
						} else {
							print.line("  Failed:    #local.m.throughput.failed#");
						}
						if (local.m.errorRate > 0) {
							print.redLine("  Error rate: #local.m.errorRate#%");
						} else {
							print.greenLine("  Error rate: 0%");
						}

						if (Len(local.m.oldestPending)) {
							print.line();
							print.line("Oldest pending job: #DateTimeFormat(local.m.oldestPending, 'yyyy-mm-dd HH:mm:ss')#");
						}

						// Recent jobs
						if (ArrayLen(local.m.recentJobs)) {
							print.line();
							print.boldLine("Recent Jobs:");
							local.count = Min(ArrayLen(local.m.recentJobs), 5);
							for (local.i = 1; local.i <= local.count; local.i++) {
								local.job = local.m.recentJobs[local.i];
								local.statusColor = "line";
								if (local.job.status == "completed") local.statusColor = "greenLine";
								else if (local.job.status == "failed") local.statusColor = "redLine";
								else if (local.job.status == "processing") local.statusColor = "cyanLine";
								else if (local.job.status == "pending") local.statusColor = "yellowLine";

								print["#local.statusColor#"](
									"  [#local.job.status#] #local.job.jobClass# (#local.job.queue#) - #DateTimeFormat(local.job.updatedAt, 'HH:mm:ss')#"
								);
							}
						}
					}

					// Timeout recoveries
					if (StructKeyExists(local.result, "timeoutsRecovered") && local.result.timeoutsRecovered > 0) {
						print.line();
						print.yellowLine("Recovered #local.result.timeoutsRecovered# timed-out job(s)");
					}
				}
			} catch (any e) {
				print.redLine("[#TimeFormat(Now(), "HH:mm:ss")#] Monitor error: #e.message#");
			}

			sleep(arguments.interval * 1000);
		}
	}

}
