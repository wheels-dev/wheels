# Wheels CLI commands for CommandBox

This is a basic port of the Rails command line;
Skips things like `rails server` which are provided by CommandBox already.

## Install

Simply run `install wheels-cli` from CommandBox to install the latest release.

## Commands
See [the CLI command guides](https://guides.wheels.dev/wheels-guides/3.0.0-snapshot/command-line-tools/cli-commands) or use `help wheels` in Commandbox.

## Template Customization

The CLI supports template customization through an override system. Templates placed in your application's `/app/snippets/` directory will override the default CLI templates in `/cli/templates/`.

This allows you to:
- Customize generated code to match your project's coding standards
- Use your preferred CSS framework markup (Bootstrap, Tailwind, etc.)
- Add project-specific boilerplate code
- Maintain consistency across generated files

To customize a template:
1. Copy the template from `/cli/templates/` to `/app/snippets/`
2. Modify it to match your needs
3. The CLI will automatically use your custom template

See the [Template System Guide](https://guides.wheels.dev/wheels-guides/3.0.0-snapshot/command-line-tools/cli-guides/template-system) for detailed documentation.