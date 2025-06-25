<!--- cfformat-ignore-start --->
<cfcomponent displayname="toXML" hint="Set of utility functions to generate XML" output="false">
	<!---
		Based on the toXML component by Raymond Camden: http://www.coldfusionjedi.com/index.cfm/2006/7/2/ToXML-CFC--Converting-data-types-to-XML

		toXML function made by Paul Klinkenberg, 25-feb-2009
		http://www.coldfusiondeveloper.nl/post.cfm/toxml-function-for-coldfusion

		Version 1.1, March 8, 2010
		Now using <cfsavecontent> while generating the xml output in the functions, since it increases process speed
		Thanks to Brian Meloche (http://www.brianmeloche.com/blog/) for pointing it out

		Version 1.2, September 1, 2010
		- Cleaned up variables to reference the arguments scope so CF doesn't have to search the different scopes
		- Cleaned up methods to only use var once per method call
		- Created a new method $simpleValueToXml()
		- Add tests outside of component
	--->

	<cffunction name="init" returntype="any" access="public" output="false" hint="I return the toXml Object">
		<cfreturn this />
	</cffunction>

	<cffunction name="toXML" returntype="string" access="public" output="no" hint="Recursively converts any kind of data to xml">
		<cfargument name="data" type="any" required="yes" />
		<cfargument name="rootelement" type="string" required="false" default="data" />
		<cfargument name="elementattributes" type="string" required="false" default="" hint="Optional string like 'order=2', which will be added into the starting rootElement tag." />
		<cfargument name="addXMLHeader" type="boolean" required="no" default="true" hint="Whether or not to add the &lt;?xml?&gt; tag" />
		<cfset var rv = "" />
		<cfif Len(arguments.elementattributes)>
			<cfset arguments.elementattributes = " " & Trim(arguments.elementattributes) />
		</cfif>
		<cfsavecontent variable="rv"><!---
			---><cfoutput><!---
				---><cfif arguments.addXMLHeader><!---
					---><?xml version="1.0" encoding="UTF-8"?><!---
				---></cfif><!---
				---><cfif IsSimpleValue(arguments.data)><!---
					--->#$simpleValueToXml(argumentCollection=arguments)#<!---
				---><cfelseif IsQuery(arguments.data)><!---
					--->#$queryToXML(argumentCollection=arguments)#<!---
				---><cfelseif IsArray(arguments.data)><!---
					--->#$arrayToXML(argumentCollection=arguments)#<!---
				---><cfelseif IsObject(arguments.data)><!---
					--->#$objectToXML(argumentCollection=arguments)#<!---
				---><cfelseif IsStruct(arguments.data)><!---
					--->#$structToXML(argumentCollection=arguments)#<!---
				---><cfelseif REFindNoCase("^coldfusion\..*Exception$", arguments.data.getClass().getName())><!---
					--->#$structToXML(argumentCollection=arguments)#<!---
				---><cfelse><!---
					--->#$simpleValueToXml(data="Unknown object of type #arguments.data.getClass().getName()#", rootelement=arguments.rootelement, elementattributes=arguments.elementattributes)#<!---
				---></cfif><!---
			---></cfoutput><!---
		---></cfsavecontent>
		<cfreturn rv />
	</cffunction>

	<cffunction name="$simpleValueToXml" access="public" output="false" returntype="string">
		<cfargument name="data" type="string" required="true" />
		<cfargument name="rootelement" type="string" required="false" default="data" />
		<cfargument name="elementattributes" type="string" required="false" default="" />
		<cfset var rv = "" />
		<cfset arguments.data = XmlFormat(arguments.data) />
		<cfsavecontent variable="rv"><!---
			---><cfoutput><!---
				---><cfif IsNumeric(arguments.data)><!---
					---><#arguments.rootelement# type="numeric"#arguments.elementattributes#>#arguments.data#</#arguments.rootelement#><!---
				---><cfelseif IsBoolean(arguments.data)><!---
					---><#arguments.rootelement# type="boolean"#arguments.elementattributes#><cfif arguments.data>1<cfelse>0</cfif></#arguments.rootelement#><!---
				---><cfelseif not Len(arguments.data)><!---
					---><#arguments.rootelement# type="string"#arguments.elementattributes#/><!---
				---><cfelse><!---
					---><#arguments.rootelement# type="string"#arguments.elementattributes#>#arguments.data#</#arguments.rootelement#><!---
				---></cfif><!---
			---></cfoutput><!---
		---></cfsavecontent>
		<cfreturn rv />
	</cffunction>

	<cffunction name="$arrayToXML" access="public" output="false" returntype="string" hint="Converts an array into XML">
		<cfargument name="data" type="array" required="true" />
		<cfargument name="rootelement" type="string" required="false" default="data" />
		<cfargument name="elementattributes" type="string" required="false" default="" />
		<cfargument name="itemelement" type="string" required="false" default="item" />

		<cfsavecontent variable="local.rv"><!---
			---><cfoutput><!---
				---><#arguments.rootelement# type="array"#elementattributes#><!---
					---><cfloop from="1" to="#ArrayLen(arguments.data)#" index="local.x"><!---
						--->#toXML(data=arguments.data[local.x], rootelement=arguments.itemelement, elementattributes="order=""#local.x#""", addXMLHeader=false)#<!---
					---></cfloop><!---
				---></#arguments.rootelement#><!---
			---></cfoutput><!---
		---></cfsavecontent>

		<cfreturn local.rv />
	</cffunction>

	<cffunction name="$queryToXML" access="public" output="false" returntype="string" hint="Converts a query to XML">
		<cfargument name="data" type="query" required="true" />
		<cfargument name="rootelement" type="string" required="false" default="data" />
		<cfargument name="elementattributes" type="string" required="false" default="" />
		<cfargument name="itemelement" type="string" required="false" default="row" />
		<cfset local.columns = arguments.data.columnList />

		<cfsavecontent variable="local.rv"><!---
			---><cfoutput><!---
				---><#arguments.rootelement# type="query"#arguments.elementattributes#><!---
					---><cfloop query="arguments.data"><!---
						---><#arguments.itemelement# order="#arguments.data.currentrow#"><!---
							---><cfloop list="#local.columns#" index="local.col"><!---
								--->#toXML(data=arguments.data[local.col][arguments.data.currentRow], rootElement=local.col, addXMLHeader=false)#<!---
							---></cfloop><!---
						---></#arguments.itemelement#><!---
					---></cfloop><!---
				---></#arguments.rootelement#><!---
			---></cfoutput><!---
		---></cfsavecontent>

		<cfreturn local.rv />
	</cffunction>

	<cffunction name="$structToXML" access="public" output="false" returntype="string" hint="Converts a struct into XML.">
		<cfargument name="data" type="any" required="true" hint="It should be a struct, but can also be an 'exception' type." />
		<cfargument name="rootelement" type="string" required="false" default="data" />
		<cfargument name="elementattributes" type="string" required="false" default="" />
		<cfset local.keys = StructKeyList(arguments.data) />

		<cfsavecontent variable="local.rv"><!---
			---><cfoutput><!---
				---><#arguments.rootelement# type="struct"#arguments.elementattributes#><!---
					---><cfloop list="#local.keys#" index="local.key"><!---
						--->#toXML(data=arguments.data[local.key], rootelement=local.key, addXMLHeader=false)#<!---
					---></cfloop><!---
				---></#arguments.rootelement#><!---
			---></cfoutput><!---
		---></cfsavecontent>

		<cfreturn local.rv />
	</cffunction>

	<cffunction name="$objectToXML" access="public" output="false" returntype="string" hint="Converts a struct into XML.">
		<cfargument name="data" type="component" required="true" hint="It should be a struct, but can also be an 'exception' type." />
		<cfargument name="rootelement" type="string" required="false" default="data" />
		<cfargument name="elementattributes" type="string" required="false" default="" />
		<cfset local.keys = ListSort(StructKeyList(arguments.data), "textnocase", "asc") />
		<cfset local.name = GetMetaData(arguments.data).name/>

		<cfsavecontent variable="local.rv"><!---
			---><cfoutput><!---
				---><#arguments.rootelement# type="component" name="#local.name#"#arguments.elementattributes#><!---
					---><cfloop list="#local.keys#" index="local.key"><!---
						---><cfif !IsCustomFunction(arguments.data[local.key])><!---
							--->#toXML(data=arguments.data[local.key], rootelement=local.key, addXMLHeader=false)#<!---
						---></cfif><!---
					---></cfloop><!---
				---></#arguments.rootelement#><!---
			---></cfoutput><!---
		---></cfsavecontent>

		<cfreturn local.rv />
	</cffunction>

</cfcomponent>
<!--- cfformat-ignore-end --->
