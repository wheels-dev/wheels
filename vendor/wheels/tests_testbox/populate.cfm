<!--- get the version of the database we're running against --->
<cftry>
	<cfdbinfo name="local.dbinfo" datasource="#application.wheels.dataSourceName#" type="version">
	<cfcatch type="any">
		<cfthrow
			message="Datasource not found?"
			detail="The CFDBINFO call appears to have failed when looking for #application.wheels.dataSourceName#"
		>
	</cfcatch>
</cftry>
<cfset local.db = LCase(
	Replace(
		local.dbinfo.database_productname,
		" ",
		"",
		"all"
	)
)>

<!--- handle differences in database for identity inserts, column types etc --->
<cfset local.storageEngine = "">
<cfset local.dateTimeColumnType = "datetime">
<cfset local.dateTimeDefault = "'2000-01-01 18:26:08.490'">
<cfset local.binaryColumnType = "blob">
<cfset local.textColumnType = "text">
<cfset local.intColumnType = "int">
<cfset local.floatColumnType = "float">
<cfset local.identityColumnType = "">
<cfset local.bitColumnType = "bit">
<cfset local.bitColumnDefault = 0>

<cfif local.db IS "microsoftsqlserver">
	<cfset local.identityColumnType = "int NOT NULL IDENTITY(1,1)">
	<cfset local.binaryColumnType = "image">
<cfelseif local.db IS "mysql" or local.db IS "mariadb">
	<cfset local.identityColumnType = "int NOT NULL AUTO_INCREMENT">
	<cfset local.storageEngine = "ENGINE=InnoDB">
<cfelseif local.db IS "h2">
	<cfset local.identityColumnType = "int NOT NULL IDENTITY">
<cfelseif local.db IS "postgresql">
	<cfset local.identityColumnType = "SERIAL NOT NULL">
	<cfset local.dateTimeColumnType = "timestamp">
	<cfset local.binaryColumnType = "bytea">
	<cfset local.bitColumnType = "boolean">
	<cfset local.bitColumnDefault = "false">
</cfif>

<!--- get a listing of all the tables and view in the database --->
<cfdbinfo name="local.dbinfo" datasource="#application.wheels.dataSourceName#" type="tables">
<cfset local.tableList = ValueList(local.dbinfo.table_name, Chr(7))>

<!--- list of views to delete --->
<cfset local.views = "userphotos">
<cfloop list="#local.views#" index="local.i">
	<cfif ListFindNoCase(local.tableList, local.i, Chr(7))>
		<cftry>
			<cfquery name="local.query" datasource="#application.wheels.dataSourceName#">
			DROP VIEW #local.i#
			</cfquery>
			<cfcatch></cfcatch>
		</cftry>
	</cfif>
</cfloop>

<!--- list of tables to delete --->
<cfset local.tables = "authors,cities,classifications,comments,galleries,photos,posts,profiles,shops,trucks,tags,users,collisiontests,combikeys,tblusers,sqltypes,CATEGORIES,migratorversions">
<cfloop list="#local.tables#" index="local.i">
	<cfif ListFindNoCase(local.tableList, local.i, Chr(7))>
		<cftry>
			<cfquery name="local.query" datasource="#application.wheels.dataSourceName#">
			DROP TABLE #local.i#
			</cfquery>
			<cfcatch></cfcatch>
		</cftry>
	</cfif>
</cfloop>

<!--- create tables --->
<cfquery name="local.query" datasource="#application.wheels.dataSourceName#">
CREATE TABLE authors
(
	id #local.identityColumnType#
	,firstname varchar(100) NOT NULL
	,lastname varchar(100) NOT NULL
	,PRIMARY KEY(id)
) #local.storageEngine#
</cfquery>

<cfquery name="local.query" datasource="#application.wheels.dataSourceName#">
CREATE TABLE cities
(
	countyid char(4) NOT NULL
	,citycode #local.intColumnType# NOT NULL
	,name varchar(50) NOT NULL
	,PRIMARY KEY(countyid,citycode)
) #local.storageEngine#
</cfquery>

