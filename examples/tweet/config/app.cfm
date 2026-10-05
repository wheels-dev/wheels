<cfscript>
	/*
		Use this file to set variables for the Application.cfc's "this" scope.

		Examples:
		this.name = "MyAppName";
		this.sessionTimeout = CreateTimeSpan(0,0,5,0);
	*/

	this.name = "tweet";
	this.datasources['tweet'] = {
          class: 'org.h2.Driver'
        , connectionString: 'jdbc:h2:file:' & expandPath('../db/h2/tweet') & ';MODE=MySQL'
        , username = 'sa'
        };
        this.datasources['tweet_test'] = {
          class: 'org.h2.Driver'
        , connectionString: 'jdbc:h2:file:' & expandPath('../db/h2/tweet_test') & ';MODE=MySQL'
        , username = 'sa'
        };
        this.datasources['wheelstestdb_h2'] = {
          class: 'org.h2.Driver'
        , connectionString: 'jdbc:h2:file:' & expandPath('../db/h2/wheelstestdb_h2') & ';MODE=MySQL'
        , username = 'sa'
        };
        // CLI-Appends-Here
</cfscript>
