---
title: setPagination()
description: "Allows you to set a pagination handle for a custom query so you can perform pagination on it in your view with <code>paginationLinks</code>."
sidebar:
  label: setPagination()
  order: 0
---

## Signature

`setPagination()` — returns `void`

**Available in:** `controller`, `model`, `migrator`, `migration`, `tabledefinition`
**Category:** Pagination Functions

## Description

Allows you to set a pagination handle for a custom query so you can perform pagination on it in your view with <code>paginationLinks</code>.



## Parameters

| Name | Type | Required | Default | Description |
| ---- | ---- | -------- | ------- | ----------- |
| `totalRecords` | `numeric` | yes | — | Total count of records that should be represented by the paginated links. |
| `currentPage` | `numeric` | no | `1` | Page number that should be represented by the data being fetched and the paginated links. |
| `perPage` | `numeric` | no | `25` | Number of records that should be represented on each page of data. |
| `handle` | `string` | no | `query` | Name of handle to reference in `paginationLinks`. |

## Examples

<pre><code class='javascript'>/* Note that there are two ways to do pagination yourself using a custom query.
	1) Do a query that grabs everything that matches and then use
	the `cfouput` or `cfloop` tag to page through the results.
	2) Use your database to make 2 queries. The first query
	basically does a count of the total number of records that match
	the criteria and the second query actually selects the page of
	records for retrieval.
	In the example below, we will show how to write a custom query
	using both of these methods. Note that the syntax where your
	database performs the pagination will differ depending on the
	database engine you are using. Plese consult your database
	engine's documentation for the correct syntax.
	Also note that the view code will differ depending on the method
	used.
*/

//=================== First method: Handle the pagination through your CFML engine

// Model code: In your model (ie. User.cfc), create a custom method for your custom query
function myCustomQuery(required numeric page, numeric perPage=25){
	local.customQuery=QueryExecute(&quot;SELECT * FROM users&quot;, [], { datasource=get('dataSourceName') });
	setPagination(
		totalRecords=local.customQuery.RecordCount,
		currentPage=arguments.page,
		perPage=arguments.perPage,
		handle=&quot;myCustomQueryHandle&quot;);
	return local.customQuery;
}

// Controller code
function list(){
	param name=&quot;params.page&quot; default=&quot;1;
	param name=&quot;params.perPage&quot; default=&quot;25&quot;;
	allUsers = model(&quot;user&quot;).myCustomQuery( page=params.page, perPage=params.perPage);

	// Because we're going to let `cfoutput`/`cfloop` handle the pagination,
	// we're going to need to get some addition information about the pagination.
	paginationData = pagination(&quot;myCustomQueryHandle&quot;)
}

&lt;!--- View code (using `cfloop`): Use the information from `paginationData` to page through the records ---&gt;
&lt;ul&gt;
	&lt;cfloop query=&quot;allUsers&quot; startrow=&quot;#paginationData.startrow#&quot; endrow=&quot;#paginationData.endrow#&quot; &gt;
	&lt;li&gt; #allUsers.firstName# #allUsers.lastName# &lt;/li&gt;
	&lt;/cfloop&gt;
&lt;/ul&gt;
#paginationLinks(handle=&quot;myCustomQueryHandle&quot;)#

&lt;!--- View code (using `cfoutput`) Use the information from `paginationData` to page through the records---&gt;
&lt;ul&gt;
	&lt;cfoutput query=&quot;allUsers&quot; startrow=&quot;#paginationData.startrow#&quot; maxrows=&quot;#paginationData.maxrows#&quot; &gt;
	&lt;li&gt; #allUsers.firstName# #allUsers.lastName# &lt;/li&gt;
	&lt;/cfoutput&gt;
&lt;/ul&gt;
#paginationLinks(handle=&quot;myCustomQueryHandle&quot;)#

//=================== Second method: Handle the pagination through the database

// Model code: In your model (ie. `User.cfc`), create a custom method for your custom query

function myCustomQuery(required numeric page, numeric perPage=25){
	local.customQueryCount=QueryExecute(&quot;SELECT COUNT(*) AS theCount FROM users&quot;,
										[], { datasource=get('dataSourceName') });
	local.customQuery=QueryExecute(&quot;SELECT * FROM users LIMIT ? OFFSET ?&quot;,
									[arguments.page, arguments.perPage],
									{ datasource=get('dataSourceName') });

	//Notice the we use the value from the first query for `totalRecords`
	setPagination(
		totalRecords=local.customQueryCount.theCount,
		currentPage=arguments.page,
		perPage=arguments.perPage,
		handle=&quot;myCustomQueryHandle&quot; );

	// We return the second query
	return local.customQuery;
}

// Controller code
function list(){
	param name=&quot;params.page&quot; default=&quot;1;
	param name=&quot;params.perPage&quot; default=&quot;25&quot;;
	allUsers = model(&quot;user&quot;).myCustomQuery( page=params.page, perPage=params.perPage);
}

&lt;!--- View code (using `cfloop`)---&gt;
&lt;ul&gt;
	&lt;cfloop query=&quot;allUsers&quot;&gt;
	&lt;li&gt; #allUsers.firstName# #allUsers.lastName# &lt;/li&gt;
	&lt;/cfloop&gt;
&lt;/ul&gt;
#paginationLinks(handle=&quot;myCustomQueryHandle&quot;)#

&lt;!--- View code (using `cfoutput`)---&gt;
&lt;ul&gt;
	&lt;cfoutput query=&quot;allUsers&quot;&gt;
	&lt;li&gt; #allUsers.firstName# #allUsers.lastName# &lt;/li&gt;
	&lt;/cfoutput&gt;
&lt;/ul&gt;
#paginationLinks(handle=&quot;myCustomQueryHandle&quot;)#

</code></pre>
