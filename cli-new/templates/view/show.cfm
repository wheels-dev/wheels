<cfoutput>

##contentFor(title="@SINGULAR_NAME@ Details")##

<div class="page-header">
    <h1>@SINGULAR_NAME@ Details</h1>
    <div class="actions">
        ##linkTo(route="edit@SINGULAR_NAME@", key=@SINGULAR_LOWER_NAME@.id, text="Edit", class="btn btn-primary")##
        ##linkTo(route="@PLURAL_LOWER_NAME@", text="Back to List", class="btn btn-default")##
    </div>
</div>

<div class="details">
@DETAIL_FIELDS@
    
    <div class="timestamps">
        <p><strong>Created:</strong> ##dateTimeFormat(@SINGULAR_LOWER_NAME@.createdAt, "mmm d, yyyy h:nn tt")##</p>
        <p><strong>Last Updated:</strong> ##dateTimeFormat(@SINGULAR_LOWER_NAME@.updatedAt, "mmm d, yyyy h:nn tt")##</p>
    </div>
</div>

<div class="form-actions">
    ##linkTo(route="edit@SINGULAR_NAME@", key=@SINGULAR_LOWER_NAME@.id, text="Edit @SINGULAR_NAME@", class="btn btn-primary")##
    ##linkTo(route="@SINGULAR_LOWER_NAME@", key=@SINGULAR_LOWER_NAME@.id, text="Delete @SINGULAR_NAME@", method="delete", confirm="Are you sure you want to delete this @SINGULAR_LOWER_NAME@?", class="btn btn-danger")##
</div>

</cfoutput>