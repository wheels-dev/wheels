/**
 * A real ServerRegistry (temp LuCLI home) that records which start tokens
 * stop() deletes, so a spec can tell the live registration's token from a
 * stale one's (#3994).
 */
component extends="cli.lucli.services.ServerRegistry" {

	this.deletedTokens = [];

	public void function deleteStartToken(required string name) {
		arrayAppend(this.deletedTokens, arguments.name);
		super.deleteStartToken(arguments.name);
	}

}
