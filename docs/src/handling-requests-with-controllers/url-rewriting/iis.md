---
description: URL rewriting instructions for IIS
---

# IIS

### Instructions for IIS 7

Similar to Apache, IIS 7 will pick up the rewrite rules from a file located in the Wheels installation. In the case of IIS 7, the rules are picked up by adding the following `web.config` file.&#x20;

This requires that the [URL Rewrite Module](http://www.iis.net/downloads/microsoft/url-rewrite) is installed. It's an IIS extension from Microsoft that you can download for free.

{% code title="web.config" %}
```
<?xml version="1.0" encoding="UTF-8"?>
<configuration>
    <system.webServer>
        <rewrite>
            <rules>
                <rule name="ColdFusion on Wheels URL Rewriting" enabled="true">
                    <match url="^(.*)$" ignoreCase="true" />
                    <conditions logicalGrouping="MatchAll">
                        <add input="{SCRIPT_NAME}" negate="true" pattern="^/(flex2gateway|jrunscripts|cf_scripts|cfide|CFFileServlet|cfformgateway|lucee|files|images|javascripts|miscellaneous|stylesheets|wheels/public/assets|robots.txt|favicon.ico|sitemap.xml|rewrite.cfm)($|/.*$)" />
                    </conditions>
                    <action type="Rewrite" url="/rewrite.cfm/{R:1}" />
                </rule>
            </rules>
        </rewrite>
    </system.webServer>
</configuration>
```
{% endcode %}

{% hint style="info" %}
#### Missing Lucee Assets?

If you had an issue with missing Lucee CSS files, try changing`{SCRIPT_NAME}`to`{PATH_INFO}`in the code above, as this reportedly can resolve the issue.
{% endhint %}

### Instructions for IIS 6

{% hint style="danger" %}
#### Deprecated

Please note that IIS6 was official End of Life as of 2015. These notes are included for historical purposes only.
{% endhint %}

Unfortunately, there is no built-in URL rewriting mechanism in IIS 6, so getting Wheels working with pretty URLs is a little more complicated than with Apache and IIS 7 (which often comes with the official "URL Rewrite Module" installed by default). Here's what you need to do:

* Download Ionic's [ISAPI Rewrite Filter](http://iirf.codeplex.com/). NOTE: the version must be v1.2.16 or later.
* Unzip the file, get the `IsapiRewrite4.dll` file from the lib folder and put it in the root of your website. (It needs to be in the same folder as the `IsapiRewrite4.ini` file.)
* To enable the rewrite filter in IIS 6, click on _Properties_ for your website, then go to the ISAPI Filters tab and click the _Add..._ button.
* Type in anything you want as the _Filter Name_ and point the Executable to the `IsapiRewrite4.dll` file.
* Uncomment the rewrite rules in the `IsapiRewrite4.ini` file.

**NOTE:** Make sure you have "Verify that file exists" disabled for your site.

* Right click your website and select _Properties_.
* Click Home _Directory_ tab.
* Click the _Configuration_ button.
* Under the Wildcard application mapping section, double-click path for the `jrun_iis6_wildcard.dll`.
* Uncheck _Verify that file exists_.
* Click _OK_ until all property screens are closed.
