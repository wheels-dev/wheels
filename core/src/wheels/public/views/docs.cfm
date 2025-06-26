<cfscript>
request.isFluid = true;
param name="request.wheels.params.type" default="core";
param name="request.wheels.params.format" default="html";

// Example Expected comment
/**
 * I am the function hint. Backticks replaced with code; tags below get replaced.
 * Tags must appear before Params
 *
 * [section: Doc Section]
 * [category: Doc Category] (optional, but recommended)
 *
 * @paramName Hint for Param. Backticks replaced with code; [doc: AFunctionName] replaced with link
 */
if (request.wheels.params.format EQ "html") {
	include "../layout/_header.cfm";
	include "../docs/#request.wheels.params.type#.cfm";
	include "../layout/_footer.cfm";
} else {
	include "../docs/#request.wheels.params.type#.cfm";
}
</cfscript>
