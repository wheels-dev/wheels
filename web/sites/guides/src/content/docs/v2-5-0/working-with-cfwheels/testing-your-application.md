---
title: Testing Your Application
description: >-
  With CFWheels, writing automated tests for your application is part of the
  development lifecycle itself, and running the tests is as simple as clicking a
  link.
---

# Testing Your Application

### Why Test?

At some point, your code is going to break. Upgrades, feature enhancements, and bug fixes are all part of the development lifecycle. Quite often with deadlines, you don't have the time to test the functionality of your entire application with every change you make.

The problem is that today's fix could be tomorrow's bug. What if there were an automated way of checking if that change you're making is going to break something? That's where writing tests for your application can be invaluable.

In the past, writing test against your application meant downloading, configuring and learning a completely separate framework. This often caused more headaches than it was worth and was the reason why most developers didn't bother writing tests. With CFWheels, we've included a small and very simple testing framework based on [RocketUnit](https://github.com/robinhilliard/rocketunit) to help address just this issue.

### The Test Framework

Like everything else in CFWheels, the testing framework is very simple, yet powerful. You don't need to remember a hundred different functions because CFWheels' testing framework contains only a handful.

### Conventions

In order to run tests against your application, all tests must reside in the `tests` directory off the root of your CFWheels application, or within a subdirectory thereof.

When you run the tests for your application, CFWheels recursively scans your application's `tests` directory for valid tests. Whilst you have freedom to organize your subdirectories, tests and supporting files any way you see fit, we would recommend using the directory structure below as a guide:

```
tests/
├── functions/
├── requests/
```

{% hint style="info" %}
#### What are these directories for?

The "functions" directory might contain test packages that cover model methods, global or view helper functions.

The "requests" directory might contain test packages that cover controller actions and the output that they generate (views).
{% endhint %}

Any components that will contain tests must extend the `wheels.Test` component:

```java
component extends="wheels.Test" {
    // your tests here
}
```

If the testing framework sees that a component does not extend `wheels.Test`, that component will be skipped. This lets you create and store any mock components that you might want to use with your tests and keep everything together.

Any test methods must begin their name with "test":

```java
function testExpectedEqualsActual() {
    assert("true");
}
```

If a method does not begin with `test`, it is ignored and skipped. This lets you create as many helper methods for your testing components as you want.

Do not `var`-scope any variables used in your tests. In order for the testing framework to access the variables within the tests that you're writing, all variables need to be within the component's `variables` scope. The easy way to do this is to just not `var` variables within your tests, and your CFML engine will automatically assign these variables into the `variables` scope of the component for you. You'll see this in the examples below.

### Setup & Teardown

When writing a group of tests, it's common for there to be some duplicate code, global configuration, and/or cleanup needs that need to be run before or after each test. In order to keep things DRY (Don't Repeat Yourself), the testing framework offers 2 special methods that you can optionally use to handle such configuration.

`setup()`: Used to initialize or override any variables or execute any code that needs to be run _before each_ test.

`teardown()`: Used to clean up any variables or execute any code that needs to be ran _after each_ test.

Example:

```java
function setup() {
  _controller = controller(name="dummy");

  args = {
    fromTime=Now(),
    includeSeconds=true;
  };
}

function testWithSecondsBelow5Seconds() {
  number = 5 - 1;
  args.toTime = DateAdd("s", number, args.fromTime);
  actual = _controller.distanceOfTimeInWords(argumentCollection=args);
  expected = "less than 5 seconds";

  assert("actual eq expected");
}

function testWithSecondsBelow10Seconds() {
  number = 10 - 1;
  args.toTime = DateAdd("s", number, args.fromTime);
    actual = _controller.distanceOfTimeInWords(argumentCollection=args);
  expected = "less than 10 seconds";

  assert("actual eq expected");
}
```

### Evaluation

`assert()`: This is the main method that you will be using when developing tests. To use, all you have to do is provide a quoted expression. The power of this is that ANY 'truthy' expression can be used.

An example test that checks that two values equal each other:

```java
function testActualEqualsExpected() {
  actual = true;
  expected = true;
  assert("actual eq expected");
}
```

An example test that checks that the first value is less then the second value:

