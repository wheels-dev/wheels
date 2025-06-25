---
description: Making URLs prettier using URL rewriting.
---

# URL Rewriting

URL rewriting is a completely optional feature of Wheels, and all it does is get rid of the `index.cfm` part of the URL.

For example, with no URL rewriting, a URL in your application could look like this:

{% code title="HTTP" %}
```
http://localhost/index.cfm/blog/new
```
{% endcode %}

After turning on URL rewriting, it would look like this:

{% code title="HTTP" %}
```
http://localhost/blog/new
```
{% endcode %}

Combine this with the routing functionality of Wheels, and you get the capability of creating some really human-friendly (easier to remember, say over the phone, etc.) and search engine friendly (easier to crawl, higher PageRank, etc.) URLs.

Once you have added the rewrite rules (usually in either `.htaccess`, `web.config` or `urlrewrite.xml`), Wheels will try and determine if your web server is capable of rewriting URLs and turn it on for you automatically. Depending on what web server you have and what folder you run Wheels from, you may need to tweak things a little though. Follow these instructions below for details on how to set up your web server and customize the rewrite rules when necessary.

{% hint style="info" %}
#### Head's Up!

Since 2.x, engine specific URL rewrite files are not included in the default distribution. Don't worry - we've got you covered though!
{% endhint %}

For webserver specific instructions look at the following pages:

* [Apache](apache.md)
* [IIS](iis.md)
* [Tomcat](tomcat.md)
* [Nginx](nginx.md)

### Don't Forget to Restart

If you need to make changes to get URL rewriting to work, it's important to remember to always restart the web server and the ColdFusion server to make sure the changes are picked up by Wheels.

If you don't have access to restart services on your server, you can issue a `reload=true` request. It's often enough.
