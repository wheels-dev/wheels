/**
 * Shows Forgebox Plugins List for Wheels
 *
 * {code:bash}
 * wheels plugins list
 * {code}
 **/
component aliases="wheels plugin list" extends="../base"  {

	/**
	 *
	 **/
	function run(  ) {
		print.greenBoldLine("================ Wheels Plugins From Forgebox ======================")
		command('forgebox show').params(type="cfwheels-plugins").run();
		print.greenBoldLine("======================================================================");
	}

}
