<cfscript>
	/**
	 * Runs the specified method within a single database transaction.
	 *
	 * [section: Model Class]
	 * [category: Miscellaneous Functions]
	 *
	 * @method Model method to run.
	 * @transaction [see:save]. `savepoint` runs the method as a nested unit: inside an open transaction it rolls back only its own writes when the method returns `false` or throws (the outer transaction carries on); with no open transaction it behaves like `commit`.
	 * @isolation Isolation level to be passed through to the cftransaction tag. Defaults to the `transactionIsolation` setting (`read_committed` unless the app changes it). An empty string sends no isolation attribute, so the transaction uses the engine's or driver's default. See your CFML engine's documentation for more details about cftransaction's isolation attribute.
	 */
	public any function invokeWithTransaction(
		required string method,
		string transaction = "commit",
		string isolation
	) {
		// Only the default isolation may be dropped when an outer raw transaction {} rejects it
		// (#4045), so remember whether the caller chose one.
		local.explicitIsolation = StructKeyExists(arguments, "isolation");
		if (!local.explicitIsolation) {
			arguments.isolation = $get("transactionIsolation");
		}
		$assertTransactionArgs(transaction = arguments.transaction, isolation = arguments.isolation);
		// A savepoint unit nests inside an open transaction instead of joining it (#3958).
		if (arguments.transaction == "savepoint") {
			return $invokeWithSavepoint(argumentCollection = arguments);
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
				local.rv = $runInTransaction(
					method = arguments.method,
					transaction = arguments.transaction,
					isolation = arguments.isolation,
					explicitIsolation = local.explicitIsolation,
					methodArgs = local.methodArgs,
					connectionArgs = local.connectionArgs,
					closeTransaction = local.closeTransaction
				);
				break;
			case "false":
			case "none":
			case "alreadyopen":
				local.rv = $runWithoutTransaction(
					method = arguments.method,
					methodArgs = local.methodArgs,
					connectionArgs = local.connectionArgs,
					closeTransaction = local.closeTransaction
				);
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
	 * Internal. The `commit` / `rollback` branch of invokeWithTransaction(): opens the
	 * transaction, runs the method, and resolves afterCommit/afterRollback for the owner.
	 *
	 * The outer try/catch exists because the `transaction action="begin"` tag can throw
	 * before the inner one is ever entered: an unsupported isolation level, a dead
	 * connection. The open marker is set by the caller, so without this the marker stayed
	 * `true` for the rest of the request and every later invokeWithTransaction took the
	 * "alreadyopen" path and silently ran with no transaction at all. The whole core suite
	 * runs in one request, which is how a single throwing begin in
	 * CockroachDBTransactionSpec went on to fail OuterTransactionSignalSpec several
	 * bundles later (#3302). Resetting twice is harmless: the inner catch already clears
	 * the same flag before it rethrows. The owner of a real (commit/rollback) transaction
	 * collects afterCommit/afterRollback callbacks from every write (incl. nested) and
	 * fires them once the outermost transaction resolves.
	 */
	public any function $runInTransaction(
		required string method,
		required string transaction,
		required string isolation,
		required boolean explicitIsolation,
		required struct methodArgs,
		required string connectionArgs,
		required boolean closeTransaction
	) {
		$prepareTransactionCallbackStore(arguments.connectionArgs, arguments.closeTransaction);
		local.ctx = {
			method = arguments.method,
			transaction = arguments.transaction,
			methodArgs = arguments.methodArgs,
			connectionArgs = arguments.connectionArgs,
			closeTransaction = arguments.closeTransaction,
			txnState = {rolledBack = false, entered = false},
			rv = ""
		};
		try {
			$beginTransaction(isolation = arguments.isolation, explicitIsolation = arguments.explicitIsolation, ctx = local.ctx);
		} catch (any e) {
			request.wheels.transactions[arguments.connectionArgs] = false;
			if (
				arguments.closeTransaction
				&& StructKeyExists(request.wheels.$txnCallbacks, arguments.connectionArgs)
			) {
				// After the transaction block has ended (a failed begin, or a method that threw).
				// The original error is the one that propagates, not a failing callback's.
				$resolveTransactionCallbacks(connection = arguments.connectionArgs, type = "afterRollback", propagateErrors = false);
			}
			if (arguments.closeTransaction) {
				// The transaction rolled back (the body threw). Reads made inside it may have cached
				// uncommitted rows, so drop the whole request query cache — otherwise a later read in
				// this request returns phantom data that never committed (#4429).
				$clearRequestCache();
			}
			rethrow;
		}
		// Transaction block closed without an exception: fire afterCommit on commit, or
		// afterRollback on a non-exception rollback (rv false / mode rollback). Owner only;
		// nested writes already queued into this set.
		if (arguments.closeTransaction) {
			// Reset the open-transaction marker BEFORE firing, so a throwing callback can
			// never leave it stuck (every later call would then run "alreadyopen" with no
			// transaction). $resolveTransactionCallbacks also clears the queue context
			// before firing.
			request.wheels.transactions[arguments.connectionArgs] = false;
			$resolveTransactionCallbacks(
				connection = arguments.connectionArgs,
				type = local.ctx.txnState.rolledBack ? "afterRollback" : "afterCommit"
			);
			if (local.ctx.txnState.rolledBack) {
				// A non-exception rollback (the method returned false, or transaction = "rollback"):
				// same phantom-read risk as the throw path above, so drop the request query cache.
				// A commit does not need this — its reads are of committed rows (#4429).
				$clearRequestCache();
			}
		}
		return local.ctx.rv;
	}

	/**
	 * Internal. Opens `transaction action="begin"` and runs $transactionBody() in it.
	 *
	 * Adobe CF rejects a nested begin whose isolation differs from the parent's ("Nested
	 * cftransaction tag should specify same isolation level as the parent"), and a raw
	 * `transaction {}` with no isolation counts as a different level from the
	 * `read_committed` Wheels sends (#4045). The rejection happens before the body runs and
	 * leaves the outer transaction usable, so when the caller did not choose the isolation
	 * the begin is retried once without the attribute: it then inherits the parent's level
	 * and joins it. `ctx.txnState.entered` makes this fail safe: a block whose body already
	 * started is never run again, and any other error is rethrown unchanged. A caller-chosen
	 * isolation is never silently dropped; it fails with Wheels.TransactionIsolationMismatch.
	 */
	public void function $beginTransaction(required string isolation, required boolean explicitIsolation, required struct ctx) {
		// No isolation (transactionIsolation="", #4059): send no attribute, so the engine's or
		// driver's default applies. A nested begin then inherits its parent's level, so the
		// mismatch retry below is never needed.
		if (!Len(arguments.isolation)) {
			transaction action="begin" {
				$transactionBody(arguments.ctx);
			}
			return;
		}
		var retry = {needed = false};
		try {
			transaction action="begin" isolation=arguments.isolation {
				$transactionBody(arguments.ctx);
			}
		} catch (any e) {
			if (arguments.ctx.txnState.entered || !$isNestedIsolationMismatch(e)) {
				rethrow;
			}
			if (arguments.explicitIsolation) {
				Throw(
					type = "Wheels.TransactionIsolationMismatch",
					message = "The `#arguments.isolation#` isolation level differs from the open transaction's.",
					extendedInfo = "This engine requires a nested transaction to use its parent's isolation level. Give the outer `transaction {}` block the same `isolation`, or call the model method without an `isolation` argument so it joins the outer transaction."
				);
			}
			retry.needed = true;
		}
		if (retry.needed) {
			// A nested-isolation mismatch can only come from a raw transaction {} around this
			// write (a Wheels-owned outer transaction takes the "alreadyopen" path and never
			// opens a nested begin). So record the same foreign marker $markForeignTransaction()
			// sets when the engine reports the raw block: afterCommit/afterRollback are skipped
			// with the usual warning instead of firing at this inner close, before the outer
			// block's own commit or rollback.
			request.wheels.$txnCallbacks[arguments.ctx.connectionArgs] = {real = false, foreign = true, queue = []};
			transaction action="begin" {
				$transactionBody(arguments.ctx);
			}
		}
	}

	/**
	 * Internal. True for the engine's "nested transaction must use the parent's isolation
	 * level" error. Adobe CF has no error code for it, so the message is matched loosely
	 * (both words, any case). A false match is harmless: $beginTransaction() only retries a
	 * block whose body never ran.
	 */
	public boolean function $isNestedIsolationMismatch(required any exception) {
		local.text = "";
		if (StructKeyExists(arguments.exception, "message")) {
			local.text &= arguments.exception.message & " ";
		}
		if (StructKeyExists(arguments.exception, "detail")) {
			local.text &= arguments.exception.detail;
		}
		return FindNoCase("cftransaction", local.text) > 0 && FindNoCase("isolation", local.text) > 0;
	}

	/**
	 * Internal. The body of a Wheels-owned transaction: run the method and roll back on a
	 * failure. Roll back on a non-boolean/invalid return, a genuine boolean failure, or an
	 * explicit rollback mode, but NOT on a numeric count. $deleteAll / $updateAll return a
	 * numeric COUNT; a count of 0 is falsy, so the old bare `!rv` check mistook a 0-row bulk
	 * op for a failed op and rolled back. Nested in a raw transaction{} on Lucee/Adobe, that
	 * rollback discarded the enclosing transaction and silently lost its other writes. A
	 * count has IsBoolean(count)=true on every engine, so it slips the `!IsBoolean` arm, and
	 * IsNumeric(count) kills the `!rv` arm, so counts never roll back. A truly
	 * non-boolean/void return still rolls back here, BEFORE the post-transaction boolean
	 * check throws, so the caller never sees an error with the data already committed.
	 */
	public void function $transactionBody(required struct ctx) {
		arguments.ctx.txnState.entered = true;
		try {
			$invokeTransactionMethod(arguments.ctx);
			if (
				!IsBoolean(arguments.ctx.rv)
				|| (!IsNumeric(arguments.ctx.rv) && !arguments.ctx.rv)
				|| arguments.ctx.transaction eq "rollback"
			) {
				transaction action="rollback";
				arguments.ctx.txnState.rolledBack = true;
			}
		} catch (any e) {
			transaction action="rollback";
			request.wheels.transactions[arguments.ctx.connectionArgs] = false;
			// afterRollback fires in $runInTransaction's catch, once this transaction block has
			// ended: a callback that writes (a job enqueued with transactional = false) must not
			// run on the connection the block is about to roll back.
			rethrow;
		}
	}

	/**
	 * Internal. Runs a Wheels-owned transaction's method. When the request ends with `abort`
	 * inside it, the method has neither returned nor thrown, and the transaction is rolled back
	 * here, as it is after a failure. The rollback must stay in a try/finally with no catch clause:
	 * on BoxLang, abort skips a finally whose try has a catch clause (cross-engine invariant 22 in
	 * CLAUDE.md), and the transaction would then keep the writes made before the abort.
	 */
	public void function $invokeTransactionMethod(required struct ctx) {
		var exitState = {completed = false, threw = false};
		try {
			try {
				arguments.ctx.rv = $invoke(
					method = arguments.ctx.method,
					componentReference = this,
					invokeArgs = arguments.ctx.methodArgs
				);
				exitState.completed = true;
			} catch (any e) {
				exitState.threw = true;
				rethrow;
			}
		} finally {
			if (!exitState.completed && !exitState.threw) {
				transaction action="rollback";
			}
		}
	}

	/**
	 * Internal. The `false` / `none` / `alreadyopen` branch of invokeWithTransaction(): run
	 * the method with no transaction of its own. "none" still sets the open marker (so
	 * nested calls skip their own transaction too), and a throw from the method used to skip
	 * the reset: the marker stayed `true` for the rest of the request and every later model
	 * call took the "alreadyopen" path with no transaction, so transaction="rollback"
	 * stopped rolling back. Only the call that set the marker clears it; an outer owner
	 * clears its own.
	 */
	public any function $runWithoutTransaction(
		required string method,
		required struct methodArgs,
		required string connectionArgs,
		required boolean closeTransaction
	) {
		try {
			return $invoke(method = arguments.method, componentReference = this, invokeArgs = arguments.methodArgs);
		} catch (any e) {
			if (arguments.closeTransaction) {
				request.wheels.transactions[arguments.connectionArgs] = false;
				$clearForeignTransaction(arguments.connectionArgs);
			}
			rethrow;
		}
	}

	/**
	 * Internal. Validate the isolation level and transaction mode before any state
	 * changes.
	 */
	public void function $assertTransactionArgs(required string transaction, required string isolation) {
		// Validate before any state changes: RustCFML (and permissive engines)
		// accept unknown isolation levels instead of failing the begin tag.
		// Fail here so an invalid level throws uniformly on every engine and
		// the open-transaction marker is never set for a transaction that
		// cannot begin (TransactionMarkerResetSpec).
		// An empty string means "send no isolation attribute" (#4059).
		if (Len(arguments.isolation) && !ListFindNoCase("read_uncommitted,read_committed,repeatable_read,serializable", arguments.isolation)) {
			Throw(
				type = "Wheels.InvalidTransactionIsolation",
				message = "The transaction isolation level `#arguments.isolation#` is not supported.",
				extendedInfo = "Valid isolation levels are read_uncommitted, read_committed, repeatable_read, and serializable, or an empty string to use the engine's default."
			);
		}
		// Validate the mode here too, before the open-transaction marker is touched:
		// rejected only in the switch's default branch, an invalid mode left the
		// marker set, and every later call in the request silently ran as
		// "alreadyopen" with no transaction.
		if (!ListFindNoCase("commit,rollback,false,none,alreadyopen,savepoint", arguments.transaction)) {
			Throw(
				type = "Wheels",
				message = "Invalid transaction type",
				extendedInfo = "The transaction type of `#arguments.transaction#` is invalid. Please use `commit`, `rollback`, `savepoint` or `false`."
			);
		}
	}

	/**
	 * Internal. Runs `method` as a nested unit for transaction="savepoint" (#3958).
	 * With no open transaction it is a plain `commit` call. Inside one it sets a
	 * savepoint, runs the method, and on a `false` / invalid return or a throw rolls
	 * back to the savepoint only, so the outer transaction keeps its earlier writes
	 * and resolves on its own outcome. A throw is rethrown after the rollback. The
	 * open-transaction marker belongs to the outer owner and is never touched here.
	 */
	public any function $invokeWithSavepoint(required string method, string transaction, string isolation) {
		local.connectionArgs = this.$hashedConnectionArgs();
		if (!$transactionIsOpen(local.connectionArgs)) {
			arguments.transaction = "commit";
			return invokeWithTransaction(argumentCollection = arguments);
		}
		if (!StructKeyExists(variables, arguments.method)) {
			Throw(
				type = "Wheels",
				message = "Model method not found",
				extendedInfo = "The method `#arguments.method#` does not exist in this model."
			);
		}
		local.methodArgs = $setProperties(
			argumentCollection = arguments,
			properties = {},
			filterList = "method,transaction,isolation",
			setOnModel = false,
			$useFilterLists = false
		);
		local.savepoint = $setSavepoint();
		local.mark = $savepointCallbackMark(local.connectionArgs);
		try {
			local.rv = $invoke(method = arguments.method, componentReference = this, invokeArgs = local.methodArgs);
		} catch (any e) {
			// A rollback that itself fails is logged, never allowed to replace the
			// method's exception, which is what the caller needs to see.
			$rollbackToSavepointQuietly(name = local.savepoint, connection = local.connectionArgs, mark = local.mark);
			// The savepoint unit's reads may have cached rows it just rolled back; clear the request
			// cache so the outer transaction, which carries on, does not serve them as phantoms (#4429).
			$clearRequestCache();
			rethrow;
		}
		// Same failure test as the commit branch: a numeric count (0-row bulk op) is not a failure.
		if (!IsBoolean(local.rv) || (!IsNumeric(local.rv) && !local.rv)) {
			$rollbackToSavepoint(name = local.savepoint, connection = local.connectionArgs, mark = local.mark);
			// Same phantom-read risk as the exception path above (#4429).
			$clearRequestCache();
		}
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
	 * Internal. True when a transaction is open on this connection: one Wheels
	 * opened, an outer owner such as the migrator, or a raw transaction{} block on
	 * engines that can detect one (Lucee, BoxLang).
	 */
	public boolean function $transactionIsOpen(required string connection) {
		if (
			StructKeyExists(request, "wheels")
			&& StructKeyExists(request.wheels, "transactions")
			&& StructKeyExists(request.wheels.transactions, arguments.connection)
			&& request.wheels.transactions[arguments.connection]
		) {
			return true;
		}
		if (
			StructKeyExists(request, "$wheelsTransactionWrapper")
			&& IsBoolean(request.$wheelsTransactionWrapper)
			&& request.$wheelsTransactionWrapper
		) {
			return true;
		}
		return $withinForeignTransaction();
	}

	/**
	 * Internal. Sets a uniquely named savepoint and returns its name. A read on this
	 * model's table runs first: Lucee silently drops a savepoint set before the
	 * transaction's first query, and the later rollback then throws "There are no
	 * savepoint with name ...". The read is done on every engine (one primary-key
	 * select per unit) rather than keyed on an engine name.
	 */
	public string function $setSavepoint() {
		this.findOne(select = this.primaryKeys(), callbacks = false, reload = true);
		if (!StructKeyExists(request.wheels, "$savepointSeq")) {
			request.wheels.$savepointSeq = 0;
		}
		request.wheels.$savepointSeq++;
		local.name = "wsp_" & request.wheels.$savepointSeq;
		transaction action="setsavepoint" savepoint=local.name;
		return local.name;
	}

	/**
	 * Internal. Rolls back to a savepoint unit's savepoint and fires afterRollback for
	 * the records written inside it. Kept free of local-scope writes so callers can
	 * use it from a catch block (BoxLang).
	 */
	public void function $rollbackToSavepoint(required string name, required string connection, required numeric mark, boolean propagateErrors = true) {
		transaction action="rollback" savepoint=arguments.name;
		$rollbackSavepointCallbacks(connection = arguments.connection, mark = arguments.mark, propagateErrors = arguments.propagateErrors);
	}

	/**
	 * Internal. $rollbackToSavepoint for the exception path: a failure of the
	 * rollback itself (or of an afterRollback callback) is logged to wheels.log
	 * and swallowed, so the caller rethrows the method's original exception.
	 */
	public void function $rollbackToSavepointQuietly(required string name, required string connection, required numeric mark) {
		try {
			$rollbackToSavepoint(name = arguments.name, connection = arguments.connection, mark = arguments.mark, propagateErrors = false);
		} catch (any e) {
			try {
				writeLog(
					file = "wheels",
					type = "error",
					text = "Rolling back savepoint `" & arguments.name & "` failed after the unit threw: " & e.message
				);
			} catch (any logError) {
			}
		}
	}

	/**
	 * Internal function.
	 */
	public string function $hashedConnectionArgs() {
		return Hash(variables.wheels.class.dataSource & variables.wheels.class.username & variables.wheels.class.password);
	}
</cfscript>
