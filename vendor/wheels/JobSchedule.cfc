/**
 * One recurring job schedule, as defined in config/schedules.cfm:
 *
 *   schedule("weeklyDigest").job("DigestJob").cron("0 7 * * MON").timezone("America/New_York");
 *   schedule("canary").job("CanaryJob").every(15, "minutes").queue("ops").data({ping: true});
 *
 * Every builder method returns the schedule, so calls chain.
 */
component {

	public function init(required string name) {
		variables.def = {
			name = Trim(arguments.name),
			jobClass = "",
			data = {},
			queue = "",
			priority = "",
			kind = "",
			spec = "",
			timezone = "UTC",
			catchUp = "latest",
			catchUpWindowSeconds = 3600,
			enabled = true
		};
		return this;
	}

	/** The job class to enqueue: a name under app/jobs (e.g. "DigestJob" or "billing.InvoiceJob") or a full component path. */
	public any function job(required string jobClass) {
		variables.def.jobClass = Trim(arguments.jobClass);
		return this;
	}

	/** A 5-field cron expression (or an @hourly/@daily/... alias), read in the schedule's time zone. */
	public any function cron(required string expression) {
		variables.def.kind = "cron";
		variables.def.spec = Trim(arguments.expression);
		return this;
	}

	/** Every n minutes or hours, at fixed UTC-aligned times (every 15 minutes = :00, :15, :30, :45). For days or longer, use cron(). */
	public any function every(required numeric count, string unit = "minutes") {
		local.unit = LCase(Trim(arguments.unit));
		local.seconds = 0;
		if (ListFindNoCase("minute,minutes", local.unit)) {
			local.seconds = arguments.count * 60;
		} else if (ListFindNoCase("hour,hours", local.unit)) {
			local.seconds = arguments.count * 3600;
		} else {
			Throw(
				type = "Wheels.Job.InvalidSchedule",
				message = "Schedule '#variables.def.name#': every() takes minutes or hours, not '#arguments.unit#'. For days or longer, use cron(), e.g. cron(""0 3 * * *"")."
			);
		}
		if (arguments.count < 1 || arguments.count != Fix(arguments.count)) {
			Throw(type = "Wheels.Job.InvalidSchedule", message = "Schedule '#variables.def.name#': every() needs a whole number of at least 1.");
		}
		variables.def.kind = "interval";
		variables.def.spec = local.seconds;
		return this;
	}

	/** The IANA time zone cron() is read in (default UTC), e.g. America/New_York. */
	public any function timezone(required string zone) {
		variables.def.timezone = Trim(arguments.zone);
		return this;
	}

	/** What to do about slots missed while nothing ran: "latest" (default) runs the newest one, if it's within catchUpWindow(); "none" runs only a slot that is due now. */
	public any function catchUp(required string mode) {
		variables.def.catchUp = LCase(Trim(arguments.mode));
		return this;
	}

	/** How old (seconds) a missed slot may be and still run with catchUp("latest"). Default 3600. Keep it below your purge retention. */
	public any function catchUpWindow(required numeric seconds) {
		variables.def.catchUpWindowSeconds = arguments.seconds;
		return this;
	}

	public any function queue(required string name) {
		variables.def.queue = Trim(arguments.name);
		return this;
	}

	public any function priority(required numeric value) {
		variables.def.priority = arguments.value;
		return this;
	}

	/** The data passed to the job's perform(). */
	public any function data(required struct value) {
		variables.def.data = arguments.value;
		return this;
	}

	public any function enabled(required boolean value) {
		variables.def.enabled = arguments.value;
		return this;
	}

	/**
	 * Internal: the definition, after checking it. Throws Wheels.Job.InvalidSchedule.
	 */
	public struct function $definition(required any cron) {
		local.d = variables.def;
		local.label = "Schedule '#local.d.name#'";
		if (!REFind("^[A-Za-z0-9][A-Za-z0-9_.:-]{0,99}$", local.d.name)) {
			Throw(type = "Wheels.Job.InvalidSchedule", message = "Schedule names are 1-100 letters, digits, dots, colons, dashes or underscores; '#local.d.name#' isn't one.");
		}
		if (!Len(local.d.jobClass)) {
			Throw(type = "Wheels.Job.InvalidSchedule", message = "#local.label# has no job(): say which job class to enqueue.");
		}
		if (!Len(local.d.kind)) {
			Throw(type = "Wheels.Job.InvalidSchedule", message = "#local.label# has no cron() or every(): say when it runs.");
		}
		if (!ListFind("latest,none", local.d.catchUp)) {
			Throw(type = "Wheels.Job.InvalidSchedule", message = "#local.label#: catchUp() is ""latest"" or ""none"", not '#local.d.catchUp#'.");
		}
		if (local.d.catchUpWindowSeconds < 60) {
			Throw(type = "Wheels.Job.InvalidSchedule", message = "#local.label#: catchUpWindow() must be at least 60 seconds.");
		}
		if (local.d.kind == "cron") {
			arguments.cron.parse(local.d.spec);
		}
		arguments.cron.validateTimeZone(local.d.timezone);
		return Duplicate(local.d);
	}

}