<cfquery name="local.query" datasource="#application.wheels.dataSourceName#">
CREATE TABLE classifications
(
	id #local.identityColumnType#
	,postid #local.intColumnType# NOT NULL
	,tagid #local.intColumnType# NOT NULL
	,PRIMARY KEY(id)
) #local.storageEngine#
</cfquery>

<cfquery name="local.query" datasource="#application.wheels.dataSourceName#">
CREATE TABLE collisiontests
(
	id #local.identityColumnType#
	,method varchar(100) NOT NULL
	,PRIMARY KEY(id)
) #local.storageEngine#
</cfquery>

<cfquery name="local.query" datasource="#application.wheels.dataSourceName#">
CREATE TABLE combikeys
(
	id1 int NOT NULL
	,id2 int NOT NULL
	,userId int NOT NULL
	,PRIMARY KEY(id1,id2)
) #local.storageEngine#
</cfquery>

<cfquery name="local.query" datasource="#application.wheels.dataSourceName#">
CREATE TABLE comments
(
	id #local.identityColumnType#
	,postid #local.intColumnType# NOT NULL
	,body #local.textColumnType# NOT NULL
	,name varchar(100) NOT NULL
	,url varchar(100) NULL
	,email varchar(100) NULL
	,createdat #local.datetimeColumnType# NOT NULL
	,PRIMARY KEY(id)
) #local.storageEngine#
</cfquery>

<cfquery name="local.query" datasource="#application.wheels.dataSourceName#">
CREATE TABLE galleries
(
	id #local.identityColumnType#
	,userid #local.intColumnType# NOT NULL
	,title varchar(255) NOT NULL
	,description #local.textColumnType# NOT NULL
	,PRIMARY KEY(id)
) #local.storageEngine#
</cfquery>

<cfquery name="local.query" datasource="#application.wheels.dataSourceName#">
CREATE TABLE photos
(
	id #local.identityColumnType#
	,galleryid #local.intColumnType# NOT NULL
	,filename varchar(255) NOT NULL
	,description varchar(255) NOT NULL
	,filedata #local.binaryColumnType# NULL
	,PRIMARY KEY(id)
) #local.storageEngine#
</cfquery>

<cfquery name="local.query" datasource="#application.wheels.dataSourceName#">
CREATE TABLE posts
(
	id #local.identityColumnType#
	,authorid #local.intColumnType# NULL
	,title varchar(250) NOT NULL
	,body #local.textColumnType# NOT NULL
	,createdat #local.datetimeColumnType# NOT NULL
	,updatedat #local.datetimeColumnType# NOT NULL
	,deletedat #local.datetimeColumnType# NULL
	,views #local.intColumnType# DEFAULT 0 NOT NULL
	,averagerating #local.floatColumnType# NULL
	,PRIMARY KEY(id)
) #local.storageEngine#
</cfquery>

<cfquery name="local.query" datasource="#application.wheels.dataSourceName#">
CREATE TABLE profiles
(
	id #local.identityColumnType#
	,authorid #local.intColumnType# NULL
	,dateofbirth #local.datetimeColumnType# NOT NULL
	,bio #local.textColumnType# NULL
	,PRIMARY KEY(id)
) #local.storageEngine#
</cfquery>

<cfquery name="local.query" datasource="#application.wheels.dataSourceName#">
CREATE TABLE shops
(
	shopid char(9) NOT NULL
	,citycode #local.intColumnType# NULL
	,name varchar(80) NOT NULL
	,PRIMARY KEY(shopid)
) #local.storageEngine#
</cfquery>

<!--- this table is for testing ambiguous column names (shopid) --->
<cfquery name="local.query" datasource="#application.wheels.dataSourceName#">
CREATE TABLE trucks
(
	id #local.identityColumnType#
	,shopid char(9) NOT NULL
	,registration varchar(80) NULL
	,PRIMARY KEY(id)
) #local.storageEngine#
</cfquery>

