/**
 *  Create a blank Wheels app from one of our app templates or a template using a valid Endpoint ID which can come from .
 *  ForgeBox, HTTP/S, git, github, etc.
 *  By default an app named MyWheelsApp will be created in a sub directory call MyWheelsApp.
 *
 *  The most basic call...
 *  {code:bash}
 *  wheels generate app
 *  {code}
 *
 *  This can be shortened to...
 *  {code:bash}
 *  wheels g app
 *  {code}
 *
 *  Here are the basic templates that are available for you that come from ForgeBox
 *  - Wheels Base Template - 3.0 Bleeding Edge (default)
 *  - CFWheels Base Template - 2.5 Stable
 *  - Wheels Template - HelloWorld
 *  - Wheels Template - HelloDynamic
 *  - Wheels Template - HelloPages
 *  - Wheels Example App
 *  - Wheels - TodoMVC - HTMX - Demo App
 *
 * {code:bash}
 * wheels create app template=base
 * {code}
 * .
 * The template parameter can also be any valid Endpoint ID, which includes a Git repo or HTTP URL pointing to a package.
 * .
 * {code:bash}
 * wheels create app template=http://site.com/myCustomAppTemplate.zip
 * {code}
 *
 **/
component aliases="wheels g app" extends="../base" {

  /**
   * Constructor
   */
  function init( ) {
    // Map these shortcut names to the actual ForgeBox slugs
    variables.templateMap = {
      'Base'        : 'wheels-base-template@BE',
      'Base@BE'     : 'wheels-base-template@BE',
      'HelloWorld'  : 'cfwheels-template-helloworld',
      'HelloDynamic': 'cfwheels-template-hellodynamic',
      'HelloPages'  : 'cfwheels-template-hellopages'
    };

    return this;
  }

  /**
   * @name           The name of the app you want to create
   * @template       The name of the app template to generate (or an endpoint ID like a forgebox slug). Default is Base@BE (Bleeding Edge)
   * @directory      The directory to create the app in
   * @reloadPassword The reload passwrod to set for the app
   * @datasourceName The datasource name to set for the app
   * @cfmlEngine     The CFML engine to use for the app
   * @useBootstrap   Add Bootstrap to the app
   * @setupH2        Setup the H2 database for development
   * @init           "init" the directory as a package if it isn't already
   * @force          Force installation into an none empty directory
   **/
  function run(
    name     = 'MyApp',
    template = 'wheels-base-template@BE',
    directory,
    reloadPassword = '',
    datasourceName,
    cfmlEngine      = 'lucee',
    boolean useBootstrap = false,
    boolean setupH2 = true,
    boolean init    = false,
    boolean force   = false
  ) {
    // Initialize detail service
    var details = application.wirebox.getInstance("DetailOutputService@wheels-cli");

    // set defaults based on app name
    if ( !len( arguments.directory ) ) {
      arguments.directory = '#getCWD()##arguments.name#';
    }
    if ( !len( arguments.datasourceName ) ) {
      arguments.datasourceName = '#arguments.name#';
    }

    // This will make the directory canonical and absolute
    arguments.directory = resolvePath( arguments.directory );

    // Output detail header
    details.header("🚀", "Creating new Wheels application: #arguments.name#");

    // Validate directory, if it doesn't exist, create it.
    if ( !directoryExists( arguments.directory ) ) {
      directoryCreate( arguments.directory );
      details.create(arguments.directory);
    } else {
      if ( arrayLen( directoryList( arguments.directory, false ) ) && !force) {
        details.error( 'The target directory is not empty. Use force=true to force the installation into a none empty directory.' );
        return;
      }
      details.identical(arguments.directory);
    }


    // If the template is one of our "shortcut" names
    if ( variables.templateMap.keyExists( arguments.template ) ) {
      // Replace it with the actual ForgeBox slug name.
      arguments.template = variables.templateMap[arguments.template];
    }

    // Install the template
    details.line();
    details.getPrint().yellowLine( "📦 Installing application template: #arguments.template#" );
    packageService.installPackage(
      ID                      = arguments.template,
      directory               = arguments.directory,
      save                    = false,
      saveDev                 = false,
      production              = false,
			verbose								  = true,
      currentWorkingDirectory = arguments.directory
    );

    command( 'cd "#arguments.directory#"' ).run();

    // Setting Application Name
    details.line();
    details.getPrint().yellowLine( "🔧 Configuring application..." );
    command( 'tokenReplace' ).params( path = 'app/config/app.cfm', token = '|appName|', replacement = arguments.name ).run();
    details.update("app/config/app.cfm", true);
    command( 'tokenReplace' ).params( path = 'server.json', token = '|appName|', replacement = arguments.name ).run();
    details.update("server.json", true);

    // Setting Reload Password
    command( 'tokenReplace' )
      .params( path = 'app/config/settings.cfm', token = '|reloadPassword|', replacement = arguments.reloadPassword )
      .run();
    details.update("app/config/settings.cfm (reload password)", true);

    // Setting Datasource Name
    command( 'tokenReplace' )
      .params( path = 'app/config/settings.cfm', token = '|datasourceName|', replacement = arguments.datasourceName )
      .run();
    details.update("app/config/settings.cfm (datasource)", true);

    // Setting cfml Engine Name
    command( 'tokenReplace' )
      .params( path = 'server.json', token = '|cfmlEngine|', replacement = arguments.cfmlEngine )
      .run();
    details.update("server.json (CFML engine)", true);


    // Create h2 embedded db by adding an application.cfc level datasource
    if ( arguments.setupH2 ) {
      details.line();
      details.getPrint().yellowLine( "🗝️ Database Configuration" );
      var datadirectory = fileSystemUtil.resolvePath( 'db/h2/' );

      if ( !directoryExists( datadirectory ) ) {
        directoryCreate( datadirectory );
        details.create("db/h2/", true);
      } else {
        details.identical("db/h2/", true);
      }
      var datasourceConfig = 'this.datasources[''#arguments.datasourceName#''] = {
          class: ''org.h2.Driver''
        , connectionString: ''jdbc:h2:file:#datadirectory##arguments.datasourceName#;MODE=MySQL''
        , username = ''sa''
        };
        this.datasources[''wheelstestdb_h2''] = {
          class: ''org.h2.Driver''
        , connectionString: ''jdbc:h2:file:#datadirectory#wheelstestdb_h2;MODE=MySQL''
        , username = ''sa''
        };
        // CLI-Appends-Here';
      command( 'tokenReplace' )
        .params( path = 'app/config/app.cfm', token = '// CLI-Appends-Here', replacement = datasourceConfig )
        .run();
      details.update("app/config/app.cfm (H2 datasource)", true);

    // Init, if not a package as a Box Package
    if ( arguments.init && !packageService.isPackage( arguments.directory ) ) {
      command( 'init' )
        .params(
          name   = arguments.name,
          slug   = replace( arguments.name, ' ', '', 'all' ),
          wizard = arguments.initWizard
        )
        .run();
    }

    // Prepare defaults on box.json so we remove template based ones
    command( 'package set' )
      .params(
        name     = arguments.name,
        slug     = variables.formatterUtil.slugify( arguments.name ),
        version  = '1.0.0',
        location = '',
        scripts  = '{}'
      )
      .run();

    // Remove the cfwheels-base from the dependencies
    command( 'tokenReplace' )
      .params( path = 'box.json', token = '"cfwheels-base":"^2.2",', replacement = '' )
      .run();

    // Remove the cfwheels-base from the install paths
    command( 'tokenReplace' )
      .params( path = 'box.json', token = '"cfwheels-base":"base/",', replacement = '' )
      .run();

    // Add the H2 Lucee extension to the dependencies
    command( 'package set' )
      .params( Dependencies = '{ "orgh213172lex":"lex:https://ext.lucee.org/org.h2-1.3.172.lex" }' )
      .flags( 'append' )
      .run();

    // Definitely refactor this into some sort of templating system?
    if(useBootstrap){
      details.line();
      details.getPrint().yellowLine( "🎨 Installing Bootstrap..." );

      // Replace Default Template with something more sensible
      var bsLayout=fileRead( getTemplate('/bootstrap/layout.cfm' ) );
      bsLayout = replaceNoCase( bsLayout, "|appName|", arguments.name, 'all' );
      file action='write' file='#fileSystemUtil.resolvePath("app/views/layout.cfm")#' mode ='777' output='#trim(bsLayout)#';
      details.update("app/views/layout.cfm", true);

      // Add Bootstrap default form settings
      var bsSettings=fileRead( getTemplate('/bootstrap/settings.cfm' ) );
      bsSettings = bsSettings & cr & '// CLI-Appends-Here';
      command( 'tokenReplace' )
        .params( path = 'app/config/settings.cfm', token = '// CLI-Appends-Here', replacement = bsSettings )
        .run();
      details.update("app/config/settings.cfm (Bootstrap settings)", true);

      // New Flashwrapper Plugin needed - install it via Forgebox
      command( 'install cfwheels-flashmessages-bootstrap' ).run();

      }

    }

    details.success("Application created successfully!");

    // Build next steps
    var nextSteps = [];
    arrayAppend(nextSteps, "cd #arguments.name#");

    if ( arguments.setupH2 ) {
      arrayAppend(nextSteps, "Start server and install H2 extension: start && install && restart");
      details.line();
      details.getPrint().yellowLine("🛠️ Installing H2 database extension...");
      command( 'start && install && restart' ).run();
    } else {
      arrayAppend(nextSteps, "Configure your datasource in Lucee/ACF admin");
      arrayAppend(nextSteps, "Start the server: server start");
    }

    arrayAppend(nextSteps, "Generate your first model: wheels generate model User");
    arrayAppend(nextSteps, "Generate a controller: wheels generate controller Users");

    details.nextSteps(nextSteps);
  }

  /**
   * Returns an array of cfwheels templates available
   */
  function templateComplete( ) {
    return variables.templateMap.keyList().listToArray();
  }

}
