<cfscript>
// Wheels Guides — moved to guides.wheels.dev
// The GitBook-era in-app renderer was retired in PR #2189 (April 2026).
// This endpoint now redirects HTML callers to the external Starlight site and
// returns a sidebar-derived summary to AI/MCP callers hitting ?format=json.

param name="request.wheels.params.path" default="";
param name="request.wheels.params.format" default="html";

// Resolve the active guides version from the monorepo sidebars directory
// (snapshot or GA — whichever sorts highest). The previous implementation
// hardcoded "v4-0-0-snapshot", which broke the in-app sidebar the moment
// v4.0.0 went GA and the snapshot file was renamed (issue ##2647). Sidebar
// basenames like "v4-0-1-snapshot.json" / "v4-0-0.json" sort sensibly in
// descending lexicographic order because the version segment (e.g.
// "4-0-1") dominates — the snapshot is always named at the NEXT minor
// version while GA files carry the released version. Note: at an
// identical version prefix, "-snapshot" sorts LOWER than ".json" (ASCII
// "." > "-"), so if "v4-0-1.json" and "v4-0-1-snapshot.json" ever
// coexist the GA wins; in practice only one exists at a time. Falls
// back to "v4-0-0" when the monorepo tree isn't present so the external
// redirect still lands somewhere valid in installed apps.
local.sidebarDir = ExpandPath("/wheels/../../web/sites/guides/src/sidebars");
local.activeSlug = "v4-0-0";
local.sidebarPath = "";
if (DirectoryExists(local.sidebarDir)) {
    local.candidates = DirectoryList(local.sidebarDir, false, "name", "*.json");
    if (ArrayLen(local.candidates)) {
        ArraySort(local.candidates, "textnocase", "desc");
        local.activeSlug = ReReplace(local.candidates[1], "\.json$", "");
        local.sidebarPath = local.sidebarDir & "/" & local.candidates[1];
    }
}

local.externalBase = "https://guides.wheels.dev/" & local.activeSlug & "/";
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
if (Len(local.sidebarPath) && FileExists(local.sidebarPath)) {
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
    <cfoutput>
        <!--- cfformat-ignore-start --->
        <!---
            Body-level redirect. The wrapper view (../views/guides.cfm)
            includes ../layout/_header.cfm before this template, so by the
            time we reach this point the response has already streamed
            past </head>. Lucee tolerates a late <cfhtmlhead> but Adobe
            ColdFusion throws "Unable to add text to HTML HEAD tag." See
            issue ##2569. We read the redirect target from a hidden data
            attribute and trigger the navigation in JavaScript — the URL
            still flows through encodeForHTMLAttribute, the same encoder
            used for the visible anchor a few lines below.
         --->
        <div id="wheels-guides-redirect" data-url="#encodeForHTMLAttribute(docs.url)#" hidden></div>
        <script>
            (function() {
                var el = document.getElementById('wheels-guides-redirect');
                if (el) {
                    setTimeout(function() {
                        window.location.href = el.getAttribute('data-url');
                    }, 3000);
                }
            })();
        </script>
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
