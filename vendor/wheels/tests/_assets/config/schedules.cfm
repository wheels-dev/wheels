<cfscript>
// Fixture for JobSchedulerSpec: a config/schedules.cfm as an app would write it.
schedule("spec_file_digest").job("wheels.tests._assets.jobs.ProcessOrdersJob").cron("0 7 * * MON").timezone("UTC").queue("test_sched_file");
schedule("spec_file_canary").job("wheels.tests._assets.jobs.ProcessOrdersJob").every(15, "minutes").queue("test_sched_file").data({ping = true});
</cfscript>
