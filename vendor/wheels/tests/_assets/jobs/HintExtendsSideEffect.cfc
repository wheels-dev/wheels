/**
 * Not a job: the only "extends" text is inside another attribute's value. Its
 * pseudo-constructor records that it ran, so the jobsEnqueue spec can show it is
 * refused before it is loaded (CliBridgeJobsEnqueueSpec).
 */
component hint="extends=wheels.Job" {
	application.$wheelsHintExtendsInstantiated = true;
}
