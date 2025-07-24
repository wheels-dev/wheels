<cfscript>
request.isFluid = true;
param name="request.wheels.params.page" default="";
param name="request.wheels.params.format" default="html";

if (request.wheels.params.format EQ "html") {
	include "../layout/_header.cfm";
	include "../docs/guides.cfm";
	include "../layout/_footer.cfm";
} else {
	include "../docs/guides.cfm";
}
</cfscript>