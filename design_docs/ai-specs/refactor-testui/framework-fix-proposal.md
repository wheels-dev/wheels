# Wheels Framework Fix Proposal: renderText/renderWith Bug

## Problem Description

When using `renderText()` or `renderWith()` in a controller action, the framework still attempts to find and render a view file, resulting in a "ViewNotFound" error even though content has already been rendered.

## Root Cause

In `$callAction()` method (processing.cfc:147), the framework checks `$performedRenderOrRedirect()` but the automatic `renderView()` call still executes and throws an error when it can't find a view file.

## Proposed Fix

Implement two complementary solutions:

### Solution 1: Check Format and Content Type in $callAction

```cfscript
// In vendor/wheels/controller/processing.cfc around line 147
public void function $callAction(required string action) {
    if (Left(arguments.action, 1) == "$" || ListFindNoCase(application.wheels.protectedControllerMethods, arguments.action)) {
        Throw(
            type = "Wheels.ActionNotAllowed",
            message = "You are not allowed to execute the `#arguments.action#` method as an action.",
            extendedInfo = "Make sure your action does not have the same name as any of the built-in Wheels functions."
        );
    }
    if (StructKeyExists(this, arguments.action) && IsCustomFunction(this[arguments.action])) {
        $invoke(method = arguments.action);
    } else if (StructKeyExists(this, "onMissingMethod")) {
        local.invokeArgs = {};
        local.invokeArgs.missingMethodName = arguments.action;
        local.invokeArgs.missingMethodArguments = {};
        $invoke(method = "onMissingMethod", invokeArgs = local.invokeArgs);
    }
    if (!$performedRenderOrRedirect()) {
        // Check if we should skip automatic view rendering
        local.contentType = $requestContentType();
        local.acceptableFormats = $acceptableFormats(action = arguments.action);
        
        // Only attempt to render a view if:
        // 1. The content type is html OR
        // 2. The content type is in the acceptable formats AND a format-specific template exists
        local.shouldRenderView = true;
        
        if (local.contentType != "html") {
            // For non-HTML formats, check if we should skip view rendering
            if (!ListFindNoCase(local.acceptableFormats, local.contentType)) {
                // Format not acceptable for this action
                local.shouldRenderView = false;
            } else if (ListFindNoCase("json,xml", local.contentType)) {
                // JSON and XML can be auto-generated, so check if a template exists
                local.templateName = $generateRenderWithTemplatePath(
                    controller = variables.params.controller,
                    action = arguments.action,
                    template = "",
                    contentType = local.contentType
                );
                if (!$formatTemplatePathExists($name = local.templateName)) {
                    // No template exists and these formats can be auto-generated
                    local.shouldRenderView = false;
                }
            }
        }
        
        if (local.shouldRenderView) {
            try {
                renderView();
            } catch (any e) {
                local.file = $get("viewPath")
                & "/"
                & LCase(ListChangeDelims(variables.$class.name, '/', '.'))
                & "/"
                & LCase(arguments.action)
                & ".cfm";
                if (FileExists(ExpandPath(local.file))) {
                    Throw(object = e);
                } else {
                    // For non-HTML formats, provide a more helpful error message
                    if (local.contentType != "html") {
                        $throwErrorOrShow404Page(
                            type = "Wheels.ViewNotFound",
                            message = "No content was rendered for the `#arguments.action#` action in the `#variables.$class.name#` controller.",
                            extendedInfo = "For content type `#local.contentType#`, either: 1) Call a render function (renderText, renderWith, etc.) in your action, 2) Create a view template named `#LCase(arguments.action)#.#local.contentType#.cfm`, or 3) Use onlyProvides() to restrict acceptable formats."
                        );
                    } else {
                        $throwErrorOrShow404Page(
                            type = "Wheels.ViewNotFound",
                            message = "Could not find the view page for the `#arguments.action#` action in the `#variables.$class.name#` controller.",
                            extendedInfo = "Create a file named `#LCase(arguments.action)#.cfm` in the `app/views/#LCase(ListChangeDelims(variables.$class.name, '/', '.'))#` directory (create the directory as well if it doesn't already exist)."
                        );
                    }
                }
            }
        }
    }
}
```

### Solution 2: Enhance renderWith to Set Response

```cfscript
// In vendor/wheels/controller/rendering.cfc, enhance renderWith
public any function renderWith(
    required any data,
    string controller = variables.params.controller,
    string action = variables.params.action,
    string template = "",
    any layout,
    any cache = "",
    string returnAs = "",
    boolean hideDebugInformation = false,
    string status = $statusCode()
) {
    $args(name = "renderWith", args = arguments);
    local.contentType = $requestContentType();
    local.acceptableFormats = $acceptableFormats(action = arguments.action);

    // Default to html if the content type found is not acceptable.
    if (!ListFindNoCase(local.acceptableFormats, local.contentType)) {
        local.contentType = "html";
    }

    $setRequestStatusCode(arguments.status);

    if (local.contentType == "html") {
        // Call render page when we are just rendering html.
        StructDelete(arguments, "data");
        local.rv = renderView(argumentCollection = arguments);
    } else {
        local.templateName = $generateRenderWithTemplatePath(
            argumentCollection = arguments,
            contentType = local.contentType
        );
        local.templatePathExists = $formatTemplatePathExists($name = local.templateName);
        if (local.templatePathExists) {
            local.content = renderView(
                argumentCollection = arguments,
                template = local.templateName,
                returnAs = "string",
                layout = false,
                hideDebugInformation = true
            );
        }

        // Throw an error if we rendered a pdf template and we got here
        if (local.contentType == "pdf" && $get("showErrorInformation") && local.templatePathExists) {
            Throw(
                type = "Wheels.PdfRenderingError",
                message = "When rendering the a PDF file, don't specify the filename attribute. This will stream the PDF straight to the browser."
            );
        }

        // Throw an error if we do not have a template to render the content type that we do not have defaults for.
        if (
            !ListFindNoCase("json,xml", local.contentType)
            && !StructKeyExists(local, "content")
            && $get("showErrorInformation")
        ) {
            Throw(
                type = "Wheels.RenderingError",
                message = "To render the #local.contentType# content type, create the template `#local.templateName#.cfm` for the #arguments.controller# controller."
            );
        }

        // Set our header based on our mime type.
        local.formats = $get("formats");
        local.value = local.formats[local.contentType] & "; charset=utf-8";
        $header(name = "content-type", value = local.value, charset = "utf-8");

        // If we do not have the local.content variable and we are not rendering html then try to create it.
        if (!StructKeyExists(local, "content")) {
            switch (local.contentType) {
                case "json":
                    // ... existing JSON serialization code ...
                    local.content = SerializeJSON(arguments.data);
                    // ... rest of JSON handling ...
                    break;
                case "xml":
                    local.content = $toXml(arguments.data);
                    break;
            }
        }

        // If the developer passed in returnAs="string" then return the generated content to them.
        if (arguments.returnAs == "string") {
            local.rv = local.content;
        } else {
            // FIX: Ensure response is set when renderWith generates content
            if (StructKeyExists(local, "content")) {
                renderText(text = local.content, status = arguments.status);
            }
        }
    }
    if (StructKeyExists(local, "rv")) {
        return local.rv;
    }
}
```

## Benefits

1. **Solution 1** prevents unnecessary view lookups for non-HTML formats when using `provides()`/`onlyProvides()`
2. **Solution 2** ensures `renderWith()` properly sets the response when auto-generating content
3. Together, they provide a complete fix that respects the framework's content negotiation system
4. Backward compatible - existing code continues to work
5. Better error messages guide developers to the correct solution

## Testing

The fix should be tested with:
- API controllers using `renderText()` directly
- API controllers using `renderWith()` with data
- Controllers using `onlyProvides("json")`
- Mixed format controllers with both HTML and API actions
- Edge cases with custom format templates

## Alternative Workaround (Current)

Until the framework is patched, developers can work around this by calling `renderNothing()` after any `renderText()` call:

```cfscript
private function renderSuccess(any data = {}, numeric statusCode = 200) {
    // ... existing code ...
    renderText(SerializeJSON(response));
    
    // Workaround for Wheels bug
    renderNothing();
}
```