```java
function testOneIsLessThanFive() {
  one = 1;
  five = 5;
  assert("one lt five");
}
```

You get the idea since you've used these kinds of expressions a thousand times. If you think of the `assert()`command as another way of using `evaluate()`, it will all make sense. Remember that you can use any expression that evaluates to a boolean value, so if you can write assertions against structures, arrays, objects, you name it, you can test it!

An example test that checks that a key exists in a structure:

```java
function testKeyExistsInStructure() {
  struct = {
    foo="bar"
  };
  key = "foo";
  assert("StructKeyExists(struct, key)");
}
```

`raised()`: Used when you want to test that an exception will be thrown. `raised()` will raise and catch the exception and return to you the exception type (think `cfcatch.type`). Just like `assert()`, `raised()` takes a quoted expression as its argument.

An example of raising the `Wheels.TableNotFound` error when you specify an invalid model name:

```java
function testTableNotFound() {
  actual = raised("model('thisHasNoTable')");
  expected = "Wheels.TableNotFound";
  assert("actual eq expected");
}
```

### Debugging

`debug()`: Will display its output after the test result so you can examine an expression more closely.

`expression` (string) - a quoted expression to display\
`display` (boolean) - whether or not to display the output

{% hint style="info" %}
#### TIP

Overloaded arguments will be passed to the internal `cfdump` attributeCollection
{% endhint %}

```java
function testKeyExistsInStructure() {
  struct = {
    foo="bar"
  };
  key = "foo";

  // displaying the debug output
  debug("struct");

  // calling debug but NOT displaying the output
  debug("struct", false);

  // displaying the output of debug as text with a label
  debug(expression="struct", format="text", label="my struct");

  assert("StructKeyExists(struct, key)");
}
```

### Testing Your Models

The first part of your application that you are going to want to test against are your models because this is where all the business logic of your application lives. Suppose that we have the following model:

```java
component extends="Model" {
  public void function config() {
    // validation
    validate("checkUsernameDoesNotStartWithNumber")
    // callbacks
    beforeSave("sanitizeEmail");
  }

  /**
   * Check the username does not start with a number
   */
  private void function checkUsernameDoesNotStartWithNumber() {
    if (IsNumeric(Left(this.username, 1))) {
        addError(
        property="username",
        message="Username cannot start with a number."
      );
    }
  }

  /**
   * trim and force email address to lowercase before saving
   */
  private void function sanitizeEmail() {
      this.email = Trim(LCase(this.email));
  }
}
```

As you can see from the code above, our model has a `beforeSave` callback that runs whenever we save a user object. Let's get started writing some tests against this model to make sure that our callback works properly.

First, create a test component called `/tests/models/TestUserModel.cfc`, and in the `setup` function, create an instance of the model that we can use in each test that we write. We will also create a structure containing some default properties for the model.

```java
function setup() {
  // create an instance of our model
  user = model("user").new();

  // a structure containing some default properties for the model
  properties = {
      firstName="Hugh",
      lastName="Dunnit",
      email="hugh@example.com",
      username="myusername",
      password="foobar",
      passwordConfirmation="foobar"
  };
}
```

As you can see, we invoke our model by using the `model()` method just like you would normally do in your controllers.

The first thing we do is add a simple test to make sure that our custom model validation works.

```java
function testUserModelShouldFailCustomValidation() {
  // set the properties of the model
  user.setProperties(properties);
  user.username = "2theBatmobile!";

  // run the validation
  user.valid();

  actual = user.allErrors()[1].message;
  expected = "Username cannot start with a number.";

  // assert that the expected error message is generated
  assert("actual eq expected");
}
```

Now that we have tests to make sure that our model validations work, it's time to make sure that the callback works as expected when a valid model is created.

```java
function testSanitizeEmailCallbackShouldReturnExpectedValue() {
  // set the properties of the model
  user.setProperties(properties);
  user.email = " FOO@bar.COM ";

  /*
    Save the model, but use transactions so we don't actually write to
    the database. this prevents us from having to have to reload a new
    copy of the database every time the test runs.
  */
  user.save(transaction="rollback");

  // make sure that email address was sanitized
  assert('user.email eq "foo@bar.com"');
}
```

