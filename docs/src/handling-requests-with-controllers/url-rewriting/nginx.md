---
description: URL Rewriting for Nginx web server.
---

# Nginx

Example Nginx configuration

```
# nginx configuration 
location ~ .*/(flex2gateway|jrunscripts|cfide|cf_scripts|cfformgateway|cffileservlet|railo-context|lucee|files|images|javascripts|miscellaneous|stylesheets|robots.txt|favicon.ico|sitemap.xml|rewrite.cfm)($|/.*$) { }

location / {
rewrite ^(.*)$ https://YOURDOMAIN.com/$1 redirect; 
rewrite ^/.*/index.cfm/(.*)$ /rewrite.cfm/$1 break; 
rewrite ^(.*)$ /rewrite.cfm/$1 break; 
}
```
