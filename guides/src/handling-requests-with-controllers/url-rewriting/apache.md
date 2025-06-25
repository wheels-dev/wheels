---
description: URL rewriting instructions for Apache
---

# Apache

### Instructions for Apache

First in your web.xml add the following servlet mapping above the default servlet mapping:

{% code title="web.xml" %}
```
 <!-- The mapping for rewriting -->
    <servlet-mapping>
        <servlet-name>CFMLServlet</servlet-name>
        <url-pattern>/rewrite.cfm/*</url-pattern>
    </servlet-mapping>
```
{% endcode %}

For this you can use the global web.xml that for instance can be found at: /opt/lucee/tomcat/conf/web.xml.
Or, if you are on shared hosting, use a local web.xml that for instance can be found at: yourwebroot/WEB-INF/web.xml.

After that use the following `.htaccess` file and Apache will pick up and use them automatically on server start-up.

Most of the time this will work. There are some exceptions though...

If you have installed Apache yourself you may need to turn on the rewrite module and/or change the security settings before URL rewriting will work:

* Check that the Apache `rewrite_module` has been loaded by ensuring there are no pound signs before the line that says `LoadModule rewrite_module modules/mod_rewrite.so` in the `httpd.conf` file.
* Make sure that Apache has permission to load the rewrite rules from the `.htaccess` file. This is done by setting `AllowOverride` to `All` under the Directory section corresponding to the website you plan on using Wheels on (still inside the `httpd.conf` file).

If you have an older version of Apache and you're trying to run your Wheels site in a sub folder of an existing site you may need to hard code the name of this folder in your rewrite rules.

* Change the last line of the `.htaccess` file to the following: `RewriteRule ^(.*)$ /sub_folder_name_goes_here/rewrite.cfm/$1 [L]`. Don't forget to change `sub_folder_name_goes_here` to the actual folder name first of course.

{% code title=".htaccess" %}
```
Options +FollowSymLinks
RewriteEngine On
RewriteCond %{REQUEST_URI} ^.*/index.cfm/(.*)$ [NC]
RewriteRule ^.*/index.cfm/(.*)$ ./rewrite.cfm/$1 [NS,L]
RewriteCond %{REQUEST_URI} !^.*/(flex2gateway|jrunscripts|cfide|cf_scripts|cfformgateway|cffileservlet|lucee|files|images|javascripts|miscellaneous|stylesheets|wheels/public/assets|robots.txt|favicon.ico|sitemap.xml|rewrite.cfm)($|/.*$) [NC]
RewriteRule ^(.*)$ ./rewrite.cfm/$1 [NS,L]
```
{% endcode %}

Note that it's often considered better practice to include this URL rewriting configuration at the `<virtualhost>` block level, but get it working with a `.htaccess` file first.