<cfquery name="local.query" datasource="#application.wheels.dataSourceName#">
CREATE TABLE sqltypes
(
	id #local.identityColumnType#
	,booleanType #local.bitColumnType# DEFAULT #local.bitColumnDefault# NOT NULL
	,binaryType #local.binaryColumnType# NULL
	,dateTimeType #local.datetimeColumnType# DEFAULT #PreserveSingleQuotes(local.dateTimeDefault)# NOT NULL
	,floatType #local.floatColumnType# DEFAULT 1.25 NULL
	,intType #local.intColumnType# DEFAULT 1 NOT NULL
	,stringType char(4) DEFAULT 'blah' NOT NULL
	,stringVariableType varchar(80) NOT NULL
	,textType #local.textColumnType# NOT NULL
	,PRIMARY KEY(id)
) #local.storageEngine#
</cfquery>

<cfquery name="local.query" datasource="#application.wheels.dataSourceName#">
CREATE TABLE tags
(
	id #local.identityColumnType#
	,parentid #local.intColumnType# NULL
	,name varchar(50) NULL
	,description varchar(50) NULL
	,PRIMARY KEY(id)
) #local.storageEngine#
</cfquery>

<cfquery name="local.query" datasource="#application.wheels.dataSourceName#">
CREATE TABLE tblusers
(
	id #local.identityColumnType#
	,username varchar(50) NOT NULL
	,password varchar(50) NOT NULL
	,firstname varchar(50) NOT NULL
	,lastname varchar(50) NOT NULL
	,address varchar(100) NULL
	,city varchar(50) NULL
	,state char(2) NULL
	,zipcode varchar(50) NULL
	,phone varchar(20) NULL
	,fax varchar(20) NULL
	,birthday #local.datetimeColumnType# NULL
	,birthdaymonth #local.intColumnType# NULL
	,birthdayyear #local.intColumnType# NULL
	,birthtime #local.datetimeColumnType# DEFAULT #PreserveSingleQuotes(local.dateTimeDefault)# NOT NULL
	,isactive #local.intColumnType# NULL
	,blank varchar(20) NULL
	,PRIMARY KEY(id)
) #local.storageEngine#
</cfquery>

<cfquery name="local.query" datasource="#application.wheels.dataSourceName#">
CREATE TABLE users
(
	id #local.identityColumnType#
	,username varchar(50) NOT NULL
	,password varchar(50) NOT NULL
	,firstname varchar(50) NOT NULL
	,lastname varchar(50) NOT NULL
	,address varchar(100) NULL
	,city varchar(50) NULL
	,state char(2) NULL
	,zipcode varchar(50) NULL
	,phone varchar(20) NULL
	,fax varchar(20) NULL
	,birthday #local.datetimeColumnType# NULL
	,birthdaymonth #local.intColumnType# NULL
	,birthdayyear #local.intColumnType# NULL
	,birthtime #local.datetimeColumnType# DEFAULT #PreserveSingleQuotes(local.dateTimeDefault)# NOT NULL
	,isactive #local.intColumnType# NULL
	,blank varchar(20) NULL
	,PRIMARY KEY(id)
) #local.storageEngine#
</cfquery>

<!--- specifically for testing uppercase table name containing OR substring --->
<cfquery name="local.query" datasource="#application.wheels.dataSourceName#">
CREATE TABLE CATEGORIES
(
	ID #local.identityColumnType#
	,CATEGORY_NAME varchar(100) NOT NULL
	,PRIMARY KEY(ID)
) #local.storageEngine#
</cfquery>

<!--- create views --->
<cfquery name="local.query" datasource="#application.wheels.dataSourceName#">
CREATE VIEW userphotos AS
SELECT u.id AS userid, u.username AS username, u.firstname AS firstname, u.lastname AS lastname, g.title AS title, g.id AS galleryid
FROM users u INNER JOIN galleries g ON u.id = g.userid
</cfquery>

