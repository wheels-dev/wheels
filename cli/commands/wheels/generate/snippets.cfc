/**
 * Copies the template snippets to the application.
 */
component
  aliases="wheels g snippets"
  extends="../base"
{

  function run() 
  {
    arguments.directory = fileSystemUtil.resolvePath( 'app' );

    print.line('Starting snippet generation...').toConsole();

    // Validate the provided directory
    if (!directoryExists(arguments.directory)) {
      error('[#arguments.directory#] can''t be found. Are you running this command from your application root?');
    }

    ensureSnippetTemplatesExist();

    print.line('Snippet successfully generated in the /app/snippets folder.');
  }

}
