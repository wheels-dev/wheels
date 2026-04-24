<cfscript>
// Wheels Guides — moved to guides.wheels.dev
// The GitBook-era in-app renderer was retired in PR #2189 (April 2026).
// This endpoint now redirects HTML callers to the external Starlight site and
// returns a sidebar-derived summary to AI/MCP callers hitting ?format=json.

param name="request.wheels.params.path" default="";
param name="request.wheels.params.format" default="html";

local.externalBase = "https://guides.wheels.dev/v4-0-0-snapshot/";
local.deepLink = local.externalBase;
if (Len(request.wheels.params.path)) {
    local.cleanPath = ReReplace(request.wheels.params.path, "\.md$", "");
    local.cleanPath = ReReplace(local.cleanPath, "^/+", "");
    local.deepLink &= local.cleanPath;
    if (Len(local.cleanPath) && Right(local.deepLink, 1) neq "/") {
        local.deepLink &= "/";
    }
}

// Sidebar JSON is only present in a monorepo checkout; installed apps won't
// have it. Best-effort — callers that need a structured index can hit
// guides.wheels.dev directly.
local.sections = [];
local.sidebarPath = ExpandPath("/wheels/../../web/sites/guides/src/sidebars/v4-0-0-snapshot.json");
if (FileExists(local.sidebarPath)) {
    try {
        local.sections = DeserializeJSON(FileRead(local.sidebarPath));
    } catch (any e) {
        local.sections = [];
    }
}

docs = {
    "title": "Wheels Guides",
    "path": request.wheels.params.path,
    "url": local.deepLink,
    "external": true,
    "source": "https://guides.wheels.dev/",
    "sections": local.sections
};
</cfscript>

<cfif request.wheels.params.format EQ "json">
    <cfcontent type="application/json" reset="true"><cfoutput>#SerializeJSON(docs)#</cfoutput>
<cfelse>
    <cfhtmlhead text="<meta http-equiv=""refresh"" content=""3;url=#encodeForHTMLAttribute(docs.url)#"">">
    <cfoutput>
        <!--- cfformat-ignore-start --->
        <div class="sixteen wide column">
            <div class="ui raised segment">
                <h1>Wheels Guides have moved</h1>
                <p>
                    The full Wheels guides now live at
                    <a href="#encodeForHTMLAttribute(docs.url)#" rel="noopener">#encodeForHTML(docs.url)#</a>.
                    Redirecting in a moment&hellip;
                </p>
                <cfif ArrayLen(docs.sections)>
                    <h2>Jump to a section</h2>
                    <div class="ui relaxed divided list">
                        <cfloop array="#docs.sections#" index="section">
                            <div class="item">
                                <i class="book icon"></i>
                                <div class="content">
                                    <a class="header"
                                       href="https://guides.wheels.dev#encodeForHTMLAttribute(section.link)#"
                                       rel="noopener">#encodeForHTML(section.label)#</a>
                                </div>
                            </div>
                        </cfloop>
                    </div>
                </cfif>
                <p>
                    Looking for older docs? See
                    <a href="https://guides.wheels.dev/v3-0-0/" rel="noopener">v3.0</a> or
                    <a href="https://guides.wheels.dev/v2-5-0/" rel="noopener">v2.5</a>.
                </p>
            </div>
        </div>
        <!--- cfformat-ignore-end --->
    </cfoutput>
</cfif>
