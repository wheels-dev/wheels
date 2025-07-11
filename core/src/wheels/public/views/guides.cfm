<cfscript>
    request.isFluid = true;
    param name="request.wheels.params.guide" default="README.md";
    param name="request.wheels.params.format" default="html";
    
    function getGuidesTree(path, parentPath = "") {
        var tree = [];
        var dirList = directoryList(path, true, "query");
        for (var i = 1; i <= dirList.recordCount; i++) {
            var isDir = dirList.type[i] == "Dir";
            var name = dirList.name[i];
            if (isDir) {
                // Skip hidden/system folders
                if (left(name, 1) == ".") continue;
                tree.append({
                    type: "folder",
                    name: name,
                    children: getGuidesTree(path & "/" & name, parentPath & name & "/")
                });
            } else if (listLast(name, ".") == "md") {
                tree.append({
                    type: "file",
                    name: name,
                    file: parentPath & name
                });
            }
        }
        return tree;
    }
    
    // Build the guides tree from /wheels/docs/src
    var guidesTree = getGuidesTree("/wheels/docs/src");
    
    // Flatten for lookup
    function flattenGuides(tree, parentPath = "") {
        var flat = [];
        for (var item in tree) {
            if (item.type == "file") {
                flat.append({ name: item.name, file: parentPath & item.name });
            } else if (item.type == "folder") {
                flat.append(flattenGuides(item.children, parentPath & item.name & "/"));
            }
        }
        
        // Flatten nested arrays manually
        var result = [];
        for (var f in flat) {
            if (isArray(f)) {
                result.addAll(f);
            } else {
                result.append(f);
            }
        }
        return result;
    }
    var flatGuides = flattenGuides(guidesTree);
    
    // Find the selected guide
    var selectedGuide = request.wheels.params.guide;
    if (!flatGuides.some(function(g) { return g.file == selectedGuide; })) {
        selectedGuide = flatGuides.len() ? flatGuides[1].file : "";
    }
    var guideContent = "";
    if (len(selectedGuide)) {
        var guidePath = expandPath("/docs/src/" & selectedGuide);
        if (fileExists(guidePath)) {
            guideContent = fileRead(guidePath);
        } else {
            guideContent = "## Not found";
        }
    }
    </cfscript>
    <cfoutput>
    <cfif request.wheels.params.format EQ "html">
        <cfinclude template="../layout/_header.cfm">
    </cfif>
    <div class="ui container" id="guides-app">
      <div class="ui grid stackable">
        <div class="four wide column">
          <div class="ui vertical menu fluid" id="guides-sidebar">
            <div class="header item">Guides</div>
            #renderGuidesSidebar(guidesTree, selectedGuide)#
          </div>
        </div>
        <div class="twelve wide column">
          <div id="guides-content" class="ui segment" style="min-height:400px;">
            <h2 class="ui header">#encodeForHTML(selectedGuide)#</h2>
            <pre style="background:##f9f9f9; padding:1em;">#encodeForHTML(guideContent)#</pre>
            <!-- Replace above with markdown rendering when ready -->
          </div>
        </div>
      </div>
    </div>
    <cfif request.wheels.params.format EQ "html">
        <cfinclude template="../layout/_footer.cfm">
    </cfif>
    </cfoutput>
    <!--- Helper to render sidebar recursively --->
    <cfscript>
    function renderGuidesSidebar(tree, selected, parentPath = "") {
        var html = "";
        for (var item in tree) {
            if (item.type == "file") {
                var active = (parentPath & item.name) == selected ? "active" : "";
                var displayName = replace(replaceNoCase(item.name, ".md$", "", "all"), "-", " ", "all");
                html &= '<a class="item guide-link ' & active & '" href="?guide=' & encodeForURL(parentPath & item.name) & '">' & displayName & '</a>';
            } else if (item.type == "folder") {
                html &= '<div class="item submenu"><b>' & item.name & '</b>';
                html &= renderGuidesSidebar(item.children, selected, parentPath & item.name & "/");
                html &= '</div>';
            }
        }
        return html;
    }
    </cfscript> 