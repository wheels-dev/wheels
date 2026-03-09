<cfscript>
// Guides Documentation System
param name="request.wheels.params.path" default="";
param name="request.wheels.params.format" default="html";

// Setup paths
local.docsPath = "/wheels/docs/src/";
local.summaryPath = local.docsPath & "SUMMARY.md";

// Get navigation structure
local.docsHelper = new wheels.public.docs.DocsHelper();
local.navigation = local.docsHelper.parseSummary(local.summaryPath);

// Determine which guide to display
local.guidePath = "";
local.guideContent = "";
local.guideTitle = "Wheels Documentation";

if (len(request.wheels.params.path)) {
    if(right(request.wheels.params.path, 3) eq '.md'){
        local.guidePath = local.docsPath & request.wheels.params.path;
    } else {
        local.guidePath = local.docsPath & request.wheels.params.path & ".md";
    }
    
    // Check if file exists
    if (fileExists(expandPath(local.guidePath))) {
        local.guideContent = fileRead(expandPath(local.guidePath));
        local.guideTitle = request.wheels.params.path;
    } else {
        local.guideContent = "Guide not found: " & request.wheels.params.path;
    }
} else {
    // Default content - show introduction
    local.readmePath = local.docsPath & "README.md";
    if (fileExists(expandPath(local.readmePath))) {
        local.guideContent = fileRead(expandPath(local.readmePath));
        local.guideTitle = "Introduction";
    } else {
        local.guideContent = "## Wheels Documentation\n\nSelect a guide from the navigation menu.";
    }
}

local.htmlContent = local.guideContent;

// Create docs structure similar to API docs
local.guides = {
    "navigation" = local.navigation,
    "content" = local.htmlContent,
    "title" = local.guideTitle,
    "path" = request.wheels.params.path
};

// Make it available to the layout
docs = local.guides;
</cfscript>

<cfif request.wheels.params.format EQ "html">
    <cfinclude template="layouts/guides.cfm">
<cfelse>
    <cfinclude template="layouts/guides-plain.cfm">
</cfif>