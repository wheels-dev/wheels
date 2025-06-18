---
description: >-
  Use Wheels to send files to your users securely and with better control of
  the user experience.
---

# Sending Files

Sending files?! Is that really a necessary feature of Wheels? Can't I just place the file on my web server and link to it? You are correct, there is absolutely no need to use Wheels to send files. Your web server will do a fine job of sending out files to your users.

However, if you want a little more control over the way the user's browser handles the download or be able to secure access to your files then you might find the [sendFile()](https://wheels.dev/api/v3.0.0/controller.sendfile.html) function useful.

### Sending Files with the sendFile() Function

The convention in Wheels is to place all files you want users to be able to download in the `public/files` folder.

Assuming you've placed a file named `wheels_tutorial_20081028_J657D6HX.pdf` in that folder, here is a quick example of how you can deliver that file to the user. Let's start with creating a link to the action that will handle the sending of the file first.

```html
<p>
  #linkTo(text="Download Tutorial", action="sendTutorial")#
</p>
```

Now let's send the file to the user in the `sendTutorial` controller action. Just like the rendering functions in Wheels, the [sendFile()](https://wheels.dev/api/v3.0.0/controller.sendfile.html) function should be placed as the very last thing you do in your action code.

In this case, that's the only thing we are doing, but perhaps you want to track how many times the file is being downloaded, for example. In that case, the tracking code needs to be placed _before_ the [sendFile()](https://wheels.dev/api/v3.0.0/controller.sendfile.html) function.

Also, remember that the [sendFile()](https://wheels.dev/api/v3.0.0/controller.sendfile.html) function replaces any rendering. You cannot send a file _and_ render a page. (This will be quite obvious once you try this code because you'll see that the browser will give you a dialog box, and you won't actually leave the page that you're viewing at the time.)

Here's the `sendTutorial` action:

{% code title="Example" %}
```javascript
function sendTutorial() {
    sendFile(file="wheels_tutorial_20081028_J657D6HX.pdf");
}
```
{% endcode %}

That's one ugly file name though, eh? Let's present it to the user in a nicer way by suggesting a different name to the browser:

{% code title="Example" %}
```javascript
function sendTutorial() {
    sendFile(file="wheels_tutorial_20081028_J657D6HX.pdf", name="Tutorial.pdf");
}
```
{% endcode %}

Much better! :)

By default, the [sendFile()](https://wheels.dev/api/v3.0.0/controller.sendfile.html) function will try and force a download dialog box to be shown to the user. The purpose of this is to make it easy for the user\
to save the file to their computer. If you want the file to be shown inside the browser instead (when possible as decided by the browser in question), you can set the `disposition` argument to `inline`.

Here's an example:

Example

```javascript
function sendTutorial() {
    sendFile(file="wheels_tutorial_20081028_J657D6HX.pdf", disposition="inline");
}
```

You can also specify what HTTP content type to use when delivering the file by using the `type` argument. Please refer to the API for the [sendFile()](https://wheels.dev/api/v3.0.0/controller.sendfile.html)\
function for complete details.

### Sending Files via ram://

You can even send files which are stored in `ram://` - this is particularly useful when you're dynamically creating files (such as PDF reports) which don't need to be written to the file system.

{% code title="Example" %}
```javascript
// Create the PDF.
wheels = cfdocument(format='pdf') {
 writeOutput(Now());
}; 

// Write the file to RAM.
fileWrite("ram://wheels.pdf", wheels);

// Send it.
sendFile(file="ram://wheels.pdf");
```
{% endcode %}

### Securing Access to Files

Perhaps the main reason to use the [sendFile()](https://wheels.dev/api/v3.0.0/controller.sendfile.html) function is that it gives you an easy way to secure access to your files. Maybe the tutorial file used in the above example is something the user paid for, and you only want for that user to be able to download it (and no one else). To accomplish this, you can just add some code to authenticate the user right before the [sendFile()](https://wheels.dev/api/v3.0.0/controller.sendfile.html) call in your action.

However, there is a security flaw here. Can you figure out what it is?

You may have guessed that the files folder is placed in your web root, so anyone can download files from it by typing `http://www.domain.com/files/wheels_tutorial_20081028_J657D6HX.pdf` in their\
browser. Although users would need to guess the file names to be able to access the files, we would still need something more robust as far as security goes.

There are two solutions to this.

The easiest one is to just lock down access to the folder using your web server. Wheels won't be affected by it since it gets the file from the file system.

If that is not an option, the other option is simply to move the files folder out of the web root, thus making it inaccessible. If you move the folder, you'll need to accommodate for this in your code by changing your [sendFile()](https://wheels.dev/api/v3.0.0/controller.sendfile.html) calls to specify the path as well, like this:

{% code title="Example" %}
```javascript
function sendTutorial() {
    sendFile(file="../../tutorials/wheels_tutorial_20081028_J657D6HX.pdf");
}
```
{% endcode %}

This assumes you've moved the folder two levels up in your file system and into\
a folder named "tutorials".

### Don't Open Any Holes with URL Parameters

**A final note of warning:** Be careful to not allow just any parameters from the URL to get passed through to the [sendFile()](https://wheels.dev/api/v3.0.0/controller.sendfile.html) because then a user would be able to download any file from your server by playing around with the URL. Be wary of how you're using the `params` struct in this context!
