/**
 * A job whose parent is a sibling job (`extends="ProbeJob"`, no package), so the
 * jobsEnqueue source check has to follow the chain to wheels.Job.
 */
component extends="ProbeJob" {
}
