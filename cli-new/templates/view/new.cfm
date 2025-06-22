<cfoutput>

##contentFor(title="New @SINGULAR_NAME@")##

<div class="page-header">
    <h1>New @SINGULAR_NAME@</h1>
</div>

##errorMessagesFor("@SINGULAR_LOWER_NAME@")##

##startFormTag(route="@PLURAL_LOWER_NAME@", method="post", class="form")##
    
    ##includePartial("form")##
    
    <div class="form-actions">
        ##submitTag("Create @SINGULAR_NAME@", class="btn btn-primary")##
        ##linkTo(route="@PLURAL_LOWER_NAME@", text="Cancel", class="btn btn-default")##
    </div>
    
##endFormTag()##

</cfoutput>