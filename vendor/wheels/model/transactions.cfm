<cfscript>
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
		// Validate before any state changes: RustCFML (and permissive engines)
		// accept unknown isolation levels instead of failing the begin tag.
		// Fail here so an invalid level throws uniformly on every engine and
		// the open-transaction marker is never set for a transaction that
		// cannot begin (TransactionMarkerResetSpec).
		if (!ListFindNoCase("read_uncommitted,read_committed,repeatable_read,serializable", arguments.isolation)) {
			Throw(
				type = "Wheels.InvalidTransactionIsolation",
				message = "The transaction isolation level `#arguments.isolation#` is not supported.",
				extendedInfo = "Valid isolation levels are read_uncommitted, read_committed, repeatable_read, and serializable."
			);
		}
		// Validate the mode here too, before the open-transaction marker is touched:
		// rejected only in the switch's default branch, an invalid mode left the
		// marker set, and every later call in the request silently ran as
		// "alreadyopen" with no transaction.
		if (!ListFindNoCase("commit,rollback,false,none,alreadyopen", arguments.transaction)) {
			Throw(
				type = "Wheels",
				message = "Invalid transaction type",
				extendedInfo = "The transaction type of `#arguments.transaction#` is invalid. Please use `commit`, `rollback` or `false`."
			);
		}
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

		// v4.2.0: per-connection afterCommit/afterRollback queue store.
		if (!StructKeyExists(request.wheels, "$txnCallbacks")) {
			request.wheels.$txnCallbacks = {};
		}

		// Issue #2789: skip model-level cftransaction when an outer owner (e.g. migrator) wraps this call.
		local.outerTransactionActive = (
			StructKeyExists(request, "$wheelsTransactionWrapper")
			&& IsBoolean(request.$wheelsTransactionWrapper)
			&& request.$wheelsTransactionWrapper
		);

		// If a transaction is already marked as open, change the mode to "alreadyopen", otherwise open one.
		if (local.outerTransactionActive || request.wheels.transactions[local.connectionArgs]) {
			arguments.transaction = "alreadyopen";
			local.closeTransaction = false;
		} else {
			request.wheels.transactions[local.connectionArgs] = true;
			// #3934 R1: mark a raw, non-Wheels transaction{} we are nested inside, BEFORE
			// opening our own (IsWithinTransaction() then still reflects only the outer block).
			// Capability-guarded: on Adobe CF / RustCFML it is a no-op and the callbacks fall
			// back to the inner close. $enqueueTransactionCallbacks then skips both callbacks
			// and warns once instead of firing on an outcome Wheels cannot observe.
			$markForeignTransaction(local.connectionArgs);
		}

		// Run the method.
		switch (arguments.transaction) {
			case "commit":
			case "rollback":
				// The outer try/catch exists because the `transaction action="begin"`
				// tag can throw before the inner one is ever entered — an unsupported
				// isolation level, a nested-isolation mismatch on Adobe, a dead
				// connection. The open marker is set above, so without this the
				// marker stayed `true` for the rest of the request and every later
				// invokeWithTransaction took the "alreadyopen" path and silently ran
				// with no transaction at all. The whole core suite runs in one
				// request, which is how a single throwing begin in
				// CockroachDBTransactionSpec went on to fail OuterTransactionSignalSpec
				// several bundles later (#3302). Resetting twice is harmless: the
				// inner catch already clears the same flag before it rethrows.
				// v4.2.0: the owner of a real (commit/rollback) transaction collects
				// afterCommit/afterRollback callbacks from every write (incl. nested)
				// and fires them once the outermost transaction resolves.
				$prepareTransactionCallbackStore(local.connectionArgs, local.closeTransaction);
				local.txnState = {rolledBack = false};
				try {
					transaction action="begin" isolation=arguments.isolation {
						try {
							local.rv = $invoke(method = arguments.method, componentReference = this, invokeArgs = local.methodArgs);
							// Roll back on a non-boolean/invalid return, a genuine boolean failure,
							// or an explicit rollback mode — but NOT on a numeric count.
							// $deleteAll / $updateAll return a numeric COUNT; a count of 0 is falsy,
							// so the old bare `!local.rv` check mistook a 0-row bulk op for a failed op
							// and rolled back. Nested in a raw transaction{} on Lucee/Adobe, that
							// rollback discarded the enclosing transaction and silently lost its other
							// writes. A count has IsBoolean(count)=true on every engine, so it slips the
							// `!IsBoolean` arm, and IsNumeric(count) kills the `!local.rv` arm — so counts
							// never roll back. A truly non-boolean/void return still rolls back here,
							// BEFORE the post-transaction boolean check throws, so the caller never sees
							// an error with the data already committed.
							if (
								!IsBoolean(local.rv)
								|| (!IsNumeric(local.rv) && !local.rv)
								|| arguments.transaction eq "rollback"
							) {
								transaction action="rollback";
								local.txnState.rolledBack = true;
							}
						} catch (any e) {
							transaction action="rollback";
							request.wheels.transactions[local.connectionArgs] = false;
							// Marker reset above; fire afterRollback (owner only) before the rethrow.
							if (local.closeTransaction) {
								$resolveTransactionCallbacks(connection = local.connectionArgs, type = "afterRollback", propagateErrors = false);
							}
							rethrow;
						}
					}
				} catch (any e) {
					request.wheels.transactions[local.connectionArgs] = false;
					if (
						local.closeTransaction
						&& StructKeyExists(request.wheels.$txnCallbacks, local.connectionArgs)
					) {
						$resolveTransactionCallbacks(connection = local.connectionArgs, type = "afterRollback");
					}
					rethrow;
				}
				// Transaction block closed without an exception: fire afterCommit on
				// commit, or afterRollback on a non-exception rollback (rv false / mode
				// rollback). Owner only; nested writes already queued into this set.
				if (local.closeTransaction) {
					// Reset the open-transaction marker BEFORE firing, so a throwing
					// callback can never leave it stuck (every later call would then run
					// "alreadyopen" with no transaction). $resolveTransactionCallbacks
					// also clears the queue context before firing.
					request.wheels.transactions[local.connectionArgs] = false;
					$resolveTransactionCallbacks(
						connection = local.connectionArgs,
						type = local.txnState.rolledBack ? "afterRollback" : "afterCommit"
					);
				}
				break;
			case "false":
			case "none":
			case "alreadyopen":
				// The same reset the commit/rollback branch does. "none" still sets the
				// open marker above (so nested calls skip their own transaction too), and
				// a throw from the method used to skip the reset below: the marker stayed
				// `true` for the rest of the request and every later model call took the
				// "alreadyopen" path with no transaction, so transaction="rollback" stopped
				// rolling back. The core test runner uses transactionMode="none", so one
				// failing create() broke OuterTransactionSignalSpec bundles later. Only
				// the call that set the marker clears it; an outer owner clears its own.
				try {
					local.rv = $invoke(method = arguments.method, componentReference = this, invokeArgs = local.methodArgs);
				} catch (any e) {
					if (local.closeTransaction) {
						request.wheels.transactions[local.connectionArgs] = false;
						$clearForeignTransaction(local.connectionArgs);
					}
					rethrow;
				}
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
			$clearForeignTransaction(local.connectionArgs);
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
</cfscript>
