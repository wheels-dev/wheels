/**
 * Creates a new Wheels application using our wizard to gather all the
 * necessary information. This is the recommended route to start a new application.
 *
 * This command will ask for:
 *
 *  - An Application Name (a new directoery will be created with this name)
 *  - Template to use
 *  - A reload Password
 *  - A datasource name
 *  - What local cfengine you want to run
 *  - If using Lucee, do you want to setup a local h2 dev database
 *  - Do you want to initialize the app as a ForgBox opbject
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
component aliases="wheels g app-wizard" extends="../base" {

  /**
   * Initialize the command
   */
  function init() {
    super.init();
    return this;
  }

  /**
   * @force          Force installation into an none empty directory
   **/
  function run(
    boolean force   = false
   ) {
    // Initialize rails service
    var rails = application.wirebox.getInstance("RailsOutputService");
    
    var appContent      = fileRead( getTemplate( '/ConfigAppContent.txt' ) );
    var routesContent   = fileRead( getTemplate( '/ConfigRoutes.txt' ) );

    // ---------------- Welcome
    rails.header("🧿", "Wheels Application Wizard");
    print.line()
      .cyanLine( "Welcome to the Wheels app wizard!" )
      .cyanLine( "I'll help you create a new Wheels application." )
      .line();

    // ---------------- Set an app Name
    // TODO: Add conditions on what can in an application name
    print.yellowBoldLine( "📝 Step 1: Application Name" )
      .line()
      .text( "Enter a name for your application. " )
      .line( "A new directory will be created with this name." )
      .line();

    var appName = ask( message = 'Please enter a name for your application: ', defaultResponse = 'MyWheelsApp' );
    appName     = helpers.stripSpecialChars( appName );
    print.line().toConsole();

    // ---------------- Template
    print.yellowBoldLine( "🎭 Step 2: Choose a Template" )
      .line()
      .text( "Select a template to use as the starting point for your application." )
      .line();

    var template = multiselect( 'Which Wheels Template shall we use? ' )
      .options( [
        {value: 'wheels-base-template@BE', display: '3.0.x - Wheels Base Template - Bleeding Edge', selected: true},
        {value: 'cfwheels-base-template', display: '2.5.x - Wheels Base Template - Stable Release'},
        {value: 'cfwheels-template-htmx-alpine-simple', display: 'Wheels Template - HTMX - Alpine.js - Simple.css'},
        {value: 'cfwheels-template-example-app', display: 'Wheels Example App'},
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
    print.yellowBoldLine( "🔒 Step 3: Reload Password" )
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
    print.yellowBoldLine( "🗝️ Step 4: Database Configuration" )
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
    print.yellowBoldLine( "⚙️ Step 5: CFML Engine" )
      .line()
      .text( "Select the CFML engine for your application." )
      .line();

    var cfmlEngine = multiselect( 'Please select your preferred CFML engine? ' )
      .options( [
        {value: 'lucee', display: 'Lucee (Latest)', selected: true},
        {value: 'adobe', display: 'Adobe ColdFusion (Latest)'},
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

    // ---------------- Test H2 Database?
    if ( allowH2Creation ) {
      print.line();
      print.Line( 'As you are using Lucee, would you like to setup and use the' ).toConsole();
      var createH2Embedded = confirm( 'H2 Java embedded SQL database for development? [y,n]' );
    } else {
      createH2Embedded = false;
    }

    //---------------- This is just an idea at the moment really.
    print.line();
    print.greenBoldLine( "========= Twitter Bootstrap ======================" ).toConsole();
    var useBootstrap=false;
      if(confirm("Would you like us to setup some default Bootstrap settings? [y/n]")){
        useBootstrap = true;
      }

    // ---------------- Initialize as a package
    print.line();
    print.line( 'Finally, shall we initialize your application as a package' ).toConsole();
    var initPackage = confirm( 'by creating a box.json file? [y,n]' );

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
         .greenBoldLine( '| Setup Bootstrap       | #ljustify(useBootstrap,57)# |' )
         .greenBoldLine( '| Setup H2 Database     | #ljustify(createH2Embedded,57)# |' )
         .greenBoldLine( '| Initialize as Package | #ljustify(initPackage,57)# |' )
         .greenBoldLine( '| Force Installation    | #ljustify(force,57)# |' )
         .greenBoldLine( "+-----------------------+-----------------------------------------------------------+" )
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
        initWizard      = true).run();

    } else {
      rails.skip( "Application creation cancelled by user" );
    }

  }

}
