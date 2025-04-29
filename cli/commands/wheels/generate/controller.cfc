/**
 * I generate a controller in /controllers/NAME.cfc
 * Actions are passed in as arguments:
 *
 * Create a user controller with full CRUD methods
 * {code:bash}
 * wheels generate controller user
 * {code}
 *
 * Create a user object with just "index" and "customaction" methods
 *
 * {code:bash}
 * wheels generate controller user index,customaction
 * {code}
 **/
component
  aliases="wheels g controller"
  extends="../base"
{

  /**
   * @name.hint       Name of the controller to create without the .cfc
   * @actionList.hint optional list of actions, comma delimited
   * @directory.hint  if for some reason you don't have your controllers in /controllers/
   **/
  function run(
    required string name,
    string actionList = '',
    directory         = 'app/controllers'
  ) {
    var obj             = helpers.getNameVariants( arguments.name );
    arguments.directory = fileSystemUtil.resolvePath( arguments.directory );

    print.line( 'Creating Controller...' ).toConsole();

    // Validate directory
    if ( !directoryExists( arguments.directory ) ) {
      error( '[#arguments.directory#] can''t be found. Are you running this from your site root?' );
    }

    // If custom actions passed in as arguments, then use them, otherwise use CRUD
    var actionContent = '';

    if ( len( arguments.actionList ) && arguments.actionList != 'CRUD' ) {
      var allactions        = '';
      var controllerContent = fileRead( getTemplate( '/ControllerContent.txt' ) );
      // Loop Over actions to generate them
      for ( var thisAction in listToArray( arguments.actionList ) ) {
        if ( thisAction == 'init' ) {
          continue;
        }
        allactions = allactions & $returnAction( thisAction );
        print.yellowLine( 'Generated Action: #thisAction#' );
      }
      actionContent = allactions;
    } else {
      //Copy template files to the application folder if they do not exist there
      ensureSnippetTemplatesExist();
      // Do Crud: overrwrite whole controllerContent with CRUD template
      controllerContent = fileRead(fileSystemUtil.resolvePath('app/snippets/CRUDContent.txt'));
      print.yellowLine( 'Generating CRUD' );
    }

    // Inject actions in controller content
    controllerContent = replaceNoCase(
      controllerContent,
      '|actions|',
      actionContent,
      'all'
    );
    // Replace Object tokens
    controllerContent = $replaceDefaultObjectNames( controllerContent, obj );

    var controllerName = obj.objectNamePluralC & '.cfc';
    var controllerPath = directory & '/' & controllerName;

    if ( fileExists( controllerPath ) ) {
      if ( confirm( '#controllerName# already exists in target directory. Do you want to overwrite? [y/n]' ) ) {
        print.greenLine( 'Ok, going to overwrite...' ).toConsole();
      } else {
        print.boldRedLine( 'Ok, aborting!' );
        return;
      }
    }
    file action="write" file="#controllerPath#" mode="777" output="#trim( controllerContent )#";
    print.line( 'Created #controllerName#' );
  }

}
