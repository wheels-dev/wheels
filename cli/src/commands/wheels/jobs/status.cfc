/**
 * Show job queue statistics.
 *
 * {code:bash}
 * wheels jobs status
 * wheels jobs status --queue=mailers
 * wheels jobs status --format=json
 * {code}
 */
component extends="../base" {

	property name="detailOutput" inject="DetailOutputService@wheels-cli";

	/**
	 * @queue  Filter by queue name (default: all queues)
	 * @format Output format: table or json (default: table)
	 */
	public void function run(
		string queue = "",
		string format = "table"
	) {
		local.appPath = getCWD();

		if (!isWheelsApp(local.appPath)) {
			error("This command must be run from a Wheels application directory");
			return;
		}

		detailOutput.header("Job Queue Status");

		// Build URL parameters
		local.urlParams = "&command=jobsStatus";
		if (Len(arguments.queue)) {
			local.urlParams &= "&queue=#arguments.queue#";
		}

		local.result = $sendToCliCommand(urlstring = local.urlParams);
		if (!local.result.success) {
			return;
		}

		if (arguments.format == "json") {
			detailOutput.output(SerializeJSON(local.result.stats));
			return;
		}

		// Display per-queue table
		if (StructKeyExists(local.result, "stats") && StructKeyExists(local.result.stats, "queues")) {
			local.queues = local.result.stats.queues;

			if (StructCount(local.queues) == 0) {
				detailOutput.output("No jobs found.");
				detailOutput.line();
				return;
			}

			// Header
			local.header = "| " & PadRight("Queue", 20) & " | " &
							PadRight("Pending", 10) & " | " &
							PadRight("Processing", 12) & " | " &
							PadRight("Completed", 12) & " | " &
							PadRight("Failed", 10) & " | " &
							PadRight("Total", 10) & " |";
			local.separator = RepeatString("-", Len(local.header));

			detailOutput.getPrint().line(local.separator);
			detailOutput.getPrint().line(local.header);
			detailOutput.getPrint().line(local.separator);

			for (local.queueName in local.queues) {
				local.q = local.queues[local.queueName];
				detailOutput.getPrint().text("| " & PadRight(local.queueName, 20) & " | ");
				detailOutput.getPrint().yellowText(PadRight(local.q.pending, 10));
				detailOutput.getPrint().text(" | ");
				detailOutput.getPrint().cyanText(PadRight(local.q.processing, 12));
				detailOutput.getPrint().text(" | ");
				detailOutput.getPrint().greenText(PadRight(local.q.completed, 12));
				detailOutput.getPrint().text(" | ");
				if (local.q.failed > 0) {
					detailOutput.getPrint().redText(PadRight(local.q.failed, 10));
				} else {
					detailOutput.getPrint().text(PadRight(local.q.failed, 10));
				}
				detailOutput.getPrint().line(" | " & PadRight(local.q.total, 10) & " |");
			}

			// Totals row
			local.totals = local.result.stats.totals;
			detailOutput.getPrint().line(local.separator);
			detailOutput.getPrint().text("| " & PadRight("TOTAL", 20) & " | ");
			detailOutput.getPrint().boldYellowText(PadRight(local.totals.pending, 10));
			detailOutput.getPrint().text(" | ");
			detailOutput.getPrint().boldCyanText(PadRight(local.totals.processing, 12));
			detailOutput.getPrint().text(" | ");
			detailOutput.getPrint().boldGreenText(PadRight(local.totals.completed, 12));
			detailOutput.getPrint().text(" | ");
			if (local.totals.failed > 0) {
				detailOutput.getPrint().boldRedText(PadRight(local.totals.failed, 10));
			} else {
				detailOutput.getPrint().boldText(PadRight(local.totals.failed, 10));
			}
			detailOutput.getPrint().line(" | " & PadRight(local.totals.total, 10) & " |");
			detailOutput.getPrint().line(local.separator);
		}

		detailOutput.line();
	}

	private string function PadRight(required string text, required numeric length) {
		local.str = ToString(arguments.text);
		if (Len(local.str) >= arguments.length) {
			return Left(local.str, arguments.length);
		}
		return local.str & RepeatString(" ", arguments.length - Len(local.str));
	}

}
