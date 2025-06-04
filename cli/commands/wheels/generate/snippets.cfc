/**
 * Copies the template snippets to the application.
 */
component
  aliases="wheels g snippets"
  extends="../base"
{

  /**
   * Initialize the command
   */
  function init() {
    super.init();
    return this;
  }

  function run() 
  {
    // Initialize rails service
    var rails = application.wirebox.getInstance("RailsOutputService");
    
    arguments.directory = fileSystemUtil.resolvePath( 'app' );

    // Output Rails-style header
    rails.header("📦", "Snippet Generation");

    // Validate the provided directory
    if (!directoryExists(arguments.directory)) {
      rails.error('[#arguments.directory#] can''t be found. Are you running this command from your application root?');
      return;
    }

    ensureSnippetTemplatesExist();

    rails.create("app/snippets/");
    rails.success("Snippets successfully generated!");
    
    var nextSteps = [];
    arrayAppend(nextSteps, "View your snippets in app/snippets/");
    arrayAppend(nextSteps, "Use these as templates for generating code");
    rails.nextSteps(nextSteps);
  }

}
