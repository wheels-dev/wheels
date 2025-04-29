# Running Local Development Servers

### Starting a local development server

With CommandBox, we don't need to have Lucee or Adobe ColdFusion installed locally. With a simple command, we can make CommandBox go and get the CFML engine we've requested, and quickly create a server running on Undertow. Make sure you're in the root of your website, and then run:

{% tabs %}
{% tab title="CommandBox" %}
server start
{% endtab %}
{% endtabs %}

The server will then start on a random port on `127.0.0.1` based the configuration from the `server.json` file that is in the root of your application that comes with wheels. We can add various options to `server.json` to customize our server. Your default `server.json` will look something like this:

```json
{
    "name":"wheels",
    "web":{
        "host":"localhost",
        "webroot":"public",
        "rewrites":{
            "enable":true,
            "config":"public/urlrewrite.xml"
        }
    },
    "app":{
        "cfengine":"lucee"
    }
}
```

In this `server.json` file, the server name is set to `wheels`, meaning I can now start the server from any directory by simply calling `start myApp`. We don't have any port specified, but you can specify any port you want. Lastly, we have URL rewriting enabled and pointed the URL rewrite configuration file to `public/urlrewrite.xml`, which is included starting from Wheels 2.x.

#### Using custom host names

You can also specify hosts other than localhost: there's a useful CommandBox module to do that ([Host updater](https://www.forgebox.io/view/commandbox-hostupdater)) which will automatically create entries in your hosts file to allow for domains such as `myapp.local` running on port 80. You can install it via `install commandbox-hostupdater` when running the box shell with administrator privileges.

### Controlling local servers

Obviously, anything you start, you might want to stop. Servers can be stopped either via right/ctrl clicking on the icon in the taskbar, or by the `stop` command. To stop a server running in the current directory issue the following:

{% tabs %}
{% tab title="CommandBox" %}
server stop
{% endtab %}
{% endtabs %}

You can also stop a server from anywhere by using its name:

{% tabs %}
{% tab title="CommandBox" %}
server stop myApp
{% endtab %}
{% endtabs %}

If you want to see what server configurations exist on your system and their current status, simply do `server list`

{% tabs %}
{% tab title="CommandBox" %}
server list
{% endtab %}
{% endtabs %}

```shell-session
myapp (stopped)
 http://127.0.0.1:60000
 Webroot: /Users/wheels/Documents/myapp

myAPI (stopped)
 http://127.0.0.1:60010
 Webroot: /Users/wheels/Documents/myAPI

megasite (stopped)
 http://127.0.0.1:61280
 CF Engine: lucee 4.5.4+017
 Webroot: /Users/wheels/Documents/megasite

awesomesite (stopped)
 http://127.0.0.1:60015
 CF Engine: lucee 4.5.4+017
 Webroot: /Users/wheels/Documents/awesomeo
```

To remove a server configuration from the list, you can use `server forget myapp`. Note the status of the servers on the list are somewhat unreliable, as it only remembers the last known state of the server: so if you start a server and then turn off your local machine, it may still remember it as `running` when you turn your local machine back on, which is why we recommend the use of `force: true` in the `server.json` file.

### Specifying different CF engines

By default, CommandBox will run Lucee (version 6.x at time of writing). You may wish to specify an exact version of Lucee, or use Adobe ColdFusion. We can do this via either setting the appropriate `cfengine` setting in `server.json`, or at runtime with the `cfengine=` argument.

{% tabs %}
{% tab title="CommandBox" %}
_Start the default engine_

CommandBox> start

\_\_

_Start the latest stable Lucee 5.x engine_

CommandBox> start cfengine=lucee@5

\_\_

_Start a specific engine and version_

CommandBox> start cfengine=adobe@10.0.12

\_\_

_Start the most recent Adobe server that starts with version "11"_

CommandBox> start cfengine=adobe@11

\_\_

_Start the most recent adobe engine that matches the range_

CommandBox> start cfengine="adobe@>9.0 <=11"
{% endtab %}
{% endtabs %}

Or via `server.json`

```json
{
    "name":"myApp",
    "force":true,
    "web":{
        "http":{
            "host":"localhost",
            "port":60000
        },
        "rewrites":{
            "enable":true,
            "config":"urlrewrite.xml"
        }
    },
    "app":{
        "cfengine":"adobe@2018"
    },
}
```

{% hint style="info" %}
#### CFIDE / Lucee administrators

The default username and password for all administrators is `admin` & `commandbox`
{% endhint %}

You can of course run multiple servers, so if you need to test your app on Lucee 5.x, Lucee 6.x and Adobe 2018, you can just start three servers with different `cfengine=` arguments!

{% hint style="info" %}
#### Watch out

CommandBox 5.1 required to install dependencies easily
{% endhint %}

By default, the Lucee server that CommandBox starts includes all the essential Lucee extensions you need, but if need to minimize the size of the Lucee instance you launch, then you can use Lucee-Light by specifying `cfengine=lucee-light` in your `server.json` file. Wheels can run just fine on lucee-light (which is after all, Lucee, minus all the extensions) but at a minimum, requires the following extensions to be installed as dependencies in your `box.json`. Please note you may have to add any drivers you need for your database to this list as well.

```json
"dependencies":{
    "lucee-image":"lex:https://ext.lucee.org/lucee.image.extension-1.0.0.35.lex",
    "lucee-zip": "lex:https://ext.lucee.org/compress-extension-1.0.0.2.lex",
    "lucee-esapi": "lex:https://ext.lucee.org/esapi-extension-2.1.0.18.lex"
}
```

Once added to your box.json file, while the server is running, just do `box install`, which will install the dependencies, and load them into the running server within 60 seconds.

Alternatively you can download the extensions and add them manually to your server root's deploy folder (i.e `\WEB-INF\lucee-server\deploy`)
