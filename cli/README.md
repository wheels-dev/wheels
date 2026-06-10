# Wheels CLI

The `wheels` command is a Rails-inspired CLI for scaffolding and running Wheels applications. In 4.0 it is distributed as a Homebrew / Chocolatey formula that bundles [LuCLI](https://github.com/cybersonic/LuCLI), so no CommandBox installation is required.

## Install

**macOS / Linux (Homebrew):**

```bash
brew tap wheels-dev/wheels
brew install wheels
```

Homebrew 5.1+ asks you to trust third-party taps on first use — run `brew trust wheels-dev/wheels` once if prompted.

**Windows (Chocolatey):**

```powershell
choco install wheels
```

Both installers depend only on Java 21, which is pulled in automatically.

## Commands

See [the CLI command guides](https://guides.wheels.dev/v4-0-0-snapshot/command-line-tools/) or run `wheels --help` in your terminal.

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

See the [Template System Guide](https://guides.wheels.dev/v4-0-0-snapshot/command-line-tools/) for detailed documentation.