### Testing Your Controllers

The next part of our application that we need to test is our controller. Below is what a typical controller for our user model would contain for creating and displaying a list of users:

```javascript
component extends="Controller" {

  // users/index
  public void function index() {
    users = model("user").findAll();
  }

  // users/new
  public void function new() {
    user = model("user").new();
  }

  // users/create
  public any function create() {
    user = model("user").new(params.user);

    // Verify that the user creates successfully
    if (user.save()) {
      flashInsert(success="The user was created successfully.");
      // notice something about this redirectTo?
      return redirectTo(action="index");
    }
    else {
      flashInsert(error="There was a problem creating the user.");
      renderView(action="new");
    }
  }
}
```

Notice the `return` in the `create` action in the `redirectTo()` method? The reason for this is quite simple, under the covers, when you call `redirectTo()`, CFWheels is using `cflocation`. As we all know, there is no way to intercept or stop a `cflocation` from happening. This can cause quite a number of problems when testing out a controller because you would never be able to get back any information about the redirection.&#x20;

To work around this, the CFWheels test framework will "delay" the execution of a redirect until after the controller has finished processing. This allows CFWheels to gather and present some information to you about what redirection will occur.&#x20;

The drawback to this technique is that the controller will continue processing and as such we need to explicitly exit out of the controller action on our own, thus the reason why we use `return`.

Let's create a test package called `/tests/controllers/TestUsersController.cfc` to test that the `create` action works as expected:

```java
function testRedirectAndFlashStatus() {
  // define the controller, action and user params we are testing
  local.params = {
    controller="users",
    action="create",
    user={
      firstName="Hugh",
      lastName="Dunnit",
      email="hugh@somedomain.com",
      username="myusername",
      password="foobar",
      passwordConfirmation="foobar"
    }
    };

  // process the create action of the controller
  result = processRequest(params=local.params, method="post", returnAs="struct");

  // make sure that the expected redirect happened
  assert("result.status eq 302");
  assert("result.flash.success eq 'Hugh was created'");
  assert("result.redirect eq '/users/show/1'");

}
```

Notice that a lot more goes into testing a controller than a model. The first step is setting up the `params` that will need to be passed to the controller. We then pass the 'params' to the `processRequest()` function which returns a structure containing a bunch of useful information.

We use this information to make sure that the controller redirected the visitor to the `index` action once the action was completed.

**Note:** `processRequest()` is only for use within the test framework.

Below are some examples of how a controller can be tested:

```java
// asserts that a failed user update returns a 302 http response, an error exists in the flash and will be redirected to the error page
function testStatusFlashAndRedirect() {
  local.params = {
    controller = "users",
    action = "update"
  };
  result = processRequest(params=local.params, method="post", rollback=true, returnAs="struct");
  assert("result.status eq 302");
  assert("StructKeyExists(result.flash, 'error') eq true");
  assert("result.redirect eq '/common/error'");
}

// asserts that expected results are returned. Notice the update transactions is rolled back
function testStatusDatabaseUpdateEmailAndFlash() {
  local.params = {
    controller = "users",
    action = "update",
    key = 1,
    user = {
      name = "Hugh"
    }
  }
  transaction {

    result = processRequest(params=local.params, method="post", returnAs="struct");

    user = model("user").findByKey(1);
    transaction action="rollback";
  }
  assert("result.status eq 302");
  assert("user.name eq 'Hugh'");
  assert("result.emails[1].subject eq 'User was updated'");
  assert("result.flash.success eq 'User was updated'");
}

// asserts that an api request returns the expected JSON response
function testJsonApi() {
  local.params = {
    controller = "countries",
    action = "index",
    format = "json",
    route = "countries"
  };
  result = DeserializeJSON(processRequest(local.params)).data;
  assert("ArrayLen(result) eq 196");
}

// asserts that an API create method returns the expected result
function testJsonApiCreate() {
  local.params = {
    action = "create",
    controller = "users",
    data = {
      type = "users",
      attributes = {
        "first-name" = "Hugh",
        "last-name" = "Dunnit"
      }
    },
    format = "json",
    route = "users"
  };
  result = processRequest(params=local.params, returnAs="struct").status;
  assert("result.status eq 201");
}
```

