component extends="wheels.channel.DatabaseAdapter" {

	public BrokenDatasourceAdapter function init(boolean tableVerified = true) {
		super.init();
		variables.$datasource = "wheels-channel-hardener-missing-ds";
		variables.tableVerified = arguments.tableVerified;
		return this;
	}

}
