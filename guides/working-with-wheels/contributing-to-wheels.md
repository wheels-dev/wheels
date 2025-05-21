---
description: >-
  Here are the rules of the road for contributing code to the project. Let's
  follow this process so that we don't duplicate effort and so the code base is
  easy to maintain over the long haul.
---

# Contributing to Wheels

## Repository

The official Git repository for Wheels is located at our [GitHub repository](https://github.com/cfwheels/cfwheels).

Anyone may fork the  `cfwheels` repository, make changes, and submit a pull request.

## Core Team Has Write Access

To make sure that we don't have too many chefs in the kitchen, we will be limiting direct commit access to a core team of developers.

At this time, the core team consists of these developers:

* [Peter Amiri](https://github.com/bpamiri)
* [Zain Ul Abideen](https://github.com/zainforbjs)

This does not restrict you from being able to contribute. See "Process for Implementing Code Changes" below for instructions on volunteering. With enough dedication, you can earn a seat on the core team as well!

## Process for Implementing Code Changes

Here's the process that we'd like for you to follow. This process is in place mainly to encourage everyone to communicate openly. This gives us the opportunity to have a great peer-review process, which will result in quality. Who doesn't like quality?

1. Open an issue in the [issue tracker](https://github.com/cfwheels/cfwheels/issues), outlining the changes or additions that you would like to make.
2. A member of the core team will review your submission and leave feedback if necessary.
3. Once the core team member is satisfied with the scope of the issue, they will indicate so in a comment to the issue. This is your green light to start working. Get to coding, grasshopper!
4. Need help or running across any issues while coding? Start a [Discussion](https://github.com/cfwheels/cfwheels/discussions).
5. When you have implemented your enhancement or change, use your Git repository to create a pull request with your changes.
   * You should annotate your commits with the issue number as `#55` if the code issue is `55`
6. A core team member will review it and post any necessary feedback in the issue tracker.
7. Once everything is resolved, a core team member will merge your commit into the Git repository.
8. If needed, open an issue to have the additions and changes in your revision documented in the [CHANGELOG](https://github.com/cfwheels/cfwheels/blob/main/CHANGELOG.md). You may claim the issue if you'd like to do this, but it's entirely your choice.

## Developing with Docker

CFWheels now includes a comprehensive Docker-based test environment that makes it easy to test your changes against multiple CFML engines and database platforms. For detailed instructions on using this environment, see:

- [Using the Test Environment](using-the-test-environment.md) - Complete guide to the Docker test environment
- [Submitting Pull Requests](submitting-pull-requests.md) - Step-by-step guide to creating and submitting PRs

## Code Style

All framework code should use the guidelines at [https://github.com/cfwheels/cfwheels/wiki/Code-Style-Guide](https://github.com/cfwheels/cfwheels/wiki/Code-Style-Guide). This will make things more readable and will keep everyone on the same page. If you're working on code and notice any violations of the official style, feel free to correct it!

Additionally, we recommend that any applications written using the Wheels framework follow the same style. This is optional, of course, but still strongly recommended.

## Supported CFML Engines

All code for Wheels should be written for use with both Adobe ColdFusion 2018 upwards, and Lucee 5 upwards.

## Naming Conventions

To stay true to our ColdFusion and Java roots, all names must be camelCase. In some cases, such as internal CFML functions, the first letter should be capitalized as well. Refer to these examples.

| Code Element          | Examples                               | Description                      |
| --------------------- | -------------------------------------- | -------------------------------- |
| CFC Names             | MyCfc.cfc, BlogEntry.cfc               | CapitalizedCamelCase             |
| Variable Names        | myVariable, storyId                    | camelCase                        |
| UDF Names             | myFunction()                           | camelCase                        |
| Built-in CF Variables | result.recordCount, cfhttp.fileContent | camelCase                        |
| Built-in CF Functions | IsNumeric(), Trim()                    | CapitalizedCamelCase             |
| Scoped Variables      | application.myVariable, session.userId | lowercase.camelCase              |
| CGI Variables         | cgi.remote\_addr, cgi.server\_name     | cgi.lowercase\_underscored\_name |

### CFC Conventions

#### Local Variables

Since moving to Wheels 2.x, the old `loc` scope has now been deprecated and you should use the function `local` scope.

Code Example

```javascript
// This is just for illustration. It's obviously a silly function.
function returnArrayLengthInWords(required array someArray) {
  local.rv = "Unknown";
  if (ArrayLen(arguments.someArray) > 50) {
    local.rv = "Pretty Long!";
  }
  if (ArrayLen(arguments.someArray) > 100) {
    local.rv = "Very Long!";
  }
  return local.rv;
}
```

#### CFC Methods

All CFC methods should be made public. If a method is meant for internal use only and shouldn't be included in the API, then prefix it with a dollar sign _**$**_. An example would be _**$query()**_.