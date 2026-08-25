/**
 * Forces $enqueueJob down the persist-fail path by pointing at a datasource
 * that cannot exist. Used to pin B2: a failed persist must not lie with
 * status=pending.
 */
component extends="wheels.Job" {

	public function init() {
		super.init();
		variables.$datasource = "wheels_jobs_no_such_ds_zzz";
		return this;
	}

}
