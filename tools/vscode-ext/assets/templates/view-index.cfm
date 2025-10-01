<!--- ${modelName} Index --->
<cfparam name="${itemsVar}">
<cfoutput>
    <h1>${itemsVar} index</h1>
    <p>#linkTo(route="new${modelName}", text="Create New ${modelName}", class="btn btn-default")#</p>

    <cfif ${itemsVar}.recordcount>
        <table class="table">
            <thead>
                <tr>
                    <th>ID</th>
                    <!--- CLI-Appends-thead-Here --->
                    <th>Actions</th>
                </tr>
            </thead>
            <tbody>
                <cfloop query="${itemsVar}">
                <tr>
                    <td>
                        #id#
                    </td>
                    <!--- CLI-Appends-tbody-Here --->
                    <td>
                        <div class="btn-group">
                            #linkTo(route="${modelName}", key=id, text="View", class="btn btn-xs btn-info", encode=false)#
                            #linkTo(route="edit${modelName}", key=id, text="Edit", class="btn btn-xs btn-primary", encode=false)#
                        </div>
                        #buttonTo(route="${modelName}", method="delete", key=id, text="Delete", class="pull-right", inputClass="btn btn-danger btn-xs", encode=false)#
                    </td>
                </tr>
                </cfloop>
            </tbody>
        </table>
    <cfelse>
        <p>Sorry, there are no ${itemsVar} yet</p>
    </cfif>
</cfoutput>