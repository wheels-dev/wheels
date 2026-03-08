<cfsetting requestTimeOut="300">
<cfscript>
// Get database info
local.db_info = $dbinfo(datasource = application.wheels.dataSourceName, type = "version");
local.db = LCase(Replace(local.db_info.database_productname, " ", "", "all"));

// Set DB-specific types
local.identityColumnType = "int NOT NULL IDENTITY";
if (local.db IS "mysql" or local.db IS "mariadb") {
	local.identityColumnType = "int NOT NULL AUTO_INCREMENT";
} else if (local.db IS "postgresql") {
	local.identityColumnType = "SERIAL NOT NULL";
}
local.storageEngine = (local.db IS "mysql" or local.db IS "mariadb") ? "ENGINE=InnoDB" : "";
</cfscript>

<!--- Drop existing tables --->
<cftry>
	<cfquery datasource="#application.wheels.dataSourceName#">DROP TABLE IF EXISTS c_o_r_e_posts</cfquery>
	<cfcatch></cfcatch>
</cftry>
<cftry>
	<cfquery datasource="#application.wheels.dataSourceName#">DROP TABLE IF EXISTS c_o_r_e_authors</cfquery>
	<cfcatch></cfcatch>
</cftry>

<!--- Create tables --->
<cfquery datasource="#application.wheels.dataSourceName#">
CREATE TABLE c_o_r_e_authors (
	id #local.identityColumnType#,
	firstname varchar(100) NOT NULL,
	lastname varchar(100) NOT NULL,
	PRIMARY KEY(id)
) #local.storageEngine#
</cfquery>

<cfquery datasource="#application.wheels.dataSourceName#">
CREATE TABLE c_o_r_e_posts (
	id #local.identityColumnType#,
	authorid int NULL,
	title varchar(250) NOT NULL,
	body text NOT NULL,
	createdat datetime NOT NULL,
	updatedat datetime NOT NULL,
	deletedat datetime NULL,
	views int DEFAULT 0 NOT NULL,
	averagerating float NULL,
	status varchar(20) DEFAULT 'draft' NOT NULL,
	PRIMARY KEY(id)
) #local.storageEngine#
</cfquery>

<!--- Populate data --->
<cfscript>
model("author").create(firstName = "Per", lastName = "Djurner");
model("author").create(firstName = "Tony", lastName = "Petruzzi");
model("author").create(firstName = "Chris", lastName = "Peters");
model("author").create(firstName = "Peter", lastName = "Amiri");
model("author").create(firstName = "James", lastName = "Gibson");
model("author").create(firstName = "Raul", lastName = "Riera");
model("author").create(firstName = "Andy", lastName = "Bellenie");
model("author").create(firstName = "Adam", lastName = "Chapman");
model("author").create(firstName = "Tom", lastName = "King");
model("author").create(firstName = "David", lastName = "Belanger");

// Create posts with various statuses
local.per = model("author").findOne(where = "firstName = 'Per'");
local.per.createPost(title = "First post", body = "Body 1", views = 5, status = "published");
local.per.createPost(title = "Second post", body = "Body 2", views = 5, status = "published");
local.per.createPost(title = "Third post", body = "Body 3", views = 0, averageRating = "3.2", status = "archived");

local.tony = model("author").findOne(where = "firstName = 'Tony'");
local.tony.createPost(title = "Fourth post", body = "Body 4", views = 3, averageRating = "3.6", status = "draft");
local.tony.createPost(title = "Fifth post", body = "Body 5", views = 2, averageRating = "3.6", status = "draft");
</cfscript>
