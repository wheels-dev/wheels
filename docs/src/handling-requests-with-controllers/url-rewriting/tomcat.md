---
description: URL rewriting instructions for Tomcat
---

# Tomcat

### Using rewrite Valve

Tomcat 8 can be configured using `RewriteValve`. See [http://tonyjunkes.com/blog/a-brief-look-at-the-rewrite-valve-in-tomcat-8/](http://tonyjunkes.com/blog/a-brief-look-at-the-rewrite-valve-in-tomcat-8/) for examples.

### Instructions for UrlRewriteFilter

UrlRewriteFilter (commonly referred to as Tuckey) is a Java web filter for compliant web application servers such as Tomcat, Jetty, Resin and JBoss. Unfortunately UrlRewriteFilter depends on XML with its extremely strict syntax.

* First follow the ([install instructions on the UrlRewriteFilter website](http://tuckey.org/urlrewrite/#install)).
* Append the _servlet-mapping_ markup to the end of the `<filter mapping>` element in your `WEB-INF/web.xml`
* Add the _pretty urls rule_ markup to the `<urlrewrite>` element to your `WEB-INF/urlrewrite.xml` configuration.
* Restart the web application server.

Servlet-Mapping markup

{% code title="servlet-mapping" %}
```xml
<servlet-mapping>
  <servlet-name>CFMLServlet</servlet-name>
    <url-pattern>/rewrite.cfm/*</url-pattern>
</servlet-mapping>
```
{% endcode %}

Example markup with UrlRewriteFilter and Wheels pretty URLs for `WEB-INF/web.xml`.

{% code title="web.xml" %}
```xml
<filter>
    <filter-name>UrlRewriteFilter</filter-name>
    <filter-class>org.tuckey.web.filters.urlrewrite.UrlRewriteFilter</filter-class>
</filter>
<filter-mapping>
    <filter-name>UrlRewriteFilter</filter-name>
    <url-pattern>/*</url-pattern>
    <dispatcher>REQUEST</dispatcher>
    <dispatcher>FORWARD</dispatcher>
</filter-mapping>
<servlet-mapping>
  <servlet-name>CFMLServlet</servlet-name>
    <url-pattern>/rewrite.cfm/*</url-pattern>
</servlet-mapping>
```
{% endcode %}

Pretty URLs Rule markup

{% code title="pretty urls rule" %}
```xml
<rule enabled="true">
    <name>Wheels pretty URLs</name>
    <condition type="request-uri" operator="notequal">^/(flex2gateway|jrunscripts|cfide|cf_scripts|cfformgateway|cffileservlet|lucee|files|images|javascripts|miscellaneous|stylesheets|wheels/public/assets|robots.txt|favicon.ico|sitemap.xml|rewrite.cfm)</condition>
    <from>^/(.*)$</from>
    <to type="passthrough">/rewrite.cfm/$1</to>
  </rule>
```
{% endcode %}

A complete barebones `WEB-INF/urlrewrite.xml` configuration example with pretty URLs.

{% code title="urlrewrite.xml" %}
```xml
<?xml version="1.0" encoding="utf-8"?>
<!DOCTYPE urlrewrite
    PUBLIC "-//tuckey.org//DTD UrlRewrite 4.0//EN"
    "http://www.tuckey.org/res/dtds/urlrewrite4.0.dtd">

<urlrewrite>
  <rule enabled="true">
    <name>Wheels pretty URLs</name>
    <condition type="request-uri" operator="notequal">^/(flex2gateway|jrunscripts|cfide|cf_scripts|cfformgateway|cffileservlet|lucee|files|images|javascripts|miscellaneous|stylesheets|wheels/public/assets|robots.txt|favicon.ico|sitemap.xml|rewrite.cfm)</condition>
    <from>^/(.*)$</from>
    <to type="passthrough">/rewrite.cfm/$1</to>
  </rule>
</urlrewrite>
```
{% endcode %}
