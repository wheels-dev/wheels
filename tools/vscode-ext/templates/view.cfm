<cfparam name="${paramName}">
<cfoutput>

#contentFor("title", "${viewTitle}")#

<div class="container">
    <div class="row">
        <div class="col-md-12">
            <h1>${pageHeading}</h1>

            <div class="actions mb-3">
                ${actionLinks}
            </div>

            ${contentBlock}
        </div>
    </div>
</div>

</cfoutput>