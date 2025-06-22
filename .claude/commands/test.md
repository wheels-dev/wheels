I want to test the wheels cli command: $ARGUMENTS

1. Create a temporary test directory (e.g., `mkdir ../test-wheels-cli && cd ../test-wheels-cli`) to test wheels cli commands.
2. To run the CLI command we need to launch CommandBox with the `box` command.

If $ARGUMENTS is equal to `wheels generate app` or `wheels g app` then skip steps 3 and 4
3. Then create a app with the `wheels g app` command.
4. Then start the web server with `server start` commandbox command.

5. Then you can run various CLI commands in this case `$ARGUMENTS`
6. Use poppeteer to check to see if the desire results are achieved in the app
7. If Errors are thrown, analyze and fix the root cause of the error.
8. Analyze the functionality of the web app with poppeteer to make sure the desired results were achieved.
9. We want to test every functionality of the cli command, look in cli/commands/wheels for the code of the cli command and make corrections and additions if needed to fix errors or add functionality.
10. If changes are made to the CLI command then reload Commandbox with `box reload` or `exit` followed by `box` to reload the changes.
11. To restart the webserver use `server restart` or `server stop` followed by `server start`.
12. Keep in mind that commanbox doesn't like to mix named attributes and positional attributes.
13. Iterate until the command is error free and achieves the desired functionality is achieved.
14. Fix all issues identified.
15. Once finished:
    - stop the server with `server stop` command
		- destroy the server with `server forget` command
		- remove the test directory created in step 1
