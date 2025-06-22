<cfoutput>

##contentFor(title="@PLURAL_NAME@")##

<div class="page-header">
    <h1>@PLURAL_NAME@</h1>
    <div class="actions">
        ##linkTo(route="new@SINGULAR_NAME@", text="New @SINGULAR_NAME@", class="btn btn-primary")##
    </div>
</div>

<cfif @PLURAL_LOWER_NAME@.recordCount>
    <table class="table">
        <thead>
            <tr>
@TABLE_HEADERS@
                <th class="actions">Actions</th>
            </tr>
        </thead>
        <tbody>
            <cfloop query="@PLURAL_LOWER_NAME@">
                <tr>
@TABLE_CELLS@
                    <td class="actions">
                        ##linkTo(route="@SINGULAR_LOWER_NAME@", key=@PLURAL_LOWER_NAME@.id, text="View", class="btn btn-sm btn-info")##
                        ##linkTo(route="edit@SINGULAR_NAME@", key=@PLURAL_LOWER_NAME@.id, text="Edit", class="btn btn-sm btn-warning")##
                        ##linkTo(route="@SINGULAR_LOWER_NAME@", key=@PLURAL_LOWER_NAME@.id, text="Delete", method="delete", confirm="Are you sure?", class="btn btn-sm btn-danger")##
                    </td>
                </tr>
            </cfloop>
        </tbody>
    </table>
    
    <!--- Pagination --->
    <cfif @PLURAL_LOWER_NAME@.totalPages GT 1>
        <div class="pagination">
            ##paginationLinks(@PLURAL_LOWER_NAME@)##
        </div>
    </cfif>
<cfelse>
    <div class="empty-state">
        <p>No @PLURAL_LOWER_NAME@ found.</p>
        <p>##linkTo(route="new@SINGULAR_NAME@", text="Create your first @SINGULAR_NAME@", class="btn btn-primary")##</p>
    </div>
</cfif>

</cfoutput>