### Testing Controller Variables

If you want to test a variable that's being set on a controller you can make use of the `this` scope. This way it's available from outside the controller, which makes it testable.

```javascript
this.employeeNumber = params.empNum;

// Then from your test...

local.controller = controller(...);
local.controller.processAction();
theValue = local.controller.employeeNumber;
```

If you think that's too "ugly", you can instead make a public function on the controller that returns the value and then call that from your tests.

### Testing Partials

You may at some point want to test a partial (usually called via `includePartial()`) outside of a request. You'll notice that if you just try and call `includePartial()` from within the test suite, it won't work. Thankfully there's a fairly easy technique you can use by calling a "fake" or "dummy" controller.

```javascript
component extends="tests.Test" {
    function setup() {
          params = {controller="dummy", action="dummy"};
          _controller = controller("dummy", params);
    }

    function testMyPartial(){
        result = _controller.includePartial(partial="/foo/bar/");
        assert("result CONTAINS 'foobar'");
    }
}
```

### Testing Your Views

Next we will look at testing the view layer. Below is the code for `new.cfm`, which is the view file for the controller's `new` action:

```html
<cfoutput>

<h1>Create a New user</h1>

#flashMessages()#

#errorMessagesFor("user")#

#startFormTag(route="users")#
    #textField(objectName='user', property='username')#
    #passwordField(objectName='user', property='password')#
    #passwordField(objectName='user', property='passwordConfirmation')#
    #textField(objectName='user', property='firstName')#
    #textField(objectName='user', property='lastName')#
    <p>
      #submitTag()# or
      #linkTo(text="Return to the listing", route="users")#
    </p>
#endFormTag()#

</cfoutput>
```

Testing the view layer is very similar to testing controllers, we will setup a params structure to pass to the `processRequest()` function which will return (among other things) the generated view output.&#x20;

Once we have this output, we can then search through it to make sure that whatever we wanted the view to display is presented to our visitor. In the test below, we are simply checking for the heading.

```java
function testUsersIndexContainsHeading() {

  local.params = {
    controller = "users",
    action = "index"
  };

  result = processRequest(params=local.params, returnAs="struct");

  assert("result.status eq 200");
  assert("result.body contains '<h1>Create a New user</h1>'");
}
```

### Testing Your Application Helpers

Next up is testing global helper functions. Below is a simple function that removes spaces from a string.

```java
// global/functions.cfm

public string function stripSpaces(required string string) {
    return Replace(arguments.string, " ", "", "all");
}
```

Testing these helpers is fairly straightforward. All we need to do is compare the function's return value against a value that we expect, using the `assert()` function.

```java
function testStripSpacesShouldReturnExpectedResult() {
    actual = stripSpaces(" foo   -   bar     ");
  expected = "foo-bar";
    assert("actual eq expected");
}
```

### Testing Your View Helpers

Testing your view helpers are very similar to testing application helpers except we need to explicitly include the helpers in the `setup()` function so our view functions are available to the test framework.

Below is a simple function that returns a string wrapped in `h1` tags.

```java
// views/helpers.cfm

public string function heading(required string text, string class="foo") {
    return '<h1 class="#arguments.class#">#arguments.text#</h1>';
}
```

And in our view test package:

```java
function setup() {
  // include our helper functions
  include "/views/helpers.cfm";
  text = "Why so serious?";
}

function testHeadingReturnsExpectedMarkup() {
  actual = heading(text=text);
  expected = '<h1 class="foo">#text#</h1>'
  assert("actual eq expected")
}

function testHeadingWithClassReturnsExpectedMarkup() {
  actual = heading(text=text, class="bar");
  expected = '<h1 class="bar">#text#</h1>'
  assert("actual eq expected")
}
```

### Testing Plugins

Testing plugins requires slightly different approaches depending on the `mixin` attribute defined in the plugin's main component.

Below is a simple plugin called `timeAgo` that extends CFWheels' `timeAgoInWords` view helper by appending "ago" to the function's return value. Take note of the `mixin="controller"` argument as this will play a part in how we test the plugin.

