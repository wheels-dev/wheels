---
title: setPagination()
description: "Allows you to set a pagination handle for a custom query so you can perform pagination on it in your view with <code>paginationLinks</code>."
sidebar:
  label: setPagination()
  order: 0
---

## Signature

`setPagination()` — returns `void`

**Available in:** `controller`, `model`, `mapper`, `migrator`, `migration`, `tabledefinition`
**Category:** Pagination Functions

## Description

Allows you to set a pagination handle for a custom query so you can perform pagination on it in your view with <code>paginationLinks</code>.



## Parameters

<div class="wd-params-table">

| Name | Type | Required | Default | Description |
| ---- | ---- | -------- | ------- | ----------- |
| `totalRecords` | `numeric` | yes | — | Total count of records that should be represented by the paginated links. |
| `currentPage` | `numeric` | no | `1` | Page number that should be represented by the data being fetched and the paginated links. |
| `perPage` | `numeric` | no | `25` | Number of records that should be represented on each page of data. |
| `handle` | `string` | no | `query` | Name of handle to reference in `paginationLinks`. |

</div>

## Examples

<pre><code class='javascript'>// 1. Basic usage: paginate a custom query inside a model method, letting the CFML engine handle pagination
// In app/models/User.cfc
function searchByName(required string name, numeric page = 1, numeric perPage = 25) {
	local.allMatches = QueryExecute(
		&quot;SELECT * FROM users WHERE firstName LIKE :name ORDER BY lastName&quot;,
		{ name = { value = &quot;%&quot; &amp; arguments.name &amp; &quot;%&quot;, cfsqltype = &quot;cf_sql_varchar&quot; } },
		{ datasource = get(&quot;dataSourceName&quot;) }
	);
	setPagination(
		totalRecords = local.allMatches.recordCount,
		currentPage  = arguments.page,
		perPage      = arguments.perPage,
		handle       = &quot;userSearch&quot;
	);
	return local.allMatches;
}

// In app/controllers/Users.cfc
function search() {
	param name=&quot;params.page&quot;    default=&quot;1&quot;;
	param name=&quot;params.perPage&quot; default=&quot;25&quot;;
	searchResults = model(&quot;User&quot;).searchByName(
		name    = params.q,
		page    = params.page,
		perPage = params.perPage
	);
	paginationData = pagination(&quot;userSearch&quot;);
}

&lt;!--- In app/views/users/search.cfm ---&gt;
&lt;!--- Use startRow / endRow to page through the full query result ---&gt;
&lt;ul&gt;
	&lt;cfloop query=&quot;searchResults&quot;
	        startRow=&quot;#paginationData.startRow#&quot;
	        endRow=&quot;#paginationData.endRow#&quot;&gt;
		&lt;li&gt;#searchResults.firstName# #searchResults.lastName#&lt;/li&gt;
	&lt;/cfloop&gt;
&lt;/ul&gt;
#paginationLinks(handle=&quot;userSearch&quot;)#

// 2. Database-level pagination: run a COUNT query and a page-slice query separately
// In app/models/Article.cfc
function pagedResults(numeric page = 1, numeric perPage = 10) {
	local.countQuery = QueryExecute(
		&quot;SELECT COUNT(*) AS total FROM articles WHERE publishedAt IS NOT NULL&quot;,
		[],
		{ datasource = get(&quot;dataSourceName&quot;) }
	);
	local.pageQuery = QueryExecute(
		&quot;SELECT * FROM articles WHERE publishedAt IS NOT NULL ORDER BY publishedAt DESC LIMIT :perPage OFFSET :offset&quot;,
		{
			perPage = { value = arguments.perPage, cfsqltype = &quot;cf_sql_integer&quot; },
			offset  = { value = (arguments.page - 1) * arguments.perPage, cfsqltype = &quot;cf_sql_integer&quot; }
		},
		{ datasource = get(&quot;dataSourceName&quot;) }
	);
	// Use the COUNT result so paginationLinks reflects the total, not just this page
	setPagination(
		totalRecords = local.countQuery.total,
		currentPage  = arguments.page,
		perPage      = arguments.perPage,
		handle       = &quot;articles&quot;
	);
	return local.pageQuery;
}

// In app/controllers/Articles.cfc
function index() {
	param name=&quot;params.page&quot;    default=&quot;1&quot;;
	param name=&quot;params.perPage&quot; default=&quot;10&quot;;
	articles = model(&quot;Article&quot;).pagedResults(
		page    = params.page,
		perPage = params.perPage
	);
}

&lt;!--- In app/views/articles/index.cfm ---&gt;
&lt;ul&gt;
	&lt;cfloop query=&quot;articles&quot;&gt;
		&lt;li&gt;#articles.title#&lt;/li&gt;
	&lt;/cfloop&gt;
&lt;/ul&gt;
#paginationLinks(handle=&quot;articles&quot;)#

// 3. Use the default handle name so paginationLinks() needs no handle argument
// In app/models/Product.cfc
function featured(numeric page = 1) {
	local.q = QueryExecute(
		&quot;SELECT * FROM products WHERE featured = 1 ORDER BY name&quot;,
		[],
		{ datasource = get(&quot;dataSourceName&quot;) }
	);
	// Omitting handle defaults it to &quot;query&quot;, matching paginationLinks() default
	setPagination(totalRecords = local.q.recordCount, currentPage = arguments.page);
	return local.q;
}

// In app/controllers/Products.cfc
function index() {
	param name=&quot;params.page&quot; default=&quot;1&quot;;
	products     = model(&quot;Product&quot;).featured(page = params.page);
	pagingData   = pagination(); // uses default handle &quot;query&quot;
}

&lt;!--- In app/views/products/index.cfm ---&gt;
&lt;ul&gt;
	&lt;cfloop query=&quot;products&quot;
	        startRow=&quot;#pagingData.startRow#&quot;
	        endRow=&quot;#pagingData.endRow#&quot;&gt;
		&lt;li&gt;#products.name#&lt;/li&gt;
	&lt;/cfloop&gt;
&lt;/ul&gt;
#paginationLinks()#
</code></pre>
