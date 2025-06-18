---
description: >-
  With Wheels, writing automated tests for your application is part of the
  development lifecycle itself, and running the tests is as simple as clicking a
  link.
---

# Testing Your Application

### Why Test?

At some point, your code is going to break. Upgrades, feature enhancements, and bug fixes are all part of the development lifecycle. Quite often with deadlines, you don't have the time to test the functionality of your entire application with every change you make.

The problem is that today's fix could be tomorrow's bug. What if there were an automated way of checking if that change you're making is going to break something? That's where writing tests for your application can be invaluable.

For testing your application in Wheels 3.0, we use [TestBox](https://github.com/Ortus-Solutions/TestBox) as the testing framework. TestBox comes bundled with Wheels and provides a modern BDD (Behavior Driven Development) testing experience.

### The Test Framework

TestBox is a powerful testing framework that provides:
- BDD and xUnit style testing syntax
- Built-in assertions and expectations library
- MockBox for mocking and stubbing
- Code coverage reporting
- Parallel test execution
- Multiple output formats (HTML, JSON, JUnit, TAP)

Wheels extends TestBox with framework-specific features through the `BaseSpec.cfc` class, providing helpers for testing models, controllers, and views.

### Conventions

In Wheels 3.0, tests reside in the `tests/` directory off the root of your application. The recommended directory structure is:

```
tests/
├── BaseSpec.cfc          # Base test class with Wheels helpers
├── runner.cfm            # Web-based test runner
├── specs/                # Test specifications
│   ├── unit/            # Isolated unit tests
│   ├── integration/     # Integration tests
│   └── functional/      # End-to-end tests
├── fixtures/            # Test data and fixtures
└── support/             # Test utilities
    └── factories/       # Test data factories
```

{% hint style="info" %}
#### Directory Organization

- **unit/**: Tests for individual components in isolation (models, helpers)
- **integration/**: Tests that verify multiple components work together
- **functional/**: End-to-end tests that simulate user interactions
- **fixtures/**: Static test data files
- **support/factories/**: Dynamic test data generators
{% endhint %}

All test components should extend the `tests.BaseSpec` component (which extends TestBox's BaseSpec):

```java
component extends="tests.BaseSpec" {
    // your tests here
}
```

The Wheels BaseSpec provides additional helpers for testing:
- **Transaction rollback**: All tests run in transactions that automatically roll back
- **Model helpers**: `model()`, `create()`, `build()`, `createList()`
- **Controller helpers**: `controller()`, `processRequest()`, `apiRequest()`
- **Authentication helpers**: `loginAs()`, `logout()`, `isLoggedIn()`
- **Assertion helpers**: `assertHasErrors()`, `assertFieldValueEquals()`

You can write a test method with the following syntax:

```java
it("Result is True", () => {
  result = true
	expect(result).toBeTrue()
})
```

You also have to write your test methods inside the describe method like the following:

```java
describe("Tests that return True", () => {
  it("Result is True", () => {
    result = true
    expect(result).toBeTrue()
  })
})
```

Using the `describe` method lets you bundle your tests inside a file. This way, you can have mutiple bundles inside a single file. You can name your tests and your bundles anything you want inside the "" but for convention's sake, you should start your bundles name with "Tests".

if you want any helper methods for your tests, you can write them outside all the describe methods in your file.

Do not `var`-scope any variables used in your tests. In order for the testing framework to access the variables within the tests that you're writing, all variables need to be within the component's `variables` scope. The easy way to do this is to just not `var` variables within your tests, and your CFML engine will automatically assign these variables into the `variables` scope of the component for you. You'll see this in the examples below.

### Setup & Teardown

When writing a group of tests, it's common for there to be some duplicate code, global configuration, and/or cleanup needs that need to be run before or after each test. In order to keep things DRY (Don't Repeat Yourself), the TestBox offers 2 special methods that you can optionally use to handle such configuration.

`beforeEach(() => {})`: Used to initialize or override any variables or execute any code that needs to be run _before each_ test.

`afterEach(() => {})`: Used to clean up any variables or execute any code that needs to be ran _after each_ test.

Example:

```java
beforeEach(() => {
  _controller = controller(name="dummy")

  args = {
    fromTime=Now(),
    includeSeconds=true;
  }
})

it("works with seconds below 5 seconds", () => {
	number = 5 - 1
	args.toTime = DateAdd('s', number, args.fromTime)
	actual = _controller.distanceOfTimeInWords(argumentCollection = args)

	expect(actual).toBe("less than 5 seconds")
})

it("works with seconds below 10 seconds", () => {
	number = 10 - 1
	args.toTime = DateAdd('s', number, args.fromTime)
	actual = _controller.distanceOfTimeInWords(argumentCollection = args)

	expect(actual).toBe("less than 10 seconds")
})
```

### Evaluation

`expect().toBe()`: This is the main method that you will be using when developing tests. You can use this to compare the result of an operation with a value that you expect the operation to return. Let's say you have the result of an operation stored in a variable `result` and you expect the result to be "run completed" then you can check if the result is indeed returning that value by doing `expect(result).toBe("run completed")`.

An example test that checks that two values equal each other:

```java
it("actual equals expected", () => {
  actual = true
  expected = true
  expect(actual).toBe(expected)
})
```

```java
it("actual equals expected", () => {
  actual = true
  expect(actual).toBeTrue()
})
```

Either of the above will work. The `toBe()` method compares the value in `expect()` to the expected value, while `toBeTrue()` checks if the value in `expect()` is true. Another simple method is `toBeFalse()`, which checks if the value in `expect()` is false.

An example test that checks that the first value is less then the second value:

```java
it("one is less than five", () => {
  one = 1
  five = 5
  expect(one).toBeLT(five)
})
```

You get the idea since you've used these kinds of expressions a thousand times. You can compare structures, arrays, objects, you name it!

An example test that checks that a key exists in a structure:

```java
it("key exists in structure", () => {
  struct = {
    foo="bar"
  }
  key = "foo"
  expect(struct).toHaveKey(key)
})
```

When you want to test if an exception will be thrown, you can use the `try{}catch{}` to test for it. An example of raising the `Wheels.TableNotFound` error when you specify an invalid model name:

```java
it("Table not found", () => {
	try {
		model('thisHasNoTable')
		$assert.fail("Wheels.TableNotFound error did not occur.")
	} catch (any e) {
		type = e.Type
		expect(type).toBe("Wheels.TableNotFound")
	}
})
```

### Debugging

`debug()`: Will display its output after the test result so you can examine an expression more closely.

`expression` (string) - a quoted expression to display\
`label` (string) - Attach a label to the expression

{% hint style="info" %}
#### TIP

Overloaded arguments will be passed to the internal `cfdump` attributeCollection
{% endhint %}

```java
it("key exists in structure", () => {
  struct = {
    foo="bar"
  }
  key = "foo"

  // displaying the debug output
  debug("struct")

  // displaying the output of debug with a label
  debug("struct", "my struct")

  expect(struct).toHaveKey(key)
})
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

First, create a test component called `/tests/Testbox/specs/models/TestUserModel.cfc`, and in the `beforeEach` function, create an instance of the model that we can use in each test that we write. We will also create a structure containing some default properties for the model.

```java
beforeEach(() => {
  // create an instance of our model
  user = model("user")

  // a structure containing some default properties for the model
  properties = {
      firstName="Hugh",
      lastName="Dunnit",
      email="hugh@example.com",
      username="myusername",
      password="foobar",
      passwordConfirmation="foobar"
  }
  
  // Alternative: Use factories for test data
  // user = build("user")  // Creates but doesn't save
  // user = create("user") // Creates and saves
})
```

As you can see, we invoke our model by using the `model()` method just like you would normally do in your controllers.

The first thing we do is add a simple test to make sure that our custom model validation works.

```java
it("user model should fail custom validation", () => {
  // set the properties of the model
  user.setProperties(properties)
  user.username = "2theBatmobile!"

  // run the validation
  user.valid()

  actual = user.allErrors()[1].message
  expected = "Username cannot start with a number."

  // check that the expected error message is generated
  expect(actual).toBe(expected)
})
```

Now that we have tests to make sure that our model validations work, it's time to make sure that the callback works as expected when a valid model is created.

```java
it("sanitize email callback should return expected value", () => {
  // set the properties of the model
  user.setProperties(properties)
  user.email = " FOO@bar.COM "

  /*
    Save the model, but use transactions so we don't actually write to
    the database. this prevents us from having to have to reload a new
    copy of the database every time the test runs.
  */
  user.save(transaction="rollback")

  // make sure that email address was sanitized
  expect(user.email).toBe("foo@bar.com")
})
```

### Testing Your Controllers

The next part of our application that we need to test is our controller. Below is what a typical controller for our user model would contain for creating and displaying a list of users:

```javascript
component extends="Controller" {

  // users/index
  public void function index() {
    users = model("user").findAll()
  }

  // users/new
  public void function new() {
    user = model("user").new()
  }

  // users/create
  public any function create() {
    user = model("user").new(params.user)

    // Verify that the user creates successfully
    if (user.save()) {
      flashInsert(success="The user was created successfully.")
      // notice something about this redirectTo?
      return redirectTo(action="index")
    }
    else {
      flashInsert(error="There was a problem creating the user.")
      renderView(action="new")
    }
  }
}
```

Notice the `return` in the `create` action in the `redirectTo()` method? The reason for this is quite simple, under the covers, when you call `redirectTo()`, Wheels is using `cflocation`. As we all know, there is no way to intercept or stop a `cflocation` from happening. This can cause quite a number of problems when testing out a controller because you would never be able to get back any information about the redirection.&#x20;

To work around this, the Wheels test framework will "delay" the execution of a redirect until after the controller has finished processing. This allows Wheels to gather and present some information to you about what redirection will occur.&#x20;

The drawback to this technique is that the controller will continue processing and as such we need to explicitly exit out of the controller action on our own, thus the reason why we use `return`.

Let's create a test package called `/tests/Testbox/specs/controllers/TestUsersController.cfc` to test that the `create` action works as expected:

```java
it("redirect and flash status", () => {
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
    }

  // process the create action of the controller
  result = processRequest(params=local.params, method="post", returnAs="struct")

  // make sure that the expected redirect happened
  expect(result.status).toBe(302)
	expect(result.flash.success).toBe('The user was created successfully.')
	expect(result.redirect).toBe('/users/show/1')

})
```

Notice that a lot more goes into testing a controller than a model. The first step is setting up the `params` that will need to be passed to the controller. We then pass the 'params' to the `processRequest()` function which returns a structure containing a bunch of useful information.

We use this information to make sure that the controller redirected the visitor to the `index` action once the action was completed.

**Note:** `processRequest()` is only for use within the test framework.

Below are some examples of how a controller can be tested:

```java
// checks that a failed user update returns a 302 http response, an error exists in the flash and will be redirected to the error page
it("status flash and redirect", () => {
  local.params = {
    controller = "users",
    action = "update"
  }
  result = processRequest(params=local.params, method="post", rollback=true, returnAs="struct")
  expect(result.status).toBe(302)
  expect(result.flash).toHaveKey(error)
  expect(result.redirect).toBe('/common/error')
})

