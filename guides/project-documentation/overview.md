# Overview

The intention of this section is to document the various pieces of the tooling that make the project function. This is not so much about the framework and using the framework as a developer but more for collaborator, contributors, and maintainers of the project.

## Wheels Guides

The guides are hosted by [GitBooks.com](https://www.gitbook.com) and are accessible at [https://guides.wheels.dev](https://guides.wheels.dev) they are however driven by the [guides](https://github.com/cfwheels/cfwheels/tree/develop/guides) folder in the
Wheels repository on GitHub. This means that making changes to the guides can be accomplished via a Pull Request and code changes and changes to the guides can be submitted in the same PR.

### Making changes to the Guides

Start by cloning the [Wheels](https://github.com/cfwheels/cfwheels) repository. The guides are contained in the `guides` folder of the repo. Make your proposed changes and submit a PR. Once the PR is reviewed and merged, the changes will automatically be synced up to GitBook and the changes will be live on the site.

## API Documentation

The API Documentation is comprised of two parts. The first is a json file that contains the data for a particular version of the framework and the second is a small Wheels App that reads that json file and displays the UI you see when you visit [https://api.wheels.dev](https://api.wheels.dev).

We use a javadoc style of notation to document all the public functions of the framework. This system is actually available to you to document your own functions and is documented at [Documenting your Code](https://guides.wheels.dev/wheels-guides/working-with-wheels/documenting-your-code). Additionally the sample code is driven off text files that are located in [wheels/public/docs/reference](https://github.com/cfwheels/cfwheels/tree/develop/wheels/public/docs/reference).

So the first step in submitting changes to the API Documentation is similar to the Wheels Guides and starts with cloning the repository, making the changes, and submitting a PR.

Once approved and merged in, then the json file is generated using a utility embedded in the framework itself. So once a version has been published to ForgeBox (either a SNAPSHOT or a stable release), use command box to install that version of the framework.

```wheels generate app name=json template=wheels-base-template@be cfmlEngine=lucee@5```

This will install the Bleeding Edge version of the framework with the Lucee v5 CFML Engine. Once the installation completes start your server.

```server start```

When the Congratulations screen is displayed, click on the Info Tab on the top menu and then the Utils tab from the sub menu.

Then click on the Export Docs as JSON link to generate the json file. Save the json file. Typically these files are named based on the version of the framework they represent. i.e. the file for v2.5.0 would be named  v2.5.json.

Now that we have generated the JSON data file, we need to add it to the codebase for the API Documentation site. This codebase is driven from the [wheels-api repository](https://github.com/cfwheels/wheels-api). A PR can be used to submit the json file to this repository. Currently the core team is manually adding this file to the repository when the API docs need to be updated.

The application is then uploaded to the site hosted by [Viviotech](http://www.viviotech.net).

At the moment the process of updating the API Documentation is very manual, I hope to be able to extend the CI pipeline and automatically update the API docs with each commit similarly to how the packages on ForgeBox are published automatically on each commit.
