/**
 *  Create a blank Wheels app from one of our app templates or a template using a valid Endpoint ID which can come from .
 *  ForgeBox, HTTP/S, git, github, etc.
 *  By default an app named MyWheelsApp will be created in a sub directoryt call MyWheelsApp.
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
 *  or simply
 *  {code:bash}
 *  wheels new
 *  {code}
 *
 *  Here are the basic templates that are available for you that come from ForgeBox
 *  - Wheels Base Template - Bleeding Edge (default)
 *  - Wheels Base Template - Stable
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
      'Base'        : 'cfwheels-base-template',
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
    name     = 'MyWheelsApp',
    template = 'wheels-base-template@BE',
    directory,
    reloadPassword = 'changeMe',
    datasourceName,
    cfmlEngine      = 'lucee',
    boolean useBootstrap = false,
    boolean setupH2 = false,
    boolean init    = false,
    boolean force   = false
  ) {
    // set defaults based on app name
    if ( !len( arguments.directory ) ) {
      arguments.directory = '#getCWD()##arguments.name#';
    }
    if ( !len( arguments.datasourceName ) ) {
      arguments.datasourceName = '#arguments.name#';
    }

    // This will make the directory canonical and absolute
    arguments.directory = resolvePath( arguments.directory );

    // Validate directory, if it doesn't exist, create it.
    if ( !directoryExists( arguments.directory ) ) {
      print.greenBoldLine( 'Creating the target directory...' ).toConsole();
      directoryCreate( arguments.directory );
    } else {
      if ( arrayLen( directoryList( arguments.directory, false ) ) && !force) {
        print.greenBoldLine( 'The target directory is not empty. The installation cannot continue. Use --force to force the installation into a none empty directory.' ).toConsole();
        return;
      }
    }

    print.greenBoldLine( 'Currently working in #getCWD()#');

    // If the template is one of our "shortcut" names
    if ( variables.templateMap.keyExists( arguments.template ) ) {
      // Replace it with the actual ForgeBox slug name.
      arguments.template = variables.templateMap[arguments.template];
    }

    // Install the template
    print.greenBoldLine( 'Installing the application template...' ).toConsole();
    packageService.installPackage(
      ID                      = arguments.template,
      directory               = arguments.directory,
      save                    = false,
      saveDev                 = false,
      production              = false,
      currentWorkingDirectory = arguments.directory
    );

    print.greenBoldline( 'Navigating to new application...#arguments.directory#' ).toConsole();
    command( 'cd "#arguments.directory#"' ).run();

    // Setting Application Name
    print.greenBoldLine( 'Setting application name...' ).toConsole();
    command( 'tokenReplace' ).params( path = 'app/config/app.cfm', token = '|appName|', replacement = arguments.name ).run();
    command( 'tokenReplace' ).params( path = 'server.json', token = '|appName|', replacement = arguments.name ).run();

    // Setting Reload Password
    print.greenBoldLine( 'Setting reload password...' ).toConsole();
    command( 'tokenReplace' )
      .params( path = 'app/config/settings.cfm', token = '|reloadPassword|', replacement = arguments.reloadPassword )
      .run();

    // Setting Datasource Name
    print.greenBoldLine( 'Setting datasource name...' ).toConsole();
    command( 'tokenReplace' )
      .params( path = 'app/config/settings.cfm', token = '|datasourceName|', replacement = arguments.datasourceName )
      .run();

    // Setting cfml Engine Name
    print.greenBoldLine( 'Setting CFML Engine name...' ).toConsole();
    command( 'tokenReplace' )
      .params( path = 'server.json', token = '|cfmlEngine|', replacement = arguments.cfmlEngine )
      .run();


    // Create h2 embedded db by adding an application.cfc level datasource
    if ( arguments.setupH2 ) {
      print.greenline( 'Creating Development H2 Database...' ).toConsole();
      var datadirectory = fileSystemUtil.resolvePath( 'db/h2/' );
      print.greenline( '...Finished Creating Development H2 Database.' ).toConsole();

      if ( !directoryExists( datadirectory ) ) {
        print.greenline( 'Creating #arguments.directory# path...' ).toConsole();
        directoryCreate( datadirectory );
        print.greenline( '...Finished Creating #arguments.directory# path.' ).toConsole();
      }

      print.greenline( 'Adding Datasource to app.cfm...' ).toConsole();
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
      print.yellowline( datasourceConfig ).toConsole();
      command( 'tokenReplace' )
        .params( path = 'app/config/app.cfm', token = '// CLI-Appends-Here', replacement = datasourceConfig )
        .run();
        print.greenline( '...Finished Adding Datasource to app.cfm.' ).toConsole();

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
      print.greenline( "========= Installing Bootstrap Settings").toConsole();
      
      // Replace Default Template with something more sensible
      var bsLayout=fileRead( getTemplate('/bootstrap/layout.cfm' ) );
      bsLayout = replaceNoCase( bsLayout, "|appName|", arguments.name, 'all' );
      file action='write' file='#fileSystemUtil.resolvePath("app/views/layout.cfm")#' mode ='777' output='#trim(bsLayout)#';
      
      // Add Bootstrap default form settings
      var bsSettings=fileRead( getTemplate('/bootstrap/settings.cfm' ) );
      bsSettings = bsSettings & cr & '// CLI-Appends-Here';
      command( 'tokenReplace' )
        .params( path = 'app/config/settings.cfm', token = '// CLI-Appends-Here', replacement = bsSettings )
        .run();
      print.greenline( '...Finished Adding Bootstrap to app.cfm.' ).toConsole();

      // New Flashwrapper Plugin needed - install it via Forgebox
      command( 'install cfwheels-flashmessages-bootstrap' ).run();
      print.line();

      }

    }
     
      print.line()
    print.greenBoldLine( '========= All Done! =============================' )
      .greenBoldLine( '| Your app has been successfully created. Type   |' )
      .greenBoldLine( '| ''start'' to start a server here.                |' )
      .greenBoldLine( '|                                                |' );
    if ( arguments.setupH2 ) {
       print.greenBoldLine( '| Since you opted to install the H2 Database we    |' )
            .greenBoldLine( '| need to installed the extension into the         | ')
            .greenBoldLine( '| Lucee server. The easiest way to do this is      | ')
            .greenBoldLine( '| to start your Lucee server by typing ''start'',    | ')
            .greenBoldLine( '| wait for the server to start up. Once it is      |' )
            .greenBoldLine( '| running type ''install''. This will install        |' )
            .greenBoldLine( '| the dependencies into your Lucee server. Then    |' )
            .greenBoldLine( '| ''restart'' your server. This process can take     |' )
            .greenBoldLine( '| up to a minute to complete. We''l attempt to run  |' )
            .greenBoldLine( '| that for you now. Please wait till the script    |' )
            .greenBoldLine( '| has finished running.                            |' );
      command( 'start && install && restart' ).run();
    } else {
      print.greenBoldLine( '| Don''t forget to add your datasource to either  |' )
        .greenBoldLine( '| /lucee/admin/server.cfm OR                     |' )
        .greenBoldLine( '| /CFIDE/administrator/index.cfm                 |' )
        .greenBoldLine( '|                                                |' );
    }
    print.greenBoldLine( '| Once you''ve started a local server, we can     |' )
      .greenBoldLine( '| continue building out the app.                 |' )
      .greenBoldLine( '==================================================' )
      .line();
  }

  /**
   * Returns an array of cfwheels templates available
   */
  function templateComplete( ) {
    return variables.templateMap.keyList().listToArray();
  }

}
