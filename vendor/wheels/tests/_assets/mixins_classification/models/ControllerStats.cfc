// Fixture for pluginsMixinClassificationSpec (di-packages:12): a component that
// lives under a "models" path segment but whose name starts with "ControllerS",
// so an unanchored FindNoCase("controllers", fullname) misclassifies it as a
// controller. Dotted-segment matching must classify it as a model.
component {
}
