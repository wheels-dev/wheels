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
    return this;
  }

  function run() 
  {
    // Initialize detail service
    var details = application.wirebox.getInstance("DetailOutputService@wheels-cli");
    
    arguments.directory = fileSystemUtil.resolvePath( 'app' );

    // Output detail header
    details.header("📦", "Snippet Generation");

    // Validate the provided directory
    if (!directoryExists(arguments.directory)) {
      details.error('[#arguments.directory#] can''t be found. Are you running this command from your application root?');
      return;
    }

    ensureSnippetTemplatesExist();

    details.create("app/snippets/");
    details.success("Snippets successfully generated!");
    
    var nextSteps = [];
    arrayAppend(nextSteps, "View your snippets in app/snippets/");
    arrayAppend(nextSteps, "Use these as templates for generating code");
    details.nextSteps(nextSteps);
  }

}
