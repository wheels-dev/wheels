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
component aliases="wheels g app-wizard, wheels new" extends="../base" {

  /**
   * @force          Force installation into an none empty directory
   **/
  function run(
    boolean force   = false
   ) {
    var appContent      = fileRead( getTemplate( '/ConfigAppContent.txt' ) );
    var routesContent   = fileRead( getTemplate( '/ConfigRoutes.txt' ) );

    // ---------------- Welcome
    print.greenBoldLine( '========= Hello! Welcome to the Wizard ===========' )
      .greenBoldLine( '| Welcome to the Wheels app wizard. We''re here |' )
      .greenBoldLine( '| to try and give you a helping hand to start yo |' )
      .greenBoldLine( '| Wheels app.                                  |' )
      .greenBoldLine( '==================================================' )
      .line()
      .toConsole();

    // ---------------- Set an app Name
    // TODO: Add conditions on what can in an application name
    print.greenBoldLine( '========= We Need Some Information ===============' )
      .greenBoldLine( '| To get going, we''re going to need to know a    |' )
      .greenBoldLine( '| NAME for your application. We''ll start with    |' )
      .greenBoldLine( '| a name like MyWheelsApp. Keep in  mind       |' )
      .greenBoldLine( '| that a new directory will be created for your  |' )
      .greenBoldLine( '| app in your current working directory.         |' )
      .greenBoldLine( '==================================================' )
      .line()
      .toConsole();

    var appName = ask( message = 'Please enter a name for your application: ', defaultResponse = 'MyWheelsApp' );
    appName     = helpers.stripSpecialChars( appName );
    print.line().toConsole();

    // ---------------- Template
    print.greenBoldLine( '============= Application Template ===============' )
      .greenBoldLine( '| Please select a templates to use as the        |' )
      .greenBoldLine( '| starting point for your application. You can   |' )
      .greenBoldLine( '| select on of our official templates or enter   |' )
      .greenBoldLine( '| a custom endpoint ID which can come from       |' )
      .greenBoldLine( '| ForgeBox, HTTP/S, git, GitHub, etc.            |' )
      .greenBoldLine( '==================================================' )
      .toConsole();

    var template = multiselect( 'Which Wheels Template shall we use? ' )
      .options( [
        {value: 'cfwheels-base-template', display: '2.5.x - Wheels Base Template - Stable Release', selected: true},
        {value: 'wheels-base-template@BE', display: '3.0.x - Wheels Base Template - Bleeding Edge'},
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
    print.greenBoldLine( '=========== And a ''Reload'' Password ==============' )
      .greenBoldLine( '| We also need a ''reload'' password to secure     |' )
      .greenBoldLine( '| your app. This can be something simple but     |' )
      .greenBoldLine( '| unique and known only to you. Your reload      |' )
      .greenBoldLine( '| password allows you to restart your app via    |' )
      .greenBoldLine( '| the URL. You can change it later if you need!  |' )
      .greenBoldLine( '==================================================' )
      .line()
      .toConsole();

    var reloadPassword = ask(
      message         = 'Please enter a ''reload'' password for your application: ',
      defaultResponse = 'changeMe'
    );
    print.line().toConsole();

    // ---------------- Set datasource Name
    print.greenBoldLine( '============= Data...Data...Data... ==============' )
      .greenBoldLine( '| All good apps need data. Unfortunately you''re  |' )
      .greenBoldLine( '| going to have to be responsible for this bit.  |' )
      .greenBoldLine( '| We''re expecting a valid DataSource to be       |' )
      .greenBoldLine( '| setup; so you''ll need mySQL or some other      |' )
      .greenBoldLine( '| supported DB server running locally. Once      |' )
      .greenBoldLine( '| you''ve setup a database, you''ll need to add it |' )
      .greenBoldLine( '| to the local CommandBox Lucee server which     |' )
      .greenBoldLine( '| we''ll start in a bit. For now, we just need to |' )
      .greenBoldLine( '| know what that datasource name will be.        |' )
      .greenBoldLine( '|                                                |' )
      .greenBoldLine( '| If you''re going to run lucee, we can           |' )
      .greenBoldLine( '| autocreate a development database for you.     |' )
      .greenBoldLine( '==================================================' )
      .line()
      .toConsole();

    var datasourceName = ask(
      message         = 'Please enter a datasource name if different from #appName#: ',
      defaultResponse = '#appName#'
    );

    if ( !len( datasourceName ) ) {
      datasourceName = appName;
    }
    print.line();

    // ---------------- Set default server.json engine
    print.greenBoldLine( '================== CFML Engine ===================' )
      .greenBoldLine( '| Now you need to specify the CFML engine you    |' )
      .greenBoldLine( '| wish to use. Once again you can choose one     |' )
      .greenBoldLine( '| from the list of available engines we have     |' )
      .greenBoldLine( '| supplied or specify a custom endpoint if you   |' )
      .greenBoldLine( '| need to test with a specific engine patch      |' )
      .greenBoldLine( '| point or snapshot. The custom endpoint can     |' )
      .greenBoldLine( '| come from ForgeBox, HTTP/S, git, GitHub, etc.  |' )
      .greenBoldLine( '==================================================' )
      .toConsole();

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
      allowH2Creation = true
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
      print.greenBoldLine( 'OK, another time then. *sobs* ' ).toConsole();
    }
    
  }

}
