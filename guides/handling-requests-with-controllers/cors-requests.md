---
description: Configure Wheels to properly handle CORS requests
---

# CORS Requests

Wheels can often act as the "backend" in a modern web application, serving data to multiple types of frontend clients. Typically this would be in the form of (but not limited to) JSON served as an API, with something like VueJS or React on the front end, possibly served under a different domain.

When we separate our systems in such a manner, we need to consider CORS (Cross Origin Resource Sharing) and how to properly serve requests which modern browsers will allow.

### The "Quick and Dirty" approach

If you just need to satisfy your CORS requirement quickly, you can do so from Wheels 2.0 onwards with a simple configuration switch in your `/app/config/settings.cfm` file: `set(allowCorsRequests=true);`.

By default, this will enable the following CORS headers:

```
Access-Control-Allow-Origin 
*

Access-Control-Allow-Methods 
GET, POST, PATCH, PUT, DELETE, OPTIONS

Access-Control-Allow-Headers
Origin, Content-Type, X-Auth-Token, X-Requested-By, X-Requested-With
```

This will satisfy most requirements to get going quickly, but is more of a blanket "catch all" configuration which doesn't really restrict anything, or provide much information to the API consumer about your available resources.

### Custom CORS Headers

{% hint style="info" %}
#### From Wheels 2.1

The options below were introduced in Wheels 2.1
{% endhint %}

From Wheels 2.1, we can be more specific. We still need to specify `set(allowCorsRequests=true);` in our `/app/config/settings.cfm` to turn on the main CORS functionality, but we can now provide some additional configuration options to fine tune our responses.

### Access Control Allow Origin

The Access Control Allow Origin header tells the browser whether the domain they are connecting from can access the requested resource.

By default, this header is set to a wildcard allowing connection from any domain. But it might be your VueJS app lives at `app.domain.com` and we only want to allow access from that domain to our API.

```javascript
// Wildcard
set(accessControlAllowOrigin="*")

// Specify a domain
set(accessControlAllowOrigin="https://app.domain.com");

// Specify multiple domains in a list
set(accessControlAllowOrigin="https://app.domain.com,https://staging-app.domain.com");
```

You can also take advantage of the environment specific configurations, such as only allowing access to `localhost:8080` in `/app/config/development/settings.cfm` for example.

**Wheels 2.2** allows for subdomain wildcard matching for CORS permitted origins:

```javascript
// Match https://foo.domain.com or https://bar.domain.com or https://www.mydomain.com
set(accessControlAllowOrigin = [
  "https://*.domain.com",
  "https://www.mydomain.com"
]);
```

The CORS spec specifies that you are only allowed either a \* wildcard, or a specific URL , i.e [https://www.foo.com:8080](https://www.foo.com:8080/)- it doesn't in itself allow for wildcard subdomains. However in this scenario Wheels will attempt to match the wildcard and return the full matched domain.

### Access Control Allow Methods

The Access Control Allow Methods tells the browser what HTTP Methods (Verbs) are allowed to be performed against the requested resource.

By default these are set to be all possible Methods, `GET, POST, PATCH, PUT, DELETE, OPTIONS`. If our API only allows specific methods, we can specify them: note that this is application-wide and not dependent on route.

cfscript

```javascript
// Only ever allow GET requests to this API
set(accessControlAllowMethods="GET");

// Only ever allow GET, POST and OPTIONS
set(accessControlAllowMethods="GET,POST,OPTIONS");
```

### Access Control Allow Methods (By Route)

Whilst setting Access Control Allow Methods site-wide is fine, it doesn't actually fulfill the CORS requirement properly - the value returned by this header should indicate what methods are available at that url. For instance, `/cats` might only allow `GET,POST` requests, and `/cats/1/` might only allow `GET,PUT,PATCH,DELETE` requests.

Thankfully, we can pull this information in from the routing system automatically! Note, `set(accessControlAllowMethodsByRoute=true)` will override `set(accessControlAllowMethods())`

```javascript
// automatically look up the available routes in application.wheels.routes and return the valid methods for the requested route
set(accessControlAllowMethodsByRoute=true);
```

### Access Control Allow Credentials

If you're sending credentials such as a cookie from your front end application, you may need to turn this header on.

```javascript
// if set to true, include the Access-Control-Allow-Credentials header
set(accessControlAllowCredentials=true);
```

### Access Control Allow Headers

If you need to specify a specific list of allowed headers, you can simply pass them into this configuration setting

```javascript
// Set site wide allowed headers
set(accessControlAllowHeaders = "Origin, Content-Type, X-Auth-Token, X-Requested-By, X-Requested-With, X-MyHeader")
```