<!--- populate with data --->
<cfset local.user = model("user").create(
	username = 'tonyp',
	password = 'tonyp123',
	firstname = 'Tony',
	lastname = 'Petruzzi',
	address = '123 Petruzzi St.',
	city = 'SomeWhere1',
	state = 'TX',
	zipcode = '11111',
	phone = '1235551212',
	fax = '4565551212',
	birthday = '11/01/1975',
	birthdaymonth = 11,
	birthdayyear = 1975,
	isactive = 1
)>

<cfset local.user = model("user").create(
	username = 'chrisp',
	password = 'chrisp123',
	firstname = 'Chris',
	lastname = 'Peters',
	address = '456 Peters Dr.',
	city = 'SomeWhere2',
	state = 'LA',
	zipcode = '22222',
	phone = '1235552323',
	fax = '4565552323',
	birthday = '10/05/1972',
	birthdaymonth = 10,
	birthdayyear = 1972,
	isactive = 1
)>

<cfset local.user = model("user").create(
	username = 'perd',
	password = 'perd123',
	firstname = 'Per',
	lastname = 'Djurner',
	address = '789 Djurner Ave.',
	city = 'SomeWhere3',
	state = 'CA',
	zipcode = '44444',
	phone = '1235554545',
	fax = '4565554545',
	birthday = '09/12/1973',
	birthdaymonth = 9,
	birthdayyear = 1973,
	isactive = 1
)>

<cfset local.user = model("user").create(
	username = 'raulr',
	password = 'raulr23',
	firstname = 'Raul',
	lastname = 'Riera',
	address = '987 Riera Blvd.',
	city = 'SomeWhere4',
	state = 'WI',
	zipcode = '55555',
	phone = '1235558989',
	fax = '4565558989',
	birthday = '06/14/1981',
	birthdaymonth = 6,
	birthdayyear = 1981,
	isactive = 1
)>

<cfset local.user = model("user").create(
	username = 'joeb',
	password = 'joeb',
	firstname = 'Joe',
	lastname = 'Blow',
	address = '123 Petruzzi St.',
	city = 'SomeWhere4',
	state = 'CA',
	zipcode = '22222',
	phone = '1235551212',
	fax = '4565554545',
	birthday = '11/12/1973',
	birthdaymonth = 11,
	birthdayyear = 1973,
	isactive = 1
)>

<cfset local.per = model("author").create(firstName = "Per", lastName = "Djurner")>
<cfset local.per.createProfile(dateOfBirth = "20/02/1975", bio = "ColdFusion Developer")>
<cfset local.per.createPost(title = "Title for first test post", body = "Text for first test post", views = 5)>
<cfset local.per.createPost(
	title = "Title for second test post",
	body = "Text for second test post",
	views = 5,
	averageRating = "3.6"
)>
<cfset local.per.createPost(
	title = "Title for third test post",
	body = "Text for third test post",
	averageRating = "3.2"
)>
<cfset local.tony = model("author").create(firstName = "Tony", lastName = "Petruzzi")>
<cfset local.tony.createPost(
	title = "Title for fourth test post",
	body = "Text for fourth test post",
	views = 3,
	averageRating = "3.6"
)>
<cfset local.tony.createPost(
	title = "Title for fifth test post",
	body = "Text for fifth test post",
	views = 2,
	averageRating = "3.6"
)>
<cfset local.chris = model("author").create(firstName = "Chris", lastName = "Peters")>
<cfset local.peter = model("author").create(firstName = "Peter", lastName = "Amiri")>
<cfset local.james = model("author").create(firstName = "James", lastName = "Gibson")>
<cfset local.raul = model("author").create(firstName = "Raul", lastName = "Riera")>
<cfset local.andy = model("author").create(firstName = "Andy", lastName = "Bellenie")>
<cfset local.adam = model("author").create(firstName = "Adam", lastName = "Chapman, Duke of Surrey")>
<cfset local.tom = model("author").create(firstName = "Tom", lastName = "King")>
<cfset local.david = model("author").create(firstName = "David", lastName = "Belanger")>