```java
component mixin="controller" {

    public any function init() {
        this.version = "2.0";
        return this;
    }

    /*
     * Append the term "ago" to the timeAgoInWords core function
     */
    public string function timeAgo() {
        return core.timeAgoInWords(argumentCollection=arguments) & " " & __timeAgoValueToAppend();
    }

    /*
     * Define the term to append to the main function
     */
    private string function __timeAgoValueToAppend() {
        return "ago";
    }
}
```

In order to test our plugin, we'll need to do a little setup. Our plugin's tests will reside in a directory within our plugin package named `tests`. We'll also need a directory to keep test assets, in this case a dummy controller that we will need to instantiate in out test's `setup()` function.

```
plugins/
├─ timeago/
    └─ TimeAgo.cfc
    └─ index.cfm
    └─ tests/
        └─ TestTimeAgo.cfc
        └─ assets/
            └─ controllers/
                └─ Dummy.cfc
```

The `/plugins/timeago/tests/assets/controllers/Dummy.cfc` controller contains the bare minimum for a controller.

```java
component extends="wheels.Controller" {
}
```

Firstly, in our `/plugins/timeago/tests/TestTimeAgo.cfc` we'll need to copy the application scope so that we can change some of CFWheels' internal paths. Fear not, we'll reinstate any changes after the tests have finished executing using the `teardown` function. so that if you're running your tests on your local development machine, your application will continue to function as expected after you're done testing.

Once the setup is done, we simply execute the plugin functions and assert that the return values are what we expect.&#x20;

```java
component extends="wheels.Test" {

    function setup() {
        // save the original environment
        applicationScope = Duplicate(application);
        // a relative path to our plugin's assets folder where we will store any plugin specific components and files
        assetsPath = "plugins/timeAgo/tests/assets/";
        // override wheels' path with our plugin's assets directory
        application.wheels.controllerPath = assetsPath & "controllers";
        // clear any plugin default values that may have been set
        StructDelete(application.wheels.functions, "timeAgo";
        // we're always going to need a controller for these tests so we'll just create a dummy
        _params = {controller="foo", action="bar"};
        dummyController = controller("Dummy", _params);
    }

    function teardown() {
        // reinstate the original application environment
        application = applicationScope;
    }

    // testing main public function
    function testTimeAgoReturnsExpectedValue() {
        actual = dummyController.timeAgo(fromTime=Now(), toTime=DateAdd("h", -1, Now()));
        expected = "About 1 hour ago";
        assert("actual eq expected");
    }

    // testing the 'private' function
    function testTimeAgoValueToAppendReturnsExpectedValue() {
        actual = dummyController.__timeAgoValueToAppend();
        expected = "ago";
        assert("actual eq expected");
    }
}
```

If your plugin is uses `mixin="model"`, you will need to create and instantiate a dummy model component.

### Running Your Tests

Down in the debug area of your CFWheels application (that grey area at the bottom of the page), you will notice a some links for running tests for the following areas:

**Run Tests** Runs all tests that you have created for your application. You should run these tests before deploying your application.

**View Tests** Shows a list of all your test packages with links to run individual packages or single tests.

**Framework Tests** If you have cloned the CFWheels repository, you will also see a link to run the core framework unit tests.

**Plugin Tests** If a plugin has a `/tests` directory, you will also see a link to run the plugin's tests.

The test URL will look something like this:\
`/index.cfm?controller=wheels&action=wheels&view=tests&type=app`

Running an individual package:\
`/index.cfm?controller=wheels&action=wheels&view=tests&type=app&package=controllers`

Running a single test:\
`/index.cfm?controller=wheels&action=wheels&view=tests&type=app&package=controllers&test=testCaseOne`

These URLs are useful should you want an external system to run your tests.

**Test Resuts Format**

CFWheels can return your test results in either HTML, JUnit or JSON formats, simply by using the `format` url parameter. Eg: `format=junit`

### Additional Techniques

Once you're comfortable with the concepts thus far, there are a few more functions available which can be used to modify the behavior of your test suite.

`beforeAll()` - Runs once before the test suite has run. Here is where you might populate a test database or set suite-specific application variables\*.

`afterAll()` - Runs once after the test suite has finished.

