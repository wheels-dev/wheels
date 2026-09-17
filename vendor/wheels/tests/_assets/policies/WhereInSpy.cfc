/**
 * Collection stand-in whose whereIn([]) would match everything. Used to prove
 * Policy.scope() / policyScope() fail closed without calling whereIn.
 */
component {

	this.whereInCalls = 0;
	this.lastProperty = "";
	this.lastValues = [];

	public any function whereIn(required string property, required any values) {
		this.whereInCalls = this.whereInCalls + 1;
		this.lastProperty = arguments.property;
		this.lastValues = arguments.values;
		return this;
	}

	public numeric function count() {
		return 99;
	}

	public query function findAll() {
		return QueryNew("id", "integer", [[1]]);
	}

}
