/**
 * Start a job worker daemon that continuously polls for and processes jobs.
 *
 * The worker calls the Wheels bridge each poll cycle to claim and process
 * the next available job. Run multiple workers for parallelism.
 *
 * {code:bash}
 * wheels jobs work
 * wheels jobs work --queue=mailers
 * wheels jobs work --queue=mailers,default --interval=3
 * wheels jobs work --max-jobs=100
 * {code}
 */
component extends="../base" {

	property name="detailOutput" inject="DetailOutputService@wheels-cli";

	/**
	 * @queue      Comma-delimited queue names to process (default: all queues)
	 * @interval   Seconds between poll cycles (default: 5)
	 * @maxJobs    Stop after processing this many jobs (default: 0 = unlimited)
	 * @timeout    Job execution timeout in seconds (default: 300)
	 * @quiet      Suppress per-job output, only show errors
	 */
	public void function run(
		string queue = "",
		numeric interval = 5,
		numeric maxJobs = 0,
		numeric timeout = 300,
		boolean quiet = false
	) {
		local.appPath = getCWD();

		if (!isWheelsApp(local.appPath)) {
			error("This command must be run from a Wheels application directory");
			return;
		}

		detailOutput.header("Wheels Job Worker");
		detailOutput.output("Press Ctrl+C to stop");
		detailOutput.line();

		if (Len(arguments.queue)) {
			detailOutput.metric("Queues", arguments.queue);
		} else {
			detailOutput.metric("Queues", "all");
		}
		detailOutput.metric("Poll interval", "#arguments.interval#s");
		if (arguments.maxJobs > 0) {
			detailOutput.metric("Max jobs", arguments.maxJobs);
		}
		detailOutput.line();

		local.processed = 0;
		local.failed = 0;
		local.cycles = 0;

		while (true) {
			local.cycles++;

			// Build URL parameters
			local.urlParams = "&command=jobsProcessNext";
			if (Len(arguments.queue)) {
				local.urlParams &= "&queues=#arguments.queue#";
			}
			local.urlParams &= "&timeout=#arguments.timeout#";

			try {
				local.result = $sendToCliCommand(urlstring = local.urlParams);

				if (StructKeyExists(local.result, "success") && local.result.success && StructKeyExists(local.result, "jobResult")) {
					local.jr = local.result.jobResult;

					if (StructKeyExists(local.jr, "skipped") && local.jr.skipped) {
						// No jobs available — just wait
					} else if (StructKeyExists(local.jr, "success") && local.jr.success) {
						local.processed++;
						if (!arguments.quiet) {
							detailOutput.output("[#TimeFormat(Now(), "HH:mm:ss")#] Completed: #local.jr.jobClass# (#local.jr.jobId#)");
						}

						// Check max jobs limit
						if (arguments.maxJobs > 0 && local.processed >= arguments.maxJobs) {
							detailOutput.line();
							detailOutput.success("Reached max jobs limit (#arguments.maxJobs#). Shutting down.");
							detailOutput.output("Processed: #local.processed# | Failed: #local.failed#");
							return;
						}

						// Process more immediately if there was work
						continue;
					} else {
						local.failed++;
						local.errorMsg = StructKeyExists(local.jr, "error") ? local.jr.error : "Unknown error";
						detailOutput.error("[#TimeFormat(Now(), "HH:mm:ss")#] Failed: #local.jr.jobClass# - #local.errorMsg#");

						// Check max jobs limit (failures count too)
						if (arguments.maxJobs > 0 && (local.processed + local.failed) >= arguments.maxJobs) {
							detailOutput.line();
							detailOutput.success("Reached max jobs limit (#arguments.maxJobs#). Shutting down.");
							detailOutput.output("Processed: #local.processed# | Failed: #local.failed#");
							return;
						}
					}
				}
			} catch (any e) {
				detailOutput.error("[#TimeFormat(Now(), "HH:mm:ss")#] Worker error: #e.message#");
			}

			sleep(arguments.interval * 1000);
		}
	}

}
