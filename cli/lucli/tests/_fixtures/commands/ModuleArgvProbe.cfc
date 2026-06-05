/**
 * Test fixture for Module.cfc's private argv-rebuild helper.
 *
 * Module.cfc's argsFromCollection() reconstructs the CLI argv array from
 * LuCLI's argCollection struct. It is private to keep the LuCLI-dispatch
 * surface tight, so this fixture exposes a thin pass-through so specs can
 * cover the negation-flag handling that issue #2855 surfaced.
 */
component extends="cli.lucli.Module" {

	public array function $argsFromCollection(required struct coll) {
		return argsFromCollection(arguments.coll);
	}

}
