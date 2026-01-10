# Localization

{% hint style="info" %}
#### Work in progress

This chapter is still being constructed...
{% endhint %}

### Page Encoding Issues

Generally speaking, if you try and add Unicode characters such as umlauts into templates, you may well come across display issues. This is easily fixable, but requires one of the following:

* For the template.cfm file to be saved in the correct encoding for the language being displayed
* Or use of the `cfprocessingdirective` tag to set `pageEncoding`

### Using cfprocessingdirective

{% code title="/app/views/main/example.cfm" %}
```html
<h1>Über uns</h1>
```
{% endcode %}

![Incorrect encoding example](https://files.readme.io/b18b015-umlaut\_1.png)![Incorrect encoding example](https://files.readme.io/b18b015-umlaut\_1.png)

Incorrect encoding example

{% code title="/app/views/main/example.cfm" %}
```html
<cfprocessingdirective pageEncoding="utf-8">
<h1>Über uns</h1>
```
{% endcode %}

![Correct encoding](https://files.readme.io/605ed49-umlaut\_2.png)![Correct encoding](https://files.readme.io/605ed49-umlaut\_2.png)

Correct encoding

Likewise, umlauts in routes would need for the `/config/routes.cfm` file to have the correct encoding:

{% code title="/config/routes.cfm" %}
```html
<cfprocessingdirective pageEncoding="utf-8">
<cfscript>
    mapper()
        .get(name="about", pattern="/über-uns", to="pages##about")
        .root(to="wheels##wheels", method="get")
    .end();
</cfscript>
```
{% endcode %}

### Using file encoding

If you're actively trying to avoid the use of `cfprocessingdirective`, you can resave the template or route file with `UTF-8-BOM`. Your local text editor should provide this facility; here's an example in Notepad++ (windows)

![](https://files.readme.io/7ee1953-umlaut\_3.png)![](https://files.readme.io/7ee1953-umlaut\_3.png)

### Localizing Wheels Helpers

// Example using monthNames args in dateSelect()\
Coming soon
