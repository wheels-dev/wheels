component {

    public array function parseSummary(required string summaryPath) {
        local.nav = [];

        if (fileExists(expandPath(arguments.summaryPath))) {
            local.summaryContent = fileRead(expandPath(arguments.summaryPath));
            local.lines = listToArray(local.summaryContent, chr(10));

            local.currentSection = "";
            local.currentSubsection = "";
            local.currentItems = [];
            local.currentSubItems = [];

            for (local.line in local.lines) {
                local.trimmedLine = trim(local.line);

                if (!len(local.trimmedLine)) continue;

                if (reFind("^##{1,2}\s", local.trimmedLine)) {
                    if (len(local.currentSection)) {
                        arrayAppend(local.nav, {
                            "title": local.currentSection,
                            "items": local.currentItems
                        });
                    }

                    local.currentSection = trim(reReplace(local.trimmedLine, "^##+\s*", ""));
                    local.currentItems = [];
                    local.currentSubsection = "";
                    local.currentSubItems = [];
                }

                else if (reFind("^\*\s+[^\[]+$", local.trimmedLine)) {
                    if (len(local.currentSubsection) && arrayLen(local.currentSubItems)) {
                        arrayAppend(local.currentItems, {
                            "title": local.currentSubsection,
                            "items": local.currentSubItems
                        });
                    }

                    local.currentSubsection = trim(reReplace(local.trimmedLine, "^\*\s+", ""));
                    local.currentSubItems = [];
                }

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

    public string function renderGuideItems(required array items, required string currentPath) output=true {
        for (var item in arguments.items) {
            if (structKeyExists(item, "link")) {
                // Determine if the link is external
                var isExternal = reFindNoCase("^(http|https)://", item.link) > 0;

                // Clean internal .md links
                if (!isExternal) {
                    var cleanLink = lcase(reReplace(item.link, "\.md$", ""));
                    var isActive = (arguments.currentPath == cleanLink) ? " active" : "";
                }

                if (isExternal) {
                    // External Link
                    writeOutput(
                        '<a href="#item.link#" target="_blank" rel="noopener noreferrer" class="item">#item.title#</a>'
                    );
                } else {
                    // Internal Guide Link (routed through /wheels/guides/)
                    writeOutput(
                        '<a href="/wheels/guides/#cleanLink#" class="item#isActive#">#item.title#</a>'
                    );
                }

            } else if (structKeyExists(item, "items")) {
                // It's a subsection/group
                writeOutput('<div class="header">#item.title#</div>');
                writeOutput('<div class="list">');
                writeOutput(renderGuideItems(item.items, arguments.currentPath));
                writeOutput('</div>');
            }
        }

        return "";
    }

}
