<!--- TestBox Runner for Wheels --->
<cfparam name="url.reporter" 		default="simple">
<cfparam name="url.directory" 		default="tests.specs">
<cfparam name="url.recurse" 		default="true" type="boolean">
<cfparam name="url.bundles" 		default="">
<cfparam name="url.labels" 			default="">
<cfparam name="url.excludes" 		default="">
<cfparam name="url.reportpath" 		default="#expandPath( "/tests/results" )#">
<cfparam name="url.propertiesFilename" 	default="TEST.properties">
<cfparam name="url.propertiesSummary" 	default="false" type="boolean">
<cfparam name="url.editor" 			default="vscode">
<cfparam name="url.bundlesPattern" 	default="*Spec*.cfc|*Test*.cfc|*Spec*.bx|*Test*.bx">
<cfparam name="url.parallel" 		default="true" type="boolean">
<cfparam name="url.verbose" 		default="true" type="boolean">
<cfparam name="url.coverage" 		default="false" type="boolean">
<cfparam name="url.coverageSonarQubeXMLOutputPath" default="">

<!--- Code Coverage requires FusionReactor --->
<cfif url.coverage AND NOT structKeyExists( server, "fusionreactor" )>
	<cfthrow message="Code coverage requires FusionReactor to be installed and running.">
</cfif>

<!--- Create TestBox instance --->
<cfset testbox = new testbox.system.TestBox(
	directory = {
		mapping = url.directory,
		recurse = url.recurse,
		filter = function( path ){
			return reFindNoCase( url.bundlesPattern, path );
		},
		exclude = len( url.excludes ) ? url.excludes : ""
	},
	bundles = url.bundles,
	labels = url.labels,
	reporter = url.reporter,
	reporterOptions = {
		reportPath = url.reportpath,
		propertiesFilename = url.propertiesFilename,
		propertiesSummary = url.propertiesSummary,
		editor = url.editor,
		verbose = url.verbose
	},
	options = {
		includeHiddenScopes = true
	}
)>

<!--- Configure parallel execution if enabled --->
<cfif url.parallel>
	<cfset testbox.setOptions({
		parallel = true,
		asyncAll = true,
		asyncTimeout = 300000, 
		maxThreads = 4
	})>
</cfif>

<!--- Configure coverage if enabled --->
<cfif url.coverage>
	<cfset testbox.setOptions({
		coverage = {
			enabled = true,
			pathToCapture = expandPath( "/app" ),
			whitelist = "*.cfc",
			blacklist = "**/tests/**,**/testbox/**,**/vendor/**",
			generateSonarQubeXMLReport = len( url.coverageSonarQubeXMLOutputPath ) GT 0,
			sonarQubeXMLOutputPath = url.coverageSonarQubeXMLOutputPath
		}
	})>
</cfif>

<!--- Run tests --->
<cfset results = testbox.run()>

