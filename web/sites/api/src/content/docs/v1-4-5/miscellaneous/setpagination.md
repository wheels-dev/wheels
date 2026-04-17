---
title: setPagination()
description: "Allows you to set a pagination handle for a custom query so you can perform pagination on it in your view with paginationLinks."
sidebar:
  label: setPagination()
  order: 0
---

## Signature

`setPagination()` — returns `any`




## Description

Allows you to set a pagination handle for a custom query so you can perform pagination on it in your view with paginationLinks.

## Parameters

| Name | Type | Required | Default | Description |
| ---- | ---- | -------- | ------- | ----------- |
| `totalRecords` | `numeric` | yes | — | Total count of records that should be represented by the paginated links. |
| `currentPage` | `numeric` | yes | `1` | Page number that should be represented by the data being fetched and the paginated links. |
| `perPage` | `numeric` | yes | `25` | Number of records that should be represented on each page of data. |
| `handle` | `string` | yes | `query` | Name of handle to reference in paginationLinks. |

## Examples

<pre>&lt;!--- Note that there are two ways to do pagination yourself using a custom query. 1) Do a query that grabs everything that matches and then use the `cfouput` or `cfloop` tag to page through the results. 2) Use your database to make 2 queries. The first query basically does a count of the total number of records that match the criteria and the second query actually selects the page of records for retrieval. In the example below, we will show how to write a custom query using both of these methods. Note that the syntax where your database performs the pagination will differ depending on the database engine you are using. Plese consult your database engine''s documentation for the correct syntax. Also note that the view code will differ depending on the method used. ---&gt; &lt;!--- First method: Handle the pagination through your CFML engine ---&gt; &lt;!--- Model code In your model (ie. User.cfc), create a custom method for your custom query ---&gt; &lt;cffunction name=&quot;myCustomQuery&quot;&gt; &lt;cfargument name=&quot;page&quot; type=&quot;numeric&quot;&gt; &lt;cfargument name=&quot;perPage&quot; type=&quot;numeric&quot; required=&quot;false&quot; default=&quot;25&quot;&gt; &lt;cfquery name=&quot;local.customQuery&quot; datasource=&quot;##get(''dataSourceName'')##&quot;&gt; SELECT * FROM users &lt;/cfquery&gt; &lt;cfset setPagination( totalRecords=local.customQuery.RecordCount, currentPage=arguments.page, perPage=arguments.perPage, handle=&quot;myCustomQueryHandle&quot; )&gt; &lt;cfreturn customQuery&gt; &lt;/cffunction&gt; &lt;!--- Controller code ---&gt; &lt;cffunction name=&quot;list&quot;&gt; &lt;cfparam name=&quot;params.page&quot; default=&quot;1&quot;&gt; &lt;cfparam name=&quot;params.perPage&quot; default=&quot;25&quot;&gt; &lt;cfset allUsers = model(&quot;user&quot;).myCustomQuery( page=params.page, perPage=params.perPage )&gt; &lt;!--- Because we're going to let `cfoutput`/`cfloop` handle the pagination, we're going to need to get some addition information about the pagination. ---&gt; &lt;cfset paginationData = pagination(&quot;myCustomQueryHandle&quot;)&gt; &lt;/cffunction&gt; &lt;!--- View code (using `cfloop`) Use the information from `paginationData` to page through the records ---&gt; &lt;cfoutput&gt; &lt;ul&gt; &lt;cfloop query=&quot;allUsers&quot; startrow=&quot;#paginationData.startrow#&quot; endrow=&quot;#paginationData.endrow#&quot; &gt; &lt;li&gt; #allUsers.firstName# #allUsers.lastName# &lt;/li&gt; &lt;/cfloop&gt; &lt;/ul&gt; #paginationLinks(handle=&quot;myCustomQueryHandle&quot;)# &lt;/cfoutput&gt; &lt;!--- View code (using `cfoutput`) Use the information from `paginationData` to page through the records ---&gt; &lt;ul&gt; &lt;cfoutput query=&quot;allUsers&quot; startrow=&quot;#paginationData.startrow#&quot; maxrows=&quot;#paginationData.maxrows#&quot; &gt; &lt;li&gt; #allUsers.firstName# #allUsers.lastName# &lt;/li&gt; &lt;/cfoutput&gt; &lt;/ul&gt; &lt;cfoutput&gt; #paginationLinks(handle=&quot;myCustomQueryHandle&quot;)# &lt;/cfoutput&gt; &lt;!--- Second method: Handle the pagination through the database ---&gt; &lt;!--- Model code In your model (ie. `User.cfc`), create a custom method for your custom query ---&gt; &lt;cffunction name=&quot;myCustomQuery&quot;&gt; &lt;cfargument name=&quot;page&quot; type=&quot;numeric&quot;&gt; &lt;cfargument name=&quot;perPage&quot; type=&quot;numeric&quot; required=&quot;false&quot; default=&quot;25&quot;&gt; &lt;cfquery name=&quot;local.customQueryCount&quot; datasource=&quot;#get('dataSouceName')#&quot; &gt; SELECT COUNT(*) AS theCount FROM users &lt;/cfquery&gt; &lt;cfquery name=&quot;local.customQuery&quot; datasource=&quot;#get('dataSourceName')#&quot; &gt; SELECT * FROM users LIMIT #arguments.page# OFFSET #arguments.perPage# &lt;/cfquery&gt; &lt;!--- Notice the we use the value from the first query for `totalRecords` ---&gt; &lt;cfset setPagination( totalRecords=local.customQueryCount.theCount, currentPage=arguments.page, perPage=arguments.perPage, handle=&quot;myCustomQueryHandle&quot; )&gt; &lt;!--- We return the second query ---&gt; &lt;cfreturn customQuery&gt; &lt;/cffunction&gt; &lt;!--- Controller code ---&gt; &lt;cffunction name=&quot;list&quot;&gt; &lt;cfparam name=&quot;params.page&quot; default=&quot;1&quot;&gt; &lt;cfparam name=&quot;params.perPage&quot; default=&quot;25&quot;&gt; &lt;cfset allUsers = model(&quot;user&quot;).myCustomQuery( page=params.page, perPage=params.perPage )&gt; &lt;/cffunction&gt; &lt;!--- View code (using `cfloop`) ---&gt; &lt;cfoutput&gt; &lt;ul&gt; &lt;cfloop query=&quot;allUsers&quot;&gt; &lt;li&gt; #allUsers.firstName# #allUsers.lastName# &lt;/li&gt; &lt;/cfloop&gt; &lt;/ul&gt; #paginationLinks(handle=&quot;myCustomQueryHandle&quot;)# &lt;/cfoutput&gt; &lt;!--- View code (using `cfoutput`) ---&gt; &lt;ul&gt; &lt;cfoutput query=&quot;allUsers&quot;&gt; &lt;li&gt; #allUsers.firstName# #allUsers.lastName# &lt;/li&gt; &lt;/cfoutput&gt; &lt;/ul&gt; &lt;cfoutput&gt; #paginationLinks(handle=&quot;myCustomQueryHandle&quot;)# &lt;/cfoutput&gt;</pre>
