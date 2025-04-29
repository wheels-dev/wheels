/**
 * This will completely scaffold a new object. It will:
 *  - Create a model file
 *  - A Default CRUD Controller complete with create/edit/update/delete code
 *  - View files for all those actions
 *  - Associated test stubs
 *  - DB migration file
 *
 * {code:bash}
 * wheels scaffold user
 * {code}
 **/
component extends="base"  {

	/**
	 * @name Name of object to scaffold
	 **/
	function run(required string name) {
		// Captialisation etc handled by sub components;
		var objectname=trim(lcase(helpers.stripSpecialChars(arguments.name)));

		print.yellowline( "Creating Model" ).toConsole();
			command( 'wheels g model' )
				.params(
					name = objectname
				)
				.run();
			command( 'wheels g test' )
				.params(
					type = "model", 
					objectname = objectname
				)
				.run();
		print.line();

		print.yellowline( "Creating Controller" ).toConsole();
			command( 'wheels g controller' )
				.params(
					name = objectname, 
					actionlist = "crud"
				)
				.run();
			command( 'wheels g test' )
				.params(
					type = "controller", 
					objectname = objectname
				)
				.run();
		print.line();

		print.yellowline( "Creating View Files" ).toConsole();
			for(action in ["index","show","new","edit","_form"]){
				command( 'wheels g view' )
					.params(
						objectname = objectname, 
						name       = action, 
						template   = "crud/#action#"
					)
					.run();
				command( 'wheels g test' )
					.params(
						type = "view", 
						objectname = objectname, 
						name = action
					)
					.run();
			}
		print.line();

		print.yellowline( "Creating Default Resources Route" ).toConsole();
			command( 'wheels g route' )
				.params(
					objectname = objectname
				)
				.run();
		print.line();

		print.yellowline( "Migrating DB" ).toConsole();
		if(confirm("Would you like to migrate the database now? [y/n]")){
			command( 'wheels db latest' )
			.run();
	    }
		print.line();
	}

}
