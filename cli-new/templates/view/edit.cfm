<cfoutput>

##contentFor(title="Edit @SINGULAR_NAME@")##

<div class="page-header">
    <h1>Edit @SINGULAR_NAME@</h1>
</div>

##errorMessagesFor("@SINGULAR_LOWER_NAME@")##

##startFormTag(route="@SINGULAR_LOWER_NAME@", key=@SINGULAR_LOWER_NAME@.id, method="patch", class="form")##
    
    ##includePartial("form")##
    
    <div class="form-actions">
        ##submitTag("Update @SINGULAR_NAME@", class="btn btn-primary")##
        ##linkTo(route="@SINGULAR_LOWER_NAME@", key=@SINGULAR_LOWER_NAME@.id, text="Cancel", class="btn btn-default")##
    </div>
    
##endFormTag()##

</cfoutput>