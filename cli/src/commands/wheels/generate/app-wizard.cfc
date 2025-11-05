/**
 * Creates a new Wheels application using our wizard to gather all the
 * necessary information. This is the recommended route to start a new application.
 *
 * This command will ask for:
 *
 *  - An Application Name (a new directory will be created with this name)
 *  - Template to use
 *  - A reload Password
 *  - A datasource name
 *  - What local cfengine you want to run
 *  - Database and dependencies configuration - only if skipInstall=false:
 *    - If using Lucee, do you want to setup a local H2 dev database
 *    - Bootstrap and other dependencies
 *  - Do you want to initialize the app as a ForgeBox object
 *
 * {code:bash}
 * wheels new
 * {code}
 *
 * {code:bash}
 * wheels g app-wizard
 * {code}
 *
 * {code:bash}
 * wheels generate app-wizard
 * {code}
 *
 * All these three commands call the same wizard.
 *
 **/
component aliases="wheels g app-wizard, wheels new" extends="../base" {

  /**
   * Initialize the command
   */
  function init() {
    super.init();
    return this;
  }

  /**
   * @name           The name of the app you want to create
   * @template       The name of the app template to generate (or an endpoint ID like a forgebox slug)
   * @directory      The directory to create the app in
   * @reloadPassword The reload password to set for the app
   * @datasourceName The datasource name to set for the app
   * @cfmlEngine     The CFML engine to use for the app
   * @useBootstrap   Add Bootstrap to the app
   * @setupH2        Setup the H2 database for development
   * @init           "init" the directory as a package if it isn't already
   * @force          Force installation into an none empty directory
   * @nonInteractive Run without prompts, using provided options or defaults
   * @expert         Show advanced options and configurations
   * @skipInstall    Skip dependency installation after app creation
   **/
  function run(
    string name = '',
    string template = '',
    string directory = '',
    string reloadPassword = '',
    string datasourceName = '',
    string cfmlEngine = '',
    boolean useBootstrap = false,
    boolean setupH2 = true,
    boolean init = false,
    boolean force = false,
    boolean nonInteractive = false,
    boolean expert = false,
    boolean skipInstall = false
   ) {
    // Reconstruct arguments for handling --prefixed options
    arguments = reconstructArgs(argStruct=arguments);

    // Initialize detail service
    var details = application.wirebox.getInstance("DetailOutputService@wheels-cli");

    var appContent      = fileRead( getTemplate( '/ConfigAppContent.txt' ) );
    var routesContent   = fileRead( getTemplate( '/ConfigRoutes.txt' ) );

    // If non-interactive mode, use defaults for missing values
    if (arguments.nonInteractive) {
      if (!len(arguments.name)) arguments.name = 'MyWheelsApp';
      if (!len(arguments.template)) arguments.template = 'wheels-base-template@BE';
      if (!len(arguments.reloadPassword)) arguments.reloadPassword = 'changeMe';
      if (!len(arguments.datasourceName)) arguments.datasourceName = arguments.name;
      if (!len(arguments.cfmlEngine)) arguments.cfmlEngine = 'lucee';
      if (!len(arguments.directory)) arguments.directory = getCWD() & arguments.name;

      // Skip all prompts and proceed directly
      command( 'wheels g app' ).params(
        name            = arguments.name,
        template        = arguments.template,
        directory       = arguments.directory,
        reloadPassword  = arguments.reloadPassword,
        datasourceName  = arguments.datasourceName,
        cfmlEngine      = arguments.cfmlEngine,
        useBootstrap    = arguments.useBootstrap,
        setupH2         = arguments.setupH2,
        init            = arguments.init,
        force           = arguments.force,
        skipInstall     = arguments.skipInstall,
        initWizard      = true
      ).run();
      return;
    }

    // ---------------- Welcome
    details.header("", "Wheels Application Wizard");
    print.line()
      .cyanLine( "Welcome to the Wheels app wizard!" )
      .cyanLine( "I'll help you create a new Wheels application." )
      .line();

    // ---------------- Set an app Name
    print.yellowBoldLine( "Step 1: Application Name" )
      .line()
      .text( "Enter a name for your application. " )
      .line( "A new directory will be created with this name." )
      .line()
      .cyanLine( "Note: Names can only contain letters, numbers, underscores, and hyphens." )
      .line();

    var validAppName = false;
    var appName = "";

    while (!validAppName) {
      appName = ask( message = 'Please enter a name for your application: ', defaultResponse = 'MyWheelsApp' );
      appName = helpers.stripSpecialChars( appName );

      // Validate app name
      if (len(trim(appName)) == 0) {
        print.redLine("Application name cannot be empty. Please try again.");
      } else if (!reFindNoCase("^[a-zA-Z][a-zA-Z0-9_-]*$", appName)) {
        print.redLine("Application name must start with a letter and contain only letters, numbers, underscores, and hyphens.");
      } else if (len(appName) > 50) {
        print.redLine("Application name is too long. Please use 50 characters or less.");
      } else {
        // Check for reserved names
        var reservedNames = ["con", "prn", "aux", "nul", "com1", "com2", "com3", "com4", "lpt1", "lpt2", "lpt3", "wheels", "commandbox", "cfml"];
        if (arrayFindNoCase(reservedNames, appName)) {
          print.redLine("'#appName#' is a reserved name. Please choose a different name.");
        } else {
          validAppName = true;
        }
      }
    }

    print.line().toConsole();

    // ---------------- Template
    print.yellowBoldLine( "Step 2: Choose a Template" )
      .line()
      .text( "Select a template to use as the starting point for your application." )
      .line();

    var template = multiselect( 'Which Wheels Template shall we use? ' )
      .options( [
        {value: 'wheels-base-template@^3.0.0-rc.1', display: '3.0.0-rc - Wheels Base Template - Release Candidate', selected: true},
        {value: 'cfwheels-base-template', display: '2.5.x - Wheels Base Template - Stable Release'},
        {value: 'cfwheels-template-htmx-alpine-simple', display: 'Wheels Template - HTMX - Alpine.js - Simple.css'},
        {value: 'wheels-starter-app', display: 'Wheels Starter App'},
        {value: 'cfwheels-todomvc-htmx', display: 'Wheels - TodoMVC - HTMX - Demo App'},
        {value: 'custom', display: 'Enter a custom template endpoint'}
      ] )
      .required()
      .ask();

    if ( template == 'custom' ) {
      template = ask( message = 'Please enter a custom endpoint to use for the template: ' );
    }
    print.line().toConsole();

    // ---------------- Set reload Password
    print.yellowBoldLine( "Step 3: Reload Password" )
      .line()
      .text( "Set a reload password to secure your app. " )
      .line( "This allows you to restart your app via URL." )
      .line();

    var reloadPassword = ask(
      message         = 'Please enter a ''reload'' password for your application: ',
      defaultResponse = 'changeMe'
    );
    print.line();

    // ---------------- Set datasource Name
    print.yellowBoldLine( "Step 4: Database Configuration" )
      .line()
      .text( "Enter a datasource name for your database. " )
      .line( "You'll need to configure this in your CFML server admin." )
      .line()
      .cyanLine( "Tip: If using Lucee, we can auto-create an H2 database for development." )
      .line();

    var datasourceName = ask(
      message         = 'Please enter a datasource name if different from #appName#: ',
      defaultResponse = '#appName#'
    );

    if ( !len( datasourceName ) ) {
      datasourceName = appName;
    }
    print.line();

    // ---------------- Set default server.json engine
    print.yellowBoldLine( "Step 5: CFML Engine" )
      .line()
      .text( "Select the CFML engine for your application." )
      .line();

    var cfmlEngine = multiselect( 'Please select your preferred CFML engine? ' )
      .options( [
        {value: 'lucee', display: 'Lucee (Latest)', selected: true},
        {value: 'adobe', display: 'Adobe ColdFusion (Latest)'},
        {value: 'boxlang', display: 'BoxLang (Latest)'},
        {value: 'lucee@6', display: 'Lucee 6.x'},
        {value: 'lucee@5', display: 'Lucee 5.x'},
        {value: 'adobe@2023', display: 'Adobe ColdFusion 2023'},
        {value: 'adobe@2021', display: 'Adobe ColdFusion 2021'},
        {value: 'adobe@2018', display: 'Adobe ColdFusion 2018'},
        {value: 'custom', display: 'Enter a custom engine endpoint'}
      ] )
      .required()
      .ask();

    if ( cfmlEngine == 'custom' ) {
      cfmlEngine = ask( message = 'Please enter a custom endpoint to use for the CFML engine: ' );
    }

    var allowH2Creation = false;
    if ( listFirst( cfmlEngine, '@' ) == 'lucee' ) {
      allowH2Creation = true;
    }

    // ---------------- Test H2 Database? (only ask if not skipping installations)
    var createH2Embedded = false;
    if ( allowH2Creation && !arguments.skipInstall ) {
      print.line();
      print.Line( 'As you are using Lucee, would you like to setup and use the' ).toConsole();
      createH2Embedded = confirm( 'H2 Java embedded SQL database for development? [y,n]' );
    }

    //---------------- Ask about dependencies only if we're not skipping installation
    var useBootstrap = false;
    if (!arguments.skipInstall) {
      print.line();
      print.greenBoldLine( "========= Dependencies ======================" ).toConsole();
      print.line( "Configure dependencies and plugins for your application." ).toConsole();

      if(confirm("Would you like us to setup some default Bootstrap settings? [y/n]")){
        useBootstrap = true;
      }
    } else {
      print.line();
      print.cyanLine( "========= Dependencies Skipped ================" ).toConsole();
      print.line( "Dependency installation is disabled (skipInstall=true)." ).toConsole();
      print.line( "Dependencies like Bootstrap and H2 database will not be configured or installed." ).toConsole();
    }

    // ---------------- Initialize as a package
    print.line();
    print.line( 'Finally, shall we initialize your application as a package' ).toConsole();
    var initPackage = confirm( 'by creating a box.json file? [y,n]' );

    // ---------------- Expert Mode Options
    var serverPort = 8080;
    var jvmSettings = "";
    var customEnvConfigs = false;
    var advancedRouting = false;
    var customPluginRepos = "";
    var buildToolIntegration = "";

    if (arguments.expert) {
      print.line();
      print.yellowBoldLine( "Expert Mode: Advanced Configuration" )
        .line()
        .text( "Configure advanced options for your application." )
        .line();

      // Custom server port
      serverPort = ask(
        message         = 'Custom server port (leave empty for default 8080): ',
        defaultResponse = '8080'
      );
      if (!isNumeric(serverPort)) {
        serverPort = 8080;
      }

      // JVM Settings
      jvmSettings = ask(
        message         = 'Custom JVM settings (e.g. -Xmx512m -Xms256m): ',
        defaultResponse = ''
      );

      // Environment-specific configurations
      print.line();
      customEnvConfigs = confirm( 'Setup custom environment configurations (dev, staging, production)? [y,n]' );

      // Advanced routing options
      print.line();
      advancedRouting = confirm( 'Enable advanced routing features (nested resources, constraints)? [y,n]' );

      // Custom plugin repositories
      customPluginRepos = ask(
        message         = 'Custom plugin repositories (comma-separated URLs): ',
        defaultResponse = ''
      );

      // Build tool integration
      if (len(customPluginRepos)) {
        print.line();
        buildToolIntegration = multiselect( 'Build tool integration? ' )
          .options( [
            {value: 'none', display: 'None', selected: true},
            {value: 'ant', display: 'Apache Ant'},
            {value: 'gradle', display: 'Gradle'},
            {value: 'maven', display: 'Maven'},
            {value: 'npm', display: 'NPM Scripts'}
          ] )
          .ask();
      }

      print.line();
    }

    print.line();
    print.line();
		print.greenBoldLine( "+-----------------------------------------------------------------------------------+" )
         .greenBoldLine( '| Great! Think we''re all good to go. We''re going to create a Wheels application for |' )
         .greenBoldLine( '| you with the following parameters.                                                |' )
         .greenBoldLine( "+-----------------------+-----------------------------------------------------------+" )
         .greenBoldLine( '| Template              | #ljustify(template,57)# |' )
         .greenBoldLine( '| Application Name      | #ljustify(appName,57)# |' )
         .greenBoldLine( '| Install Directory     | #ljustify(getCWD() & appName,57)# |' )
         .greenBoldLine( '| Reload Password       | #ljustify(reloadPassword,57)# |' )
         .greenBoldLine( '| Datasource Name       | #ljustify(datasourceName,57)# |' )
         .greenBoldLine( '| CF Engine             | #ljustify(cfmlEngine,57)# |' )
         .greenBoldLine( '| Initialize as Package | #ljustify(initPackage,57)# |' )
         .greenBoldLine( '| Force Installation    | #ljustify(force,57)# |' )
         .greenBoldLine( '| Skip Dependency Install | #ljustify(arguments.skipInstall,57)# |' );

    // Only show dependency settings if dependencies will be installed
    if (!arguments.skipInstall) {
      if (allowH2Creation) {
        print.greenBoldLine( '| Setup H2 Database     | #ljustify(createH2Embedded,57)# |' );
      }
      print.greenBoldLine( '| Setup Bootstrap       | #ljustify(useBootstrap,57)# |' );
    }

    // Show expert mode options if enabled
    if (arguments.expert) {
      print.greenBoldLine( '| Expert Mode           | #ljustify("Enabled",57)# |' )
           .greenBoldLine( '| Server Port           | #ljustify(serverPort,57)# |' );

      if (len(jvmSettings)) {
        print.greenBoldLine( '| JVM Settings          | #ljustify(left(jvmSettings, 57),57)# |' );
      }

      print.greenBoldLine( '| Custom Env Configs    | #ljustify(customEnvConfigs,57)# |' )
           .greenBoldLine( '| Advanced Routing      | #ljustify(advancedRouting,57)# |' );

      if (len(customPluginRepos)) {
        print.greenBoldLine( '| Plugin Repositories   | #ljustify(left(customPluginRepos, 57),57)# |' );
      }

      if (len(buildToolIntegration) && buildToolIntegration != "none") {
        print.greenBoldLine( '| Build Tool            | #ljustify(buildToolIntegration,57)# |' );
      }
    }

    print.greenBoldLine( "+-----------------------+-----------------------------------------------------------+" )
         .toConsole();

    print.line();


    if ( confirm( 'Sound good? [y/n]' ) ) {
      // call wheels g app

      command( 'wheels g app' ).params(
        name            = '#appName#',
        template        = '#template#',
        directory       = '#getCWD()##appName#',
        reloadPassword  = '#reloadPassword#',
        datasourceName  = '#datasourceName#',
        cfmlEngine      = '#cfmlEngine#',
        useBootstrap    = #useBootstrap#,
        setupH2         = #createH2Embedded#,
        init            = #initPackage#,
        force           = #force#,
        skipInstall     = #arguments.skipInstall#,
        initWizard      = true).run();

    } else {
      details.skip( "Application creation cancelled by user" );
    }

  }

}