`packageSetup()` - Used in a test package, similar to `setup()` but only runs once before a package's first test case. Here is where you might set variables that are common to all the tests in a CFC.

`packageTeardown()` - Used in a test package, similar to `teardown()` but only runs once after a package's last test case. Here is where you might cleanup files, database rows created by test cases or revert application variables in a CFC.

A typical test request lifecycle will look something like this:

Test.cfc -`beforeAll()`

Foo.cfc - `packageSetup()`\
Foo.cfc - `setup()`\
Foo.cfc - `testCaseOne()`\
Foo.cfc - `teardown()`\
Foo.cfc - `setup()`\
Foo.cfc - `testCaseTwo()`\
Foo.cfc - `teardown()`\
Foo.cfc - `packageTeardown()`

Bar.cfc - `packageSetup()`\
Bar.cfc - `setup()`\
Bar.cfc - `testCaseThree()`\
Bar.cfc - `teardown()`\
Bar.cfc - `packageTeardown()`

Test.cfc - `afterAll()`

In order to use `beforeAll()` and `afterAll()`, you'll need to make a few small changes to your test suite. Firstly, create a `Test.cfc` in the root of your `/tests/` directory. This is where you'll define your `beforeAll()` and `afterAll()` functions and it should look something like this:

```javascript
component extends="wheels.Test" output=false {

  /*
   * Executes once before the test suite runs.
   */
  function beforeAll() {

  }

  /*
   * Executes once after the test suite runs.
   */
  function afterAll() {

  }

  /*
   * Executes before every tests case unless overridden in a package.
   */
  function setup() {

  }

  /*
   * Executes after every tests case unless overridden in a package.
   */
  function teardown() {

  }

}
```

For your test packages to inherit these functions, you'll need to change the `extends` attribute in your\
test packages to `extends="tests.Test"`. This enables the CFWheels test framework to run your functions.

Since we've implemented the new `Test.cfc` component, we now have global `setup()` and `teardown()` functions will run respectively before and after every test case. If we want to prevent these from running in a particular package, we simply override the global functions like this:

```java
function setup() {
  // your setup code
}

function teardown() {
  // your teardown code
}
```

If we want to run the global function AND some package-specific setup & teardown\
code, here's how achieve that:

```java
function setup() {
  super.setup();
  // your setup code
}

function teardown() {
  super.teardown();
  // your teardown code
}
```

Whilst best practice recommends that tests should be kept as simple and readable as possible, sometimes moving commonly used code into test suite helpers can greatly improve the simplicity of your tests.

Some examples may include, serializing complex values for use in `assert()` or grouping multiple assertions together. Whatever your requirements, there are a number of ways to use test helpers.

1. Put your helper functions in your `/tests/Test.cfc`.\
   These will be available to any package that extends this component. Be mindful of\
   functions you put in here, as it's easy to create naming collisions.
2. If you've arranged your tests into subdirectories, you can create a `helpers.cfm` file in any given\
   directory and simply include it in the package.
3. Put package-specific helper functions in the same package as the tests that use it.\
   These will only be available to the tests in that package. To ensure that these test helpers\
   are not run as tests, use a function name that doesn't start with "test\_". Eg: `$simplify()`

```java
component extends="tests.Test" {

  // 1. All functions in /tests/Test.cfc will be available

  // 2. Include a file containing helpers
  include "helpers.cfm";

  // 3. This is only available to this package
  function $simplify(required string string) {
    local.rv = Replace(arguments.string, " ", "", "all");
    local.rv = Replace(local.rv, Chr(13), "", "all");
    local.rv = Replace(local.rv, Chr(10), "", "all");
    return local.rv;
  }

}
```

* Overloading application vars.. CFWheels will revert the application scope after all tests have completed.

Caveat: The test suite request must complete without uncaught exceptions. If an uncaught exception occurs, the application scope may stay 'dirty', so it's recommended to reload the application by adding `reload=true` param to your url whilst developing your test packages.

### Learn By Example: CFWheels Core

The CFWheels core uses this test framework for its unit test suite and contains a wealth of useful examples. They can all be found in the [`tests` folder](https://github.com/cfwheels/cfwheels/tree/master/wheels/tests) of the CFWheels git repo.
