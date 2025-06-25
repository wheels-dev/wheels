component {
	/**
	 * Runs the specified method within a single database transaction.
	 *
	 * [section: Model Class]
	 * [category: Miscellaneous Functions]
	 *
	 * @method Model method to run.
	 * @transaction [see:save].
	 * @isolation Isolation level to be passed through to the cftransaction tag. See your CFML engine's documentation for more details about cftransaction's isolation attribute.
	 */
	public any function invokeWithTransaction(
		required string method,
		string transaction = "commit",
		string isolation = "read_committed"
	) {
		local.methodArgs = $setProperties(
			argumentCollection = arguments,
			properties = {},
			filterList = "method,transaction,isolation",
			setOnModel = false,
			$useFilterLists = false
		);
		local.connectionArgs = this.$hashedConnectionArgs();
		local.closeTransaction = true;
		if (!StructKeyExists(variables, arguments.method)) {
			Throw(
				type = "Wheels",
				message = "Model method not found",
				extendedInfo = "The method `#arguments.method#` does not exist in this model."
			);
		}

		// Create the marker for an open transaction if it doesn't already exist.
		if (!StructKeyExists(request.wheels.transactions, local.connectionArgs)) {
			request.wheels.transactions[local.connectionArgs] = false;
		}

		// If a transaction is already marked as open, change the mode to "alreadyopen", otherwise open one.
		if (request.wheels.transactions[local.connectionArgs]) {
			arguments.transaction = "alreadyopen";
			local.closeTransaction = false;
		} else {
			request.wheels.transactions[local.connectionArgs] = true;
		}

		// Run the method.
		switch (arguments.transaction) {
			case "commit":
			case "rollback":
				transaction action="begin" isolation=arguments.isolation {
					try {
						local.rv = $invoke(method = arguments.method, componentReference = this, invokeArgs = local.methodArgs);
						if (!IsBoolean(local.rv) || !local.rv || arguments.transaction eq "rollback") {
							transaction action="rollback";
						}
					} catch (any e) {
						transaction action="rollback";
						request.wheels.transactions[local.connectionArgs] = false;
						rethrow;
					}
				}
				break;
			case "false":
			case "none":
			case "alreadyopen":
				local.rv = $invoke(method = arguments.method, componentReference = this, invokeArgs = local.methodArgs);
				break;
			default:
				Throw(
					type = "Wheels",
					message = "Invalid transaction type",
					extendedInfo = "The transaction type of `#arguments.transaction#` is invalid. Please use `commit`, `rollback` or `false`."
				);
		}

		if (local.closeTransaction) {
			request.wheels.transactions[local.connectionArgs] = false;
		}

		// Check the return type.
		if (!IsBoolean(local.rv)) {
			Throw(
				type = "Wheels",
				message = "Invalid return type",
				extendedInfo = "Methods invoked using `invokeWithTransaction` must return a boolean value."
			);
		}

		return local.rv;
	}

	/**
	 * Internal function.
	 */
	public string function $hashedConnectionArgs() {
		return Hash(variables.wheels.class.dataSource & variables.wheels.class.username & variables.wheels.class.password);
	}
}
