<cfoutput>
<!DOCTYPE html>
<html lang="en">
  <head>
  	<meta charset="utf-8">
    <meta http-equiv="X-UA-Compatible" content="IE=edge">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <!-- The above 3 meta tags *must* come first in the head; any other head content must come *after* these tags -->
    <cfoutput>#csrfMetaTags()#</cfoutput>
    <title>|appName|</title>
    <meta name="description"            content="|appName|">
    <!--- Twitter Meta Data
    <meta name="twitter:creator"        content="" />
    <meta name="twitter:card"           content="" />
    <meta name="twitter:title"          content="" />
    <meta name="twitter:image:src"      content="" />
    <meta name="twitter:description"    content="" />
    --->
    <!--- Facebook Meta Data
    <meta property="og:site_name"       content="" />
    <meta property="og:url"             content="" />
    <meta property="og:title"           content="" />
    <meta property="og:image"           content="" />
    <meta property="og:description"     content="" />
    <meta property="og:type"            content="" />
    --->
	<!---=============== CSS ==============--->
    <!-- Bootstrap -->
    <!-- Latest compiled and minified CSS -->
    <link rel="stylesheet" href="https://maxcdn.bootstrapcdn.com/bootstrap/3.3.7/css/bootstrap.min.css" integrity="sha384-BVYiiSIFeK1dGmJRAkycuHAHRg32OmUcww7on3RYdg4Va+PmSTsz/K68vbdEjh4u" crossorigin="anonymous">

    <!-- Optional theme -->
    <link rel="stylesheet" href="https://maxcdn.bootstrapcdn.com/bootstrap/3.3.7/css/bootstrap-theme.min.css" integrity="sha384-rHyoN1iRsVXV4nD0JutlnGaslCJuC7uwjduW9SVrLvRYooPp2bWYgmgJQIXwl/Sp" crossorigin="anonymous">

    <!-- HTML5 shim and Respond.js IE8 support of HTML5 elements and media queries -->
    <!--[if lt IE 9]>
      <script src="https://oss.maxcdn.com/libs/html5shiv/3.7.0/html5shiv.js"></script>
      <script src="https://oss.maxcdn.com/libs/respond.js/1.4.2/respond.min.js"></script>
    <![endif]-->
	<link rel="shortcut icon" href="/favicon.ico">

  </head>
<body>
<!--[if lt IE 8]>
    <p class="browserupgrade">You are using an <strong>outdated</strong> browser. Please <a href="http://browsehappy.com/">upgrade your browser</a> to improve your experience.</p>
<![endif]-->
<!--=============== Header ==========-->
<header>
    <div class="container">
	   <h1 class="site-title">#linkTo(route="root", text="|appName|")#</h1>
    </div>
</header>
<!--=============== Content ==============-->
<div id="content" class="container">
    #flashMessages()#
	<section>
	    #includeContent()#
	</section>
</div>
<!--=============== Footer==============-->
<footer>

</footer>
<!---=============== JS ==============--->
#javascriptIncludeTag("https://ajax.googleapis.com/ajax/libs/jquery/1.12.4/jquery.min.js,https://maxcdn.bootstrapcdn.com/bootstrap/3.3.7/js/bootstrap.min.js")#
</body>
</html>
</cfoutput>
