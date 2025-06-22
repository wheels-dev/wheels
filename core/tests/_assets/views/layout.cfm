<cfoutput>
start:defaultlayout
#includeContent()#
<cfif structKeyExists(variables, "variableForLayout")>
	#variableForLayout#
</cfif>
end:defaultlayout
</cfoutput>