<!--- Display results based on reporter --->
<cfswitch expression="#url.reporter#">
	<cfcase value="json">
		<cfcontent type="application/json">
		<cfoutput>#serializeJSON( results.getMemento() )#</cfoutput>
	</cfcase>
	
	<cfcase value="junit">
		<cfcontent type="application/xml">
		<cfoutput>#results.getResultsOutput()#</cfoutput>
	</cfcase>
	
	<cfcase value="tap">
		<cfcontent type="text/plain">
		<cfoutput>#results.getResultsOutput()#</cfoutput>
	</cfcase>
	
	<cfcase value="text">
		<cfcontent type="text/plain">
		<cfoutput>#results.getResultsOutput()#</cfoutput>
	</cfcase>
	
	<cfdefaultcase>
		<!DOCTYPE html>
		<html>
		<head>
			<meta charset="utf-8">
			<meta name="viewport" content="width=device-width, initial-scale=1">
			<title>Wheels Test Results</title>
			<style>
				body {
					font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, "Helvetica Neue", Arial, sans-serif;
					margin: 0;
					padding: 20px;
					background: #f5f5f5;
				}
				.container {
					max-width: 1200px;
					margin: 0 auto;
					background: white;
					padding: 20px;
					border-radius: 8px;
					box-shadow: 0 2px 4px rgba(0,0,0,0.1);
				}
				h1 {
					color: #333;
					margin-bottom: 20px;
				}
				.stats {
					display: grid;
					grid-template-columns: repeat(auto-fit, minmax(200px, 1fr));
					gap: 20px;
					margin-bottom: 30px;
				}
				.stat {
					padding: 20px;
					border-radius: 8px;
					text-align: center;
				}
				.stat.success { background: #d4edda; color: #155724; }
				.stat.error { background: #f8d7da; color: #721c24; }
				.stat.failure { background: #fff3cd; color: #856404; }
				.stat.info { background: #d1ecf1; color: #0c5460; }
				.stat h3 { margin: 0 0 10px 0; }
				.stat .number { font-size: 2em; font-weight: bold; }
				
				.test-results {
					margin-top: 20px;
				}
				
				.progress {
					width: 100%;
					height: 20px;
					background: #e9ecef;
					border-radius: 10px;
					overflow: hidden;
					margin-bottom: 20px;
				}
				
				.progress-bar {
					height: 100%;
					background: #28a745;
					transition: width 0.3s ease;
				}
				
				.coverage {
					margin-top: 30px;
					padding: 20px;
					background: #f8f9fa;
					border-radius: 8px;
				}
				
				.actions {
					margin-top: 20px;
					display: flex;
					gap: 10px;
					flex-wrap: wrap;
				}
				
				.btn {
					padding: 10px 20px;
					background: #007bff;
					color: white;
					text-decoration: none;
					border-radius: 5px;
					transition: background 0.2s;
				}
				
				.btn:hover {
					background: #0056b3;
				}
				
				.btn.secondary {
					background: #6c757d;
				}
				
				.btn.secondary:hover {
					background: #545b62;
				}
			</style>
		</head>
		<body>
			<div class="container">
				<h1>🧪 Wheels Test Results</h1>
				
				<cfset stats = results.getMemento()>
				<cfset successRate = stats.totalSpecs GT 0 ? (stats.totalPass / stats.totalSpecs * 100) : 0>
				
				<div class="progress">
					<div class="progress-bar" style="width: #numberFormat(successRate, '0')#%"></div>
				</div>
				
				<div class="stats">
					<div class="stat info">
						<h3>Total Specs</h3>
						<div class="number">#stats.totalSpecs#</div>
					</div>
					<div class="stat success">
						<h3>Passed</h3>
						<div class="number">#stats.totalPass#</div>
					</div>
					<div class="stat failure">
						<h3>Failed</h3>
						<div class="number">#stats.totalFail#</div>
					</div>
					<div class="stat error">
						<h3>Errors</h3>
						<div class="number">#stats.totalError#</div>
					</div>
				</div>
				
				<div class="test-results">
					<cfoutput>#results.getResultsOutput( "html" )#</cfoutput>
				</div>
				
				<cfif url.coverage AND structKeyExists( results, "getCoverageData" )>
					<div class="coverage">
						<h2>📊 Code Coverage</h2>
						<cfset coverageData = results.getCoverageData()>
						<p>Line Coverage: <strong>#numberFormat( coverageData.percentageLineCoverage, "0.00" )#%</strong></p>
						<p>Files Analyzed: <strong>#coverageData.numFiles#</strong></p>
						<p>Lines Covered: <strong>#coverageData.numLinesCovered# / #coverageData.numLines#</strong></p>
					</div>
				</cfif>
				
				<div class="actions">
					<a href="?directory=#url.directory#&reporter=#url.reporter#&recurse=#url.recurse#" class="btn">🔄 Run Again</a>
					<a href="?directory=#url.directory#&reporter=json&recurse=#url.recurse#" class="btn secondary">📄 JSON Report</a>
					<a href="?directory=#url.directory#&reporter=junit&recurse=#url.recurse#" class="btn secondary">📋 JUnit Report</a>
					<cfif NOT url.coverage>
						<a href="?directory=#url.directory#&reporter=#url.reporter#&recurse=#url.recurse#&coverage=true" class="btn secondary">📊 With Coverage</a>
					</cfif>
				</div>
			</div>
		</body>
		</html>
	</cfdefaultcase>
</cfswitch>