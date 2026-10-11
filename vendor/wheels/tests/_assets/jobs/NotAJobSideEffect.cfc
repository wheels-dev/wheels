/**
 * Allowlisted jobs path, not a job, and its pseudo-constructor records that it
 * ran. The jobsEnqueue bridge command must refuse it from its name and metadata
 * alone, without instantiating it (CliBridgeJobsEnqueueSpec).
 */
component {
	application.$wheelsNotAJobInstantiated = true;
}
