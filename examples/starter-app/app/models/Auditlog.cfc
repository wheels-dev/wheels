component extends="Model"
{
	function config() {
		// Properties
		validatesPresenceOf("message,type,severity,createdBy,ipaddress");
		afterNew("serializeExtendedData");
	}

	/**
	 * If anything is passed into data, serialize if at all possible
	 */
	function serializeExtendedData() {
		if(structKeyExists(this, "data"))
			 this.data=serializeJSON(this.data);
	}
	
	function getAuditLog(required array where, required string perpage, required string page) {
		return model("auditlog").findAll(
			where=whereify(arguments.where),
			order="createdAt DESC",
			perpage=arguments.perpage,
			page=arguments.page
		);
	}
	
	function getAuditLogByKey(required string key) {
		return findByKey(arguments.key);
	}

	function getAuditLogBySelect(required string select) {
		return findAll(select="#arguments.select#");
	}
}
