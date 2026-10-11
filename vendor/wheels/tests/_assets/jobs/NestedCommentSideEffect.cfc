<!--- outer <!--- inner ---> <cfcomponent extends="wheels.Job"> --->
A tag-based component that is not a job: the only extends is inside nested comments.
Its body records that it ran, so the jobsEnqueue spec can show it is never loaded.
<cfcomponent>
	<cfset application.$wheelsNestedCommentInstantiated = true>
</cfcomponent>
