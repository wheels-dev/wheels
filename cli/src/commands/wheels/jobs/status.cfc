/**
 * Show job queue statistics.
 *
 * {code:bash}
 * wheels jobs status
 * wheels jobs status --queue=mailers
 * wheels jobs status --format=json
 * {code}
 */
component extends="../../base" {

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

		print.line();
		print.boldBlueLine("Job Queue Status");
		print.line();

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
			print.line(SerializeJSON(local.result.stats));
			return;
		}

		// Display per-queue table
		if (StructKeyExists(local.result, "stats") && StructKeyExists(local.result.stats, "queues")) {
			local.queues = local.result.stats.queues;

			if (StructCount(local.queues) == 0) {
				print.line("No jobs found.");
				print.line();
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

			print.line(local.separator);
			print.line(local.header);
			print.line(local.separator);

			for (local.queueName in local.queues) {
				local.q = local.queues[local.queueName];
				print.text("| " & PadRight(local.queueName, 20) & " | ");
				print.yellowText(PadRight(local.q.pending, 10));
				print.text(" | ");
				print.cyanText(PadRight(local.q.processing, 12));
				print.text(" | ");
				print.greenText(PadRight(local.q.completed, 12));
				print.text(" | ");
				if (local.q.failed > 0) {
					print.redText(PadRight(local.q.failed, 10));
				} else {
					print.text(PadRight(local.q.failed, 10));
				}
				print.line(" | " & PadRight(local.q.total, 10) & " |");
			}

			// Totals row
			local.totals = local.result.stats.totals;
			print.line(local.separator);
			print.text("| " & PadRight("TOTAL", 20) & " | ");
			print.boldYellowText(PadRight(local.totals.pending, 10));
			print.text(" | ");
			print.boldCyanText(PadRight(local.totals.processing, 12));
			print.text(" | ");
			print.boldGreenText(PadRight(local.totals.completed, 12));
			print.text(" | ");
			if (local.totals.failed > 0) {
				print.boldRedText(PadRight(local.totals.failed, 10));
			} else {
				print.boldText(PadRight(local.totals.failed, 10));
			}
			print.line(" | " & PadRight(local.totals.total, 10) & " |");
			print.line(local.separator);
		}

		print.line();
	}

	private string function PadRight(required string text, required numeric length) {
		local.str = ToString(arguments.text);
		if (Len(local.str) >= arguments.length) {
			return Left(local.str, arguments.length);
		}
		return local.str & RepeatString(" ", arguments.length - Len(local.str));
	}

}
