# app/lib/

App-specific utility code. Plain CFCs, no framework conventions required.

Use this directory for:

- Domain logic that doesn't belong on a model or controller
- Service objects orchestrating multiple models
- Value objects, calculators, formatters
- Integration clients (third-party API wrappers)
- Anything shared across controllers

## Auto-discovery

Wheels maps components under `app/lib/` to the `app.lib` path automatically. Create `app/lib/PriceCalculator.cfc` and reference it as:

```cfm
var calc = createObject("component", "app.lib.PriceCalculator").init();
```

Or register it with the DI container in `config/services.cfm`:

```cfm
injector().map("priceCalculator").to("app.lib.PriceCalculator").asSingleton();
```

Then resolve anywhere with `service("priceCalculator")`.

## When to reach elsewhere

- **Model behavior** → `app/models/`
- **Request handling** → `app/controllers/`
- **Background work** → `app/jobs/`
- **Email** → `app/mailers/`
- **Cross-app reusable feature** → create a package in `vendor/<name>/`