<cfset local.users = model("user").findAll(order = "id")>

<cfloop query="local.users">
	<cfloop from="1" to="5" index="local.i">
		<cfset local.gallery = model("gallery").create(
			userid = "#local.users.id#",
			title = "#local.users.firstname# Test Galllery #local.i#",
			description = "test gallery #local.i# for #local.users.firstname#"
		)>

		<cfloop from="1" to="10" index="local.i2">
			<cfset local.photo = model("photo").create(
				galleryid = "#local.gallery.id#",
				filename = "Gallery #local.gallery.id# Photo Test #local.i2#",
				description1 = "test photo #local.i2# for gallery #local.gallery.id#"
			)>
		</cfloop>
	</cfloop>
</cfloop>

<cfset model("user2").create(
	username = "Chris",
	password = "x",
	firstName = "x",
	lastName = "x"
)>
<cfset model("user2").create(
	username = "Tim",
	password = "x",
	firstName = "x",
	lastName = "x"
)>
<cfset model("user2").create(
	username = "Tom",
	password = "x",
	firstName = "x",
	lastName = "x"
)>

<!--- create a profile with an author --->
<cfset model("profile").create(dateOfBirth = "1/1/1970", bio = "Unknown Author")>

<cfset local.posts = model("post").findAll(order = "id")>

<cfloop query="local.posts">
	<cfloop from="1" to="3" index="local.i">
		<cfset local.comment = model("comment").create(
			postid = local.posts.id,
			body = "This is comment #local.i#",
			name = "some commenter #local.i#",
			url = "http://#local.i#.somecommenter.com",
			email = "#local.i#@#local.i#.com"
		)>
	</cfloop>
</cfloop>

<!--- cities and shops --->
<cfloop from="1" to="5" index="local.i">
	<cfset model("city").create(id = "3", citycode = "#local.i#", name = "county #local.i#")>

	<cfset model("shop").create(shopid = "shop#local.i#", citycode = "#local.i#", name = "shop #local.i#")>
</cfloop>
<!--- shop 1 has 5 trucks --->
<cfloop from="1" to="5" index="local.i">
	<cfset model("truck").create(shopid = "shop1", registration = "TRUCK-#local.i#")>
</cfloop>

<cfset model("shop").create(shopid = " shop6", citycode = 0, name = "x")>

<!--- tags --->
<cfset local.releases = model("tag").create(name = "releases", description = "testdesc")>
<cfset model("tag").create(name = "minor", description = "a minor release", parentid = 3)>
<cfset model("tag").create(name = "major", description = "a major release")>
<cfset model("tag").create(name = "point", description = "a point release", parentid = 2)>

<cfset local.fruit = model("tag").create(name = "fruit", description = "something to eat")>
<cfset model("tag").create(name = "apple", description = "ummmmmm good", parentid = local.fruit.id)>
<cfset model("tag").create(name = "pear", description = "rhymes with Per", parentid = local.fruit.id)>
<cfset model("tag").create(name = "banana", description = "peal it", parentid = local.fruit.id)>

<!--- classifications --->
<cfset model("classification").create(postid = 1, tagid = 7)>

<!--- collisiontests --->
<cfset model("collisiontest").create(method = "test")>

<!--- collisiontests --->
<cfloop from="1" to="5" index="i">
	<cfloop from="1" to="5" index="a">
		<cfset model("CombiKey").create(id1 = "#i#", id2 = "#a#", userId = "#a#")>
	</cfloop>
</cfloop>

<!--- sqltype --->
<cfset model("sqltype").create(stringVariableType = "tony", textType = "blah blah blah blah")>

<!--- assign posts for multiple join test --->
<cfset local.andy.update(favouritePostId = 1, leastFavouritePostId = 2)>

<!--- uppercase table --->
<cfset model("category").create(category_name = "Quick Brown Foxes")>
<cfset model("category").create(category_name = "Lazy Dogs")>
