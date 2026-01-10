<cfscript>
    formats = ["html","junit","json","txt"];
    _baseParams = "";
    for (key in "reload,db,format,refresh") {
        if (StructKeyExists(url, key)) {
            _baseParams = ListAppend(_baseParams, "#key#=#url[key]#", "&");
        }
    }
    _params = _baseParams;
    for (key in "package,test") {
        if (StructKeyExists(url, key)) {
            _params = ListAppend(_params, "#key#=#url[key]#", "&");
        }
    }
</cfscript>
<cfoutput>
    <div class="ui segment">
        <div class="ui stackable grid">
            <div class="two column row">
                <div class="four wide column">
                    <!--- Route Filter --->
                    <div class="ui action input">
                        <input
                            type="text"
                            class="table-searcher"
                            name="package-search" id="package-search"
                            placeholder="Quick find..."
                        >
                        <button class="ui icon button matched-count">
                            <svg xmlns="http://www.w3.org/2000/svg" height="16" width="16" viewBox="0 0 512 512"><path  fill="##7e7e7f" d="M505 442.7L405.3 343c-4.5-4.5-10.6-7-17-7H372c27.6-35.3 44-79.7 44-128C416 93.1 322.9 0 208 0S0 93.1 0 208s93.1 208 208 208c48.3 0 92.7-16.4 128-44v16.3c0 6.4 2.5 12.5 7 17l99.7 99.7c9.4 9.4 24.6 9.4 33.9 0l28.3-28.3c9.4-9.4 9.4-24.6 .1-34zM208 336c-70.7 0-128-57.2-128-128 0-70.7 57.2-128 128-128 70.7 0 128 57.2 128 128 0 70.7-57.2 128-128 128z"/></svg>
                            <span class="matched-count-value"></span>
                        </button>
                    </div>
                </div>
                <div class="twelve wide column right aligned">
                    <a href="#urlFor(route = "#route#")#" class="ui button basic blue">
                        Run All Tests &nbsp<svg xmlns="http://www.w3.org/2000/svg" height="16" width="14" viewBox="0 0 448 512"><path  fill="##4d9dd9" d="M438.6 278.6c12.5-12.5 12.5-32.8 0-45.3l-160-160c-12.5-12.5-32.8-12.5-45.3 0s-12.5 32.8 0 45.3L338.8 224 32 224c-17.7 0-32 14.3-32 32s14.3 32 32 32l306.7 0L233.4 393.4c-12.5 12.5-12.5 32.8 0 45.3s32.8 12.5 45.3 0l160-160z"/></svg>
                    </a>
                    <cfloop array="#formats#" index="_format">
                        <cfif StructKeyExists(url, "format")>
                            <cfset __params = ReplaceNoCase(_params, "format=#url.format#", "format=#_format#")>
                        <cfelse>
                            <cfset __params = ListAppend(_params, "format=#_format#", "&")>
                        </cfif>
                        <a href="#urlFor(route = "#route#", params = __params)#" class="ui button basic<cfif _format eq "html"> active</cfif>">
                            #_format#
                        </a>
                    </cfloop>
                </div>
            </div>
        </div>
    </div>
</cfoutput>
    