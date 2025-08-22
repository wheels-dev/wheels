<cfscript>
    // Place helper functions here that should be available for use in all view pages of your application.
    /**
     * Renders a tick or cross depending on boolean value via font awesome
    *
    * [section: Application]
    * [category: View Helpers]
    *
    * @boolean The boolean
    */
    public string function tickorcross(required boolean boolean){
        if(structKeyexists(arguments, "boolean") && isBoolean(arguments.boolean) && arguments.boolean){
        return "<i class='fa fa-check text-success'></i>";
        } else {
        return "<i class='fa fa-times text-danger'></i>";
        }
    }

    /**
    * Shortcut to encodeForHTML, because I'm lazy
    *
    * [section: Application]
    * [category: View Helpers]
    *
    * @string The string to encode
    */
    string function e(string string="") {
        return encodeForHTML(arguments.string);
    }

    /**
    * A Default Date Formatter
    *
    * [section: Application]
    * [category: View Helpers]
    *
    * @date The date to Format
    */
    string function formatDate(any date) {
        if(!isDate(arguments.date)){
            return "Unknown";
        } else {
            return dateFormat(arguments.date, "dd mmm yyyy") & " " & timeformat(arguments.date, "HH:MM");
        }
    }

    /**
    * Renders a bootstrap Card
    *
    * [section: Application]
    * [category: View Helpers]
    *
    * @header Card Header
    * @title Card Title
    * @text Main text
    * @style Additional CSS
    * @footer Footer Text
    * @close boolean true/false
    */
    string function card(required string header, string title="", string text="", string class="", string style="", string footer="", boolean close=false) {
        savecontent variable="local.rv" {
        writeOutput('<div class="card ' & arguments.class & '" style="' & arguments.style & '">');
        writeOutput('<div class="card-header">' & e(arguments.header) & '</div>');
        writeOutput('<div class="card-body">');
            if(len(arguments.title)){
            writeOutput('<h5 class="card-title">' & e(arguments.title) & '</h5>');
            }
            if(len(arguments.text)){
            writeOutput(' <p class="card-text">' & e(arguments.text) & '</p>');
            }
            writeOutput("</div>");
            if(len(arguments.footer)){
            writeOutput('<div class="card-footer">' & arguments.footer & '</div>');
            }
            if(arguments.close){
            writeOutput('</div>');
            }
        }
        return local.rv;
    }

    /**
    * Ends a bootstrap Card: use if not self closing
    *
    * [section: Application]
    * [category: View Helpers]
    */
    string function cardEnd(){
        writeOutput('</div></div>');
    }

    /**
    * Renders a bootstrap Card/Panel but with custom contents
    *
    * [section: Application]
    * [category: View Helpers]
    *
    * @title Card Title
    * @class CSS Class
    * @style Additional CSS
    * @btn optional btn
    */
    string function panel(string title="", string class="", string style="", string btn=""){
    savecontent variable="local.rv" {
        writeOutput('<div class="card ' & arguments.class & '" style="' & arguments.style & '">');
        writeOutput('<div class="card-header">' & e(arguments.title) );
        if(len(arguments.btn)){
            writeOutput('<span class="float-end">' & arguments.btn & '</span>');
        }
        writeOutput('</div><div class="card-body">');
        }
    return local.rv;
    }

    /**
    * Ends a panel
    *
    * [section: Application]
    * [category: View Helpers]
    */
    string function panelEnd(){
        writeOutput('</div></div>');

    }

    /**
    * Default Page Header: allows passing in some custom contents to float right
    *
    * [section: Application]
    * [category: View Helpers]
    *
    * @title Title Text
    * @btn BTN contents
    */
    string function pageHeader(string title="", string btn=""){
    writeOutput('<h1 class="fw-light">' & e(arguments.title));
    if(len(arguments.btn)){
        writeOutput('<span class="float-end">' & arguments.btn & '</span>');
    }
    writeOutput('</h1><hr />');
    }

    /**
    * Log File Badges: give me a type and match it up to a bootstrap badge
    *
    * [section: Application]
    * [category: View Helpers]
    *
    * @type Log file type string
    */
    string function logFileBadge(string type="", string severity="light"){
    switch(arguments.severity) {
        // Match bootstrap classes immediately
        case "info": case "success": case "danger": case "warning":
            local.badgeClass = arguments.severity;
            break;
        // Make error the same as danger
        case "error":
            local.badgeClass = "danger";
            break;
        // Default everything else
        default:
        local.badgeClass = "light";
            break;
    }
    return "<span class='badge rounded-pill text-bg-#local.badgeClass#'>" & e(arguments.type) & "</span>";
    }
    /**
    * Renders a Gravatar from gravatar.com
    *
    * [section: Application]
    * [category: View Helpers]
    *
    * @email Email of user
    * @size px size of image
    * @rating Limit to rating
    * @class Image Class, defaults to bootstrap 4 rounded image
    */
    string function gravatar(string email, numeric size=80, string rating="pg", class="rounded-circle mx-auto d-block"){
    if(len(arguments.email)){
        local.email = lcase(hash(trim(arguments.email)));
        return "<img src='https://www.gravatar.com/avatar/#local.email#?s=#arguments.size#&amp;r=#rating#' class='#arguments.class#', alt='Users Gravatar' border='0' />";
    }
    }
</cfscript>