// checks that expected results are returned. Notice the update transactions is rolled back
it("status database update email and flash", () => {
  local.params = {
    controller = "users",
    action = "update",
    key = 1,
    user = {
      name = "Hugh"
    }
  }
  transaction {

    result = processRequest(params=local.params, method="post", returnAs="struct")

    user = model("user").findByKey(1)
    transaction action="rollback"
  }
  expect(result.status).toBe(302)
  expect(user.name).toBe('Hugh')
  expect(result.emails[1].subject).toBe('User was updated')
  expect(result.flash.success).toBe('User was updated')
})

// checks that an api request returns the expected JSON response
it("Test Json API", () => {
  local.params = {
    controller = "countries",
    action = "index",
    format = "json",
    route = "countries"
  }
  result = DeserializeJSON(processRequest(local.params)).data
  expect(result).toHaveLength(196)
})

// checks that an API create method returns the expected result
it("Test Json API create", () => {
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
  }
  result = processRequest(params=local.params, returnAs="struct").status;
  expect(result.status).toBe(201)
})
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
component extends="testbox.system.BaseSpec" {
    beforeEach(() => {
      params = {controller="dummy", action="dummy"}
      _controller = controller("dummy", params)
    })

    it("Test my partial", () => {
      result = _controller.includePartial(partial="/foo/bar/")
      expect(result).toInclude('foobar')
    })
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
it("users index contains heading", () => {

  local.params = {
    controller = "users",
    action = "index"
  }

  result = processRequest(params=local.params, returnAs="struct")

  expect(result.status).toBe(200)
  expect(result.body).toHave('<h1>Create a New user</h1>')
})
```

### Testing Your Application Helpers

Next up is testing global helper functions. Below is a simple function that removes spaces from a string.

```java
// app/global/functions.cfm

public string function stripSpaces(required string string) {
    return Replace(arguments.string, " ", "", "all");
}
```

Remember to restart your application after adding a helper function to use it afterwards.

Testing these helpers is fairly straightforward. All we need to do is compare the function's return value against a value that we expect, using the `assert()` function.

```java
it("stripSpaces should return expected result", () => {
    actual = stripSpaces(" foo   -   bar     ")
    expected = "foo-bar"
    expect(actual).toBe(expected)
})
```

### Testing Your View Helpers

Testing your view helpers are very similar to testing application helpers except we need to explicitly include the helpers in the `beforeEach` function so our view functions are available to the test framework.

Below is a simple function that returns a string wrapped in `h1` tags.

```java
// app/views/helpers.cfm

public string function heading(required string text, string class="foo") {
    return '<h1 class="#arguments.class#">#arguments.text#</h1>';
}
```

And in our view test package:

```java
beforeEach(() => {
  // include our helper functions
  include "/app/views/helpers.cfm"
  text = "Why so serious?"
})

it("heading returns expected markup", () => {
  actual = heading(text=text)
  expected = '<h1 class="foo">#text#</h1>'
  expect(actual).toBe(expected)
})

it("heading with class returns expected markup", () => {
  actual = heading(text=text, class="bar")
  expected = '<h1 class="bar">#text#</h1>'
  expect(actual).toBe(expected)
})
```

### Testing Plugins

Testing plugins requires slightly different approaches depending on the `mixin` attribute defined in the plugin's main component.

Below is a simple plugin called `timeAgo` that extends Wheels' `timeAgoInWords` view helper by appending "ago" to the function's return value. Take note of the `mixin="controller"` argument as this will play a part in how we test the plugin.

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

In order to test our plugin, we'll need to do a little setup. Our plugin's tests will reside in a directory within our plugin package named `tests`. We'll also need a directory to keep test assets, in this case a dummy controller that we will need to instantiate in our test's `beforeEach()` function.

```
app/
├─ plugins/
   └─ timeago/
      └─ TimeAgo.cfc
      └─ index.cfm
      └─ tests/
          └─ TestTimeAgo.cfc
          └─ assets/
              └─ controllers/
                  └─ Dummy.cfc
```

The `/app/plugins/timeago/tests/assets/controllers/Dummy.cfc` controller contains the bare minimum for a controller.

```java
component extends="wheels.Controller" {
}
```

Firstly, in our `/app/plugins/timeago/tests/TestTimeAgo.cfc` we'll need to copy the application scope so that we can change some of Wheels' internal paths. Fear not, we'll reinstate any changes after the tests have finished executing using the `AfterEach()` function. so that if you're running your tests on your local development machine, your application will continue to function as expected after you're done testing.

Once the setup is done, we simply execute the plugin functions and check using `expect()` function that the return values are what we expect.&#x20;

```java
component extends="testbox.system.BaseSpec" {

	function run() {
		describe("Tests that timeAgo", () => {

			beforeEach(() => {
				// save the original environment
				applicationScope = Duplicate(application)
				// a relative path to our plugin's assets folder where we will store any plugin specific components and files
				assetsPath = "app/plugins/timeAgo/tests/assets/"
				// override wheels' path with our plugin's assets directory
				application.wheels.controllerPath = assetsPath & "controllers"
				// clear any plugin default values that may have been set
				StructDelete(application.wheels.functions, "timeAgo")
				// we're always going to need a controller for these tests so we'll just create a dummy
				_params = {controller="foo", action="bar"}
				dummyController = controller("Dummy", _params)
			})

			afterEach(() => {
				// reinstate the original application environment
				application = applicationScope;
			})

			// testing main public function
			it("timeAgo returns expected value", () => {
				actual = dummyController.timeAgo(fromTime=Now(), toTime=DateAdd("h", -1, Now()))
				expected = "About 1 hour ago"
				expect(actual).toBe(expected)
			})

			// testing the 'private' function
			it("timeAgo value to append returns expected value", () => {
				actual = dummyController.__timeAgoValueToAppend()
				expected = "ago"
				expect(actual).toBe(expected)
			})

		})
	}
}
```

If your plugin is uses `mixin="model"`, you will need to create and instantiate a dummy model component.

### Running Your Tests

Wheels provides multiple ways to run your tests:

#### Command Line (Recommended)

```bash
# Run all tests
wheels test run

# Run specific directory
wheels test run --directory=tests/specs/unit

# Watch mode for TDD
wheels test run --watch

# Run with coverage
wheels test run --coverage

# Run specific test bundles
wheels test run --testBundles=models

# Generate coverage report
wheels test coverage
```

#### Using TestBox CLI directly

```bash
# Run all tests
box testbox run

# Run specific directory
box testbox run --directory=tests/specs/unit

# Watch mode
box testbox watch

# With coverage
box testbox run --coverage --coverageReporter=html
```

#### Web Runner

You can also run tests through the web interface:

- Visit `/tests/runner.cfm` for an interactive HTML interface
- The test runner supports various URL parameters:
  - `testBundles=controllers` - Run specific test bundles
  - `testSpecs=testCaseOne` - Run specific test specs
  - `reporter=json` - Change output format (html, json, junit, tap, simple, text)
  - `coverage=true` - Enable code coverage

#### Legacy Method

The legacy test runner is still available through the navbar menu for backward compatibility:
- Click on the `Testbox` button in your navbar
- Choose between `App Tests` and `Core Tests`
- Select your desired output format (HTML, JSON, TXT, JUnit)

**Note**: We recommend using the newer CLI commands for better performance and features.

#### Migrating from RocketUnit

If you have existing RocketUnit tests, use the migration tool:

```bash
# Migrate a single file
wheels test migrate path/to/test.cfc

# Migrate all tests
wheels test migrate tests --recursive

# Preview changes without modifying files
wheels test migrate tests --dry-run
```

### Running Tests with Docker

Wheels provides a comprehensive Docker-based testing environment that allows you to run tests across multiple CFML engines and databases simultaneously. This is especially useful for ensuring compatibility across different environments.

#### Using the TestUI

The easiest way to run tests in Docker is through the TestUI, which provides a modern web interface for managing tests:

```bash
# From the Wheels root directory
docker compose --profile ui up -d
```

Then navigate to http://localhost:3000 to access the TestUI.

**TestUI Features:**
- **Visual Test Runner**: See test results in real-time with detailed error information
- **Container Management**: Start stopped containers directly from the UI by clicking on them
- **Pre-flight Checks**: Automatic verification that required services are running before tests
- **Multi-Engine Testing**: Run tests across Lucee 5/6 and Adobe ColdFusion 2018/2021/2023
- **Multi-Database Support**: Test against MySQL, PostgreSQL, SQL Server, H2, and Oracle
- **Test History**: View previous test runs and results

#### Running Tests Across Different Databases

The Docker setup includes multiple database configurations. You can run tests against different databases by appending the `db` parameter:

- `db=mysql` - MySQL database
- `db=postgres` - PostgreSQL database  
- `db=sqlserver` - Microsoft SQL Server
- `db=h2` - H2 embedded database (Lucee only)
- `db=oracle` - Oracle database (requires additional setup)

Example URLs:
```
http://localhost:60005/wheels/testbox?format=json&db=mysql
http://localhost:60005/wheels/testbox?format=json&db=postgres
```

#### Docker Profiles

The Docker Compose setup uses profiles to organize containers:

- `ui`: TestUI and API server
- `lucee`: All Lucee engines
- `adobe`: All Adobe ColdFusion engines
- `db`: All database containers
- `quick-test`: Minimal setup (Lucee 5 + MySQL)
- `all`: All containers

Start specific profiles:
```bash
# Just the UI
docker compose --profile ui up -d

# Lucee engines with databases
docker compose --profile lucee --profile db up -d

# Everything
docker compose --profile all up -d
```

#### Container Management from TestUI

The TestUI includes an API server that allows you to start Docker containers directly from the web interface:

1. Click on any stopped engine or database in the dashboard
2. Confirm that you want to start the service
3. The container will start automatically
4. Status updates appear in real-time

This eliminates the need to use the terminal for basic container management tasks.

### Additional Techniques

Whilst best practice recommends that tests should be kept as simple and readable as possible, sometimes moving commonly used code into test suite helpers can greatly improve the simplicity of your tests.

Some examples may include, serializing complex values for use in `assert()` or grouping multiple assertions together. Whatever your requirements, there are a number of ways to use test helpers.

1. Put your helper functions in your `/tests/Testbox/Test.cfc`.\
   These will be available to any package that extends this component. Be mindful of\
   functions you put in here, as it's easy to create naming collisions.
2. If you've arranged your tests into subdirectories, you can create a `helpers.cfm` file in any given\
   directory and simply include it in the package.
3. Put package-specific helper functions in the same package as the tests that use it.\
   These will only be available to the tests in that package. To ensure that these test helpers\
   are not run as tests, use a function name that doesn't start with "test\_". Eg: `$simplify()`

```java
component extends="tests.Testbox.Test" {

  // 1. All functions in /tests/Testbox/Test.cfc will be available

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

* Overloading application vars.. Wheels will revert the application scope after all tests have completed.

Caveat: The test suite request must complete without uncaught exceptions. If an uncaught exception occurs, the application scope may stay 'dirty', so it's recommended to reload the application by adding `reload=true` param to your url whilst developing your test packages.

### Learn By Example: Wheels Core

The Wheels core uses TestBox for its unit test suite and contains a wealth of useful examples. They can all be found in the [`tests` folder](https://github.com/wheels-dev/wheels/tree/develop/tests) of the Wheels git repo.

### Video Tutorials

> 📹 **Coming Soon**: Video tutorials for visual learners
> - Getting Started with TestBox in Wheels
> - Migrating from RocketUnit to TestBox
> - Writing Effective Tests with TDD
> - Advanced Testing Techniques
>
> *Check the [complete testing guide](/docs/testing-with-testbox.md#video-tutorials) for updates*

### Additional Resources

- [Complete TestBox Testing Guide](/docs/testing-with-testbox.md) - Comprehensive guide with advanced topics
- [TestBox Documentation](https://testbox.ortusbooks.com/) - Official TestBox docs
- [Test Quick Start](/tests/README.md) - Quick reference for common patterns
- [Migration Cheat Sheet](/docs/testbox-migration-cheatsheet.md) - Quick reference for RocketUnit to TestBox
