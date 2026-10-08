/**
 * HookProbeJob that must never run twice (core-suite fixture): a reaped attempt ends
 * 'interrupted', which the hook specs check fires onFailure as final.
 */
component extends="wheels.tests._assets.jobs.HookProbeJob" {

	function config() {
		super.config();
		this.idempotent = false;
	}

}
