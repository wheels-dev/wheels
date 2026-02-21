<cfscript>
// Guides Documentation System
param name="request.wheels.params.path" default="";
param name="request.wheels.params.format" default="html";

// Setup paths
local.docsPath = "/wheels/docs/src/";
local.summaryPath = local.docsPath & "SUMMARY.md";

// Function to parse navigation from SUMMARY.md
function parseSummary(summaryPath) {
    local.nav = [];

    if (fileExists(arguments.summaryPath)) {
        local.summaryContent = fileRead(arguments.summaryPath);
        local.lines = listToArray(local.summaryContent, chr(10));

        local.currentSection = "";
        local.currentSubsection = "";
        local.currentItems = [];
        local.currentSubItems = [];

        for (local.line in local.lines) {
            local.trimmedLine = trim(local.line);

            // Skip empty lines
            if (!len(local.trimmedLine)) continue;

            // Main section headers: "# " or "## "
            if (reFind("^##{1,2}\s", local.trimmedLine)) {
                // Save previous section
                if (len(local.currentSection)) {
                    arrayAppend(local.nav, {
                        "title": local.currentSection,
                        "items": local.currentItems
                    });
                }

                // Reset everything for new section
                local.currentSection = trim(reReplace(local.trimmedLine, "^##+\s*", ""));
                local.currentItems = [];
                local.currentSubsection = "";
                local.currentSubItems = [];
            }

            // Subsection title (not a link)
            else if (reFind("^\*\s+[^\[]+$", local.trimmedLine)) {
                // If previous subsection exists, push it
                if (len(local.currentSubsection) && arrayLen(local.currentSubItems)) {
                    arrayAppend(local.currentItems, {
                        "title": local.currentSubsection,
                        "items": local.currentSubItems
                    });
                }

                local.currentSubsection = trim(reReplace(local.trimmedLine, "^\*\s+", ""));
                local.currentSubItems = [];
            }

            // Navigation items (Markdown links)
            else if (reFind("^\*\s+\[", local.trimmedLine)) {
                local.linkMatch = reMatch("\*\s+\[([^\]]+)\]\(([^\)]+)\)", local.trimmedLine);

                if (arrayLen(local.linkMatch)) {
                    local.title = reReplace(local.linkMatch[1], "\*\s+\[([^\]]+)\]\(([^\)]+)\)", "\1");
                    local.link = reReplace(local.linkMatch[1], "\*\s+\[([^\]]+)\]\(([^\)]+)\)", "\2");

                    local.link = reReplace(local.link, "\.md$", "");
                    local.link = reReplace(local.link, "^/", "");

                    local.linkItem = {
                        "title": local.title,
                        "link": local.link
                    };

                    if (len(local.currentSubsection)) {
                        arrayAppend(local.currentSubItems, local.linkItem);
                    } else {
                        arrayAppend(local.currentItems, local.linkItem);
                    }
                }
            }
        }

        // Final section/subsection flush
        if (len(local.currentSubsection) && arrayLen(local.currentSubItems)) {
            arrayAppend(local.currentItems, {
                "title": local.currentSubsection,
                "items": local.currentSubItems
            });
        }

        if (len(local.currentSection)) {
            arrayAppend(local.nav, {
                "title": local.currentSection,
                "items": local.currentItems
            });
        }
    }

    return local.nav;
}

// Get navigation structure
local.navigation = parseSummary(local.summaryPath);

// Determine which guide to display
local.guidePath = "";
local.guideContent = "";
local.guideTitle = "Wheels Documentation";

if (len(request.wheels.params.path)) {
    local.guidePath = local.docsPath & request.wheels.params.path & ".md";
    
    // Check if file exists
    if (fileExists(local.guidePath)) {
        local.guideContent = fileRead(local.guidePath);
        local.guideTitle = request.wheels.params.path;
    } else {
        local.guideContent = "Guide not found: " & request.wheels.params.path;
    }
} else {
    // Default content - show introduction
    local.readmePath = local.docsPath & "README.md";
    if (fileExists(local.readmePath)) {
        local.guideContent = fileRead(local.readmePath);
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