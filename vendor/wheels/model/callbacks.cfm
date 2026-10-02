<cfscript>
	/**
	 * Registers method(s) that should be called after a new object is created.
	 *
	 * [section: Model Configuration]
	 * [category: Callback Functions]
	 *
	 * @methods [see:afterNew].
	 */
	public void function afterCreate(string methods = "") {
		$registerCallback(argumentCollection = arguments, type = "afterCreate");
	}

	/**
	 * Registers method(s) that should be called after an object is deleted.
	 *
	 * [section: Model Configuration]
	 * [category: Callback Functions]
	 *
	 * @methods [see:afterNew].
	 */
	public void function afterDelete(string methods = "") {
		$registerCallback(argumentCollection = arguments, type = "afterDelete");
	}

	/**
	 * Registers method(s) that should be called after an existing object has been initialized (which is usually done with the `findByKey` or `findOne` method).
	 *
	 * [section: Model Configuration]
	 * [category: Callback Functions]
	 *
	 * @methods [see:afterNew].
	 */
	public void function afterFind(string methods = "") {
		$registerCallback(argumentCollection = arguments, type = "afterFind");
	}

	/**
	 * Registers method(s) that should be called after an object has been initialized.
	 *
	 * [section: Model Configuration]
	 * [category: Callback Functions]
	 *
	 * @methods [see:afterNew].
	 */
	public void function afterInitialization(string methods = "") {
		$registerCallback(argumentCollection = arguments, type = "afterInitialization");
	}

	/**
	 * Registers method(s) that should be called after a new object has been initialized (which is usually done with the `new` method).
	 *
	 * [section: Model Configuration]
	 * [category: Callback Functions]
	 *
	 * @methods Method name or list of method names that should be called when this callback event occurs in an object's life cycle (can also be called with the `method` argument).
	 */
	public void function afterNew(string methods = "") {
		$registerCallback(argumentCollection = arguments, type = "afterNew");
	}

	/**
	 * Registers method(s) that should be called after an object is saved.
	 *
	 * [section: Model Configuration]
	 * [category: Callback Functions]
	 *
	 * @methods [see:afterNew].
	 */
	public void function afterSave(string methods = "") {
		$registerCallback(argumentCollection = arguments, type = "afterSave");
	}

	/**
	 * Registers method(s) that should be called after an existing object is updated.
	 *
	 * [section: Model Configuration]
	 * [category: Callback Functions]
	 *
	 * @methods [see:afterNew].
	 */
	public void function afterUpdate(string methods = "") {
		$registerCallback(argumentCollection = arguments, type = "afterUpdate");
	}

	/**
	 * Registers method(s) that should be called after an object is validated.
	 *
	 * [section: Model Configuration]
	 * [category: Callback Functions]
	 *
	 * @methods [see:afterNew].
	 */
	public void function afterValidation(string methods = "") {
		$registerCallback(argumentCollection = arguments, type = "afterValidation");
	}

	/**
	 * Registers method(s) that should be called after a new object is validated.
	 *
	 * [section: Model Configuration]
	 * [category: Callback Functions]
	 *
	 * @methods [see:afterNew].
	 */
	public void function afterValidationOnCreate(string methods = "") {
		$registerCallback(argumentCollection = arguments, type = "afterValidationOnCreate");
	}

	/**
	 * Registers method(s) that should be called after an existing object is validated.
	 *
	 * [section: Model Configuration]
	 * [category: Callback Functions]
	 *
	 * @methods [see:afterNew].
	 */
	public void function afterValidationOnUpdate(string methods = "") {
		$registerCallback(argumentCollection = arguments, type = "afterValidationOnUpdate");
	}

	/**
	 * Registers method(s) that should be called before a new object is created.
	 *
	 * [section: Model Configuration]
	 * [category: Callback Functions]
	 *
	 * @methods [see:afterNew].
	 */
	public void function beforeCreate(string methods = "") {
		$registerCallback(argumentCollection = arguments, type = "beforeCreate");
	}

	/**
	 * Registers method(s) that should be called before an object is deleted.
	 *
	 * [section: Model Configuration]
	 * [category: Callback Functions]
	 *
	 * @methods [see:afterNew].
	 */
	public void function beforeDelete(string methods = "") {
		$registerCallback(argumentCollection = arguments, type = "beforeDelete");
	}

	/**
	 *  Registers method(s) that should be called before an object is saved.
	 *
	 * [section: Model Configuration]
	 * [category: Callback Functions]
	 *
	 * @methods [see:afterNew].
	 */
	public void function beforeSave(string methods = "") {
		$registerCallback(argumentCollection = arguments, type = "beforeSave");
	}

	/**
	 * Registers method(s) that should be called before an existing object is updated.
	 *
	 * [section: Model Configuration]
	 * [category: Callback Functions]
	 *
	 * @methods [see:afterNew].
	 */
	public void function beforeUpdate(string methods = "") {
		$registerCallback(argumentCollection = arguments, type = "beforeUpdate");
	}

	/**
	 * Registers method(s) that should be called before an object is validated.
	 *
	 * [section: Model Configuration]
	 * [category: Callback Functions]
	 *
	 * @methods [see:afterNew].
	 */
	public void function beforeValidation(string methods = "") {
		$registerCallback(argumentCollection = arguments, type = "beforeValidation");
	}

	/**
	 * Registers method(s) that should be called before a new object is validated.
	 *
	 * [section: Model Configuration]
	 * [category: Callback Functions]
	 *
	 * @methods [see:afterNew].
	 */
	public void function beforeValidationOnCreate(string methods = "") {
		$registerCallback(argumentCollection = arguments, type = "beforeValidationOnCreate");
	}

	/**
	 * Registers method(s) that should be called before an existing object is validated.
	 *
	 * [section: Model Configuration]
	 * [category: Callback Functions]
	 *
	 * @methods [see:afterNew].
	 */
	public void function beforeValidationOnUpdate(string methods = "") {
		$registerCallback(argumentCollection = arguments, type = "beforeValidationOnUpdate");
	}

	/**
	 * Internal function.
	 */
	public void function $registerCallback(required string type, required string methods) {
		// Create this type in the array if it doesn't already exist.
		if (!StructKeyExists(variables.wheels.class.callbacks, arguments.type)) {
			variables.wheels.class.callbacks[arguments.type] = [];
		}

		local.existingCallbacks = ArrayToList(variables.wheels.class.callbacks[arguments.type]);
		if (StructKeyExists(arguments, "method")) {
			arguments.methods = arguments.method;
		}
		arguments.methods = $listClean(arguments.methods);
		local.iEnd = ListLen(arguments.methods);
		for (local.i = 1; local.i <= local.iEnd; local.i++) {
			if (!ListFindNoCase(local.existingCallbacks, ListGetAt(arguments.methods, local.i))) {
				ArrayAppend(variables.wheels.class.callbacks[arguments.type], ListGetAt(arguments.methods, local.i));
			}
		}
	}

	/**
	 * Internal function.
	 */
	public void function $clearCallbacks(string type = "") {
		arguments.type = $listClean(list = "#arguments.type#", returnAs = "array");

		// No type(s) was passed in. get all the callback types registered.
		if (ArrayIsEmpty(arguments.type)) {
			arguments.type = ListToArray(StructKeyList(variables.wheels.class.callbacks));
		}

		// Loop through each callback type and clear it.
		local.iEnd = ArrayLen(arguments.type);
		for (local.i = 1; local.i <= local.iEnd; local.i++) {
			variables.wheels.class.callbacks[arguments.type[local.i]] = [];
		}
	}

	/**
	 * Internal function.
	 */
	public any function $callbacks(string type = "") {
		if (Len(arguments.type)) {
			if (StructKeyExists(variables.wheels.class.callbacks, arguments.type)) {
				local.rv = variables.wheels.class.callbacks[arguments.type];
			} else {
				local.rv = [];
			}
		} else {
			local.rv = variables.wheels.class.callbacks;
		}
		return local.rv;
	}

	/**
	 * Internal function.
	 */
	public boolean function $callback(required string type, required boolean execute, any collection = "") {
		if (arguments.execute) {
			// Get all callbacks for the type and loop through them all until the end or one of them returns false.
			local.callbacks = $callbacks(arguments.type);
			local.iEnd = ArrayLen(local.callbacks);
			for (local.i = 1; local.i <= local.iEnd; local.i++) {
				local.method = local.callbacks[local.i];
				if (arguments.type == "afterFind") {
					local.rv = $afterFindCallback(method = local.method, collection = arguments.collection);
				} else {
					local.rv = $invoke(method = local.method);
				}

				// Break the loop if the callback returned false.
				if (StructKeyExists(local, "rv") && IsBoolean(local.rv) && !local.rv) {
					break;
				}
			}
		}

		// Return true by default (happens when no callbacks are set or none of the callbacks returned a result).
		if (!StructKeyExists(local, "rv")) {
			local.rv = true;
		}

		return local.rv;
	}

	/**
	 * Internal function.
	 */
	public boolean function $queryCallback(required string method, required query collection) {
		// We return true by default, will be overridden only if the callback method returns false on one of the iterations.
		local.rv = true;
		// Loop over all query rows and execute the callback method for each.
		local.rowNumber = 0;
		for (local.row in arguments.collection) {
			local.rowNumber++;
			// Execute the callback method.
			local.result = $invoke(method = arguments.method, invokeArgs = local.row);

			if (StructKeyExists(local, "result")) {
				if (IsStruct(local.result)) {
					// The arguments struct was returned so we need to add the changed values to the query row.
					for (local.key in local.result) {
						// Add a new column to the query if a value was passed back for a column that did not exist originally.
						if (!QueryKeyExists(arguments.collection, local.key)) {
							QueryAddColumn(arguments.collection, local.key, []);
						}
						if ($engineAdapter().isBoxLang() && local.result[local.key] == "") {
							continue;
						}

						arguments.collection[local.key][local.rowNumber] = $engineAdapter().coerceOracleObject(local.result[local.key]);
					}
				} else if (IsBoolean(local.result) && !local.result) {
					// Break the loop and return false if the callback returned false.
					local.rv = false;
					break;
				}
			}
		}

		// Update the request with a hash of the query if it changed so that we can find it with pagination.
		local.querykey = $hashedKey(arguments.collection);
		if (!StructKeyExists(request.wheels, local.querykey)) {
			request.wheels[local.querykey] = variables.wheels.class.modelName;
		}

		return local.rv;
	}

	/**
	 * Internal function.
	 * Executes an afterFind callback against a query or object.
	 */
	public any function $afterFindCallback(required string method, any collection = "") {
		if (IsQuery(arguments.collection)) {
			return $queryCallback(method = arguments.method, collection = arguments.collection);
		}
		local.invokeArgs = properties();
		local.result = $invoke(method = arguments.method, invokeArgs = local.invokeArgs);
		if (StructKeyExists(local, "result") && IsStruct(local.result)) {
			setProperties(local.result);
			return;
		}
		if (StructKeyExists(local, "result")) {
			return local.result;
		}
	}

	/**
	 * Internal function.
	 * Converts Oracle TIMESTAMP/DATE objects to CFML DateTime values via the engine adapter.
	 */
	public any function $coerceOracleTimestamp(required any value) {
		return $engineAdapter().coerceOracleObject(arguments.value);
	}

	/**
	 * Registers method(s) to run AFTER the database transaction commits (v4.2.0).
	 * They run only when the OUTERMOST transaction commits; a rollback discards
	 * them. With no transaction (transactionMode="none"/"false") they fire
	 * immediately after the write, since it is already committed.
	 *
	 * [section: Model Configuration]
	 * [category: Callback Functions]
	 *
	 * @methods [see:afterNew].
	 * @on Restrict to one or more operations: create, update, delete (comma-delimited; blank = all).
	 */
	public void function afterCommit(string methods = "", string on = "") {
		$registerTransactionCallback(type = "afterCommit", methods = arguments.methods, on = arguments.on);
	}

	/**
	 * Registers method(s) to run AFTER the database transaction rolls back (v4.2.0).
	 *
	 * [section: Model Configuration]
	 * [category: Callback Functions]
	 *
	 * @methods [see:afterNew].
	 * @on Restrict to one or more operations: create, update, delete (comma-delimited; blank = all).
	 */
	public void function afterRollback(string methods = "", string on = "") {
		$registerTransactionCallback(type = "afterRollback", methods = arguments.methods, on = arguments.on);
	}

	/**
	 * Internal. Stores afterCommit/afterRollback entries as {method, on} structs
	 * so the optional operation filter rides with each method.
	 */
	public void function $registerTransactionCallback(required string type, required string methods, string on = "") {
		if (!StructKeyExists(variables.wheels.class.callbacks, arguments.type)) {
			variables.wheels.class.callbacks[arguments.type] = [];
		}
		local.cleanMethods = $listClean(arguments.methods);
		local.cleanOn = $listClean(LCase(arguments.on));
		local.iEnd = ListLen(local.cleanMethods);
		for (local.i = 1; local.i <= local.iEnd; local.i++) {
			ArrayAppend(
				variables.wheels.class.callbacks[arguments.type],
				{method = ListGetAt(local.cleanMethods, local.i), on = local.cleanOn}
			);
		}
	}

	/**
	 * Internal. True when this model has any afterCommit/afterRollback callback.
	 */
	public boolean function $hasTransactionCallbacks() {
		return (
			(StructKeyExists(variables.wheels.class.callbacks, "afterCommit") && !ArrayIsEmpty(variables.wheels.class.callbacks.afterCommit))
			|| (StructKeyExists(variables.wheels.class.callbacks, "afterRollback") && !ArrayIsEmpty(variables.wheels.class.callbacks.afterRollback))
		);
	}

	/**
	 * Internal. Called by $save / $delete after their in-transaction after*
	 * callbacks succeed. Enqueues this instance for the outermost transaction to
	 * fire; or, with no real transaction (none/false mode), fires afterCommit now
	 * because the write is already committed (decision B1). Inside a foreign raw
	 * transaction{} (detectable engines only) it skips both callbacks and warns once.
	 */
	public void function $enqueueTransactionCallbacks(required string operation) {
		if (!$hasTransactionCallbacks()) {
			return;
		}
		local.conn = this.$hashedConnectionArgs();
		// #3934 R1: a write inside a foreign, non-Wheels transaction{} — Wheels cannot
		// observe the outer commit/rollback, so skip BOTH afterCommit and afterRollback
		// and warn once (per request + model). The flag is set where the engine reports an
		// open transaction ($foreignTransactionCheckMode: Lucee/BoxLang IsWithinTransaction(),
		// Adobe's TransactionTag, #4068), and on Adobe when its nested-isolation mismatch proves
		// a raw outer block (#4045, $beginTransaction). On RustCFML it is never set.
		if (this.$transactionForeign(local.conn)) {
			this.$warnForeignTransactionCallbacksOnce();
			return;
		}
		if (
			StructKeyExists(request, "wheels")
			&& StructKeyExists(request.wheels, "$txnCallbacks")
			&& StructKeyExists(request.wheels.$txnCallbacks, local.conn)
			&& request.wheels.$txnCallbacks[local.conn].real
		) {
			ArrayAppend(
				request.wheels.$txnCallbacks[local.conn].queue,
				{object = this, operation = arguments.operation}
			);
		} else {
			this.$runTransactionCallbacks(type = "afterCommit", operation = arguments.operation);
		}
	}

	/**
	 * Internal. True if the engine can tell that a transaction Wheels did not open is
	 * active, i.e. a raw, non-Wheels transaction we are nested in. Probed once and cached
	 * per application; see $foreignTransactionCheckMode() for the capabilities used.
	 */
	public boolean function $supportsForeignTransactionCheck() {
		return Len($foreignTransactionCheckMode()) > 0;
	}

	/**
	 * Internal. How this engine reports an open transaction, probed by capability (never
	 * by engine name) and cached per application:
	 * - "isWithinTransaction": the IsWithinTransaction() function exists (Lucee, BoxLang).
	 * - "transactionTag": Adobe CF's static coldfusion.tagext.sql.TransactionTag.getCurrent()
	 *   resolves and returns null when no transaction is open (#4068). It returns the
	 *   enclosing cftransaction tag for the current thread, so one request never sees
	 *   another's transaction (probed with concurrent requests on Adobe 2023 and 2025). It is
	 *   an Adobe internal, so it is called reflectively through the exported Method object
	 *   (cross-engine invariant 14) and anything unexpected disables it.
	 * - "": neither (RustCFML, or an Adobe release without the class): not detectable.
	 * A getCurrent() that is not null at probe time proves nothing either way (the probe may
	 * be running inside a raw transaction {}), so that result is not cached.
	 */
	public string function $foreignTransactionCheckMode() {
		if (!StructKeyExists(application, "wheels")) {
			return "";
		}
		if (!StructKeyExists(application.wheels, "$foreignTransactionCheckMode")) {
			local.mode = "";
			try {
				IsWithinTransaction();
				local.mode = "isWithinTransaction";
			} catch (any e) {
				// Engine lacks the function (Adobe CF, RustCFML).
			}
			if (!Len(local.mode)) {
				local.probe = $probeTransactionTagCurrent();
				if (local.probe == "inconclusive") {
					return "";
				}
				local.mode = local.probe;
			}
			application.wheels.$foreignTransactionCheckMode = local.mode;
		}
		return application.wheels.$foreignTransactionCheckMode;
	}

	/**
	 * Internal. Probes Adobe CF's TransactionTag.getCurrent(): "transactionTag" when it
	 * resolves and is null now, "inconclusive" when it returns a tag (a transaction may be
	 * open around this probe), "" when it is missing or throws. The resolved Method object is
	 * kept in the application scope for $transactionTagIsOpen().
	 */
	public string function $probeTransactionTagCurrent() {
		try {
			local.method = CreateObject("java", "java.lang.Class")
				.forName("coldfusion.tagext.sql.TransactionTag")
				.getMethod("getCurrent", JavaCast("null", ""));
			local.current = local.method.invoke(JavaCast("null", ""), JavaCast("null", ""));
			if (!IsNull(local.current)) {
				return "inconclusive";
			}
			application.wheels.$transactionTagGetCurrent = local.method;
			return "transactionTag";
		} catch (any e) {
			return "";
		}
	}

	/**
	 * Internal. True when Adobe CF's TransactionTag.getCurrent() reports an open
	 * cftransaction on this thread. Any failure reads as "not open", which is today's
	 * behaviour on an engine that can't detect one.
	 */
	public boolean function $transactionTagIsOpen() {
		try {
			return !IsNull(application.wheels.$transactionTagGetCurrent.invoke(JavaCast("null", ""), JavaCast("null", "")));
		} catch (any e) {
			return false;
		}
	}

	/**
	 * Internal. True when a transaction Wheels did not open is already active — i.e. a
	 * raw transaction{} block we are nested inside. MUST be called BEFORE Wheels opens
	 * its own transaction (after which the engine reports Wheels' own).
	 */
	public boolean function $withinForeignTransaction() {
		switch ($foreignTransactionCheckMode()) {
			case "isWithinTransaction":
				try {
					return IsWithinTransaction();
				} catch (any e) {
					return false;
				}
			case "transactionTag":
				return $transactionTagIsOpen();
			default:
				return false;
		}
	}

	/**
	 * Internal. True when the per-connection store marks this connection as being
	 * inside a foreign (raw, non-Wheels) transaction.
	 */
	public boolean function $transactionForeign(required string connection) {
		return (
			StructKeyExists(request, "wheels")
			&& StructKeyExists(request.wheels, "$txnCallbacks")
			&& StructKeyExists(request.wheels.$txnCallbacks, arguments.connection)
			&& StructKeyExists(request.wheels.$txnCallbacks[arguments.connection], "foreign")
			&& request.wheels.$txnCallbacks[arguments.connection].foreign
		);
	}

	/**
	 * Internal. Record a foreign (raw, non-Wheels) transaction marker for this connection
	 * when one is active. MUST be called by the transaction owner BEFORE opening Wheels'
	 * own transaction (IsWithinTransaction() then still reflects only the outer block).
	 */
	public void function $markForeignTransaction(required string connection) {
		if ($withinForeignTransaction()) {
			request.wheels.$txnCallbacks[arguments.connection] = {real = false, foreign = true, queue = []};
		}
	}

	/**
	 * Internal. Set up the owner's real afterCommit/afterRollback queue — unless this
	 * connection is inside a foreign transaction, where the foreign marker stays in place
	 * and the callbacks are skipped instead.
	 */
	public void function $prepareTransactionCallbackStore(required string connection, required boolean closeTransaction) {
		if (arguments.closeTransaction && !$transactionForeign(arguments.connection)) {
			request.wheels.$txnCallbacks[arguments.connection] = {real = true, queue = []};
		}
	}

	/**
	 * Internal. Drop a foreign-transaction marker set for none/false mode (the commit/
	 * rollback branch clears its own store when it resolves).
	 */
	public void function $clearForeignTransaction(required string connection) {
		if ($transactionForeign(arguments.connection)) {
			StructDelete(request.wheels.$txnCallbacks, arguments.connection);
		}
	}

	/**
	 * Internal. One wheels.log warning per request + model when afterCommit/afterRollback
	 * are skipped because the write ran inside an unmanaged raw transaction{} block.
	 * Guarded so a bulk import inside a raw transaction logs one line, not one per write.
	 */
	public void function $warnForeignTransactionCallbacksOnce() {
		if (!StructKeyExists(request, "wheels")) {
			return;
		}
		if (!StructKeyExists(request.wheels, "$txnForeignWarned")) {
			request.wheels.$txnForeignWarned = {};
		}
		local.modelName = variables.wheels.class.modelName;
		if (StructKeyExists(request.wheels.$txnForeignWarned, local.modelName)) {
			return;
		}
		request.wheels.$txnForeignWarned[local.modelName] = true;
		try {
			writeLog(
				file = "wheels",
				type = "warning",
				text = "afterCommit/afterRollback callbacks on model `" & local.modelName
					& "` were skipped: the write ran inside a raw transaction{} block that Wheels does not "
					& "manage, so the commit/rollback outcome is not observable. Use the Wheels-managed "
					& "transaction (transaction() / invokeWithTransaction) for these callbacks to fire."
			);
		} catch (any e) {
		}
	}

	/**
	 * Internal. Runs this instance's registered callbacks of `type`, filtered by
	 * `operation` (an entry's `on`; blank = all). A throwing callback is logged to
	 * wheels.log (model + method); the database change is NOT rolled back (decision C).
	 * With `propagateErrors` (the default) the exception propagates and stops the rest.
	 * On the exception-unwinding path the caller passes `propagateErrors=false` so a
	 * throwing afterRollback is logged + swallowed and does NOT mask the original
	 * transaction exception the caller is about to rethrow (#3934 R2).
	 */
	public void function $runTransactionCallbacks(required string type, required string operation, boolean propagateErrors = true) {
		if (!StructKeyExists(variables.wheels.class.callbacks, arguments.type)) {
			return;
		}
		local.entries = variables.wheels.class.callbacks[arguments.type];
		local.iEnd = ArrayLen(local.entries);
		for (local.i = 1; local.i <= local.iEnd; local.i++) {
			local.entry = local.entries[local.i];
			local.method = IsStruct(local.entry) ? local.entry.method : local.entry;
			local.on = IsStruct(local.entry) ? (local.entry.on ?: "") : "";
			if (Len(local.on) && !ListFindNoCase(local.on, arguments.operation)) {
				continue;
			}
			try {
				$invoke(method = local.method);
			} catch (any e) {
				try {
					writeLog(
						file = "wheels",
						type = "error",
						text = "A `" & arguments.type & "` callback failed after the transaction resolved on model `"
							& variables.wheels.class.modelName & "`, method `" & local.method & "`: " & e.message
							& (arguments.propagateErrors
								? " - the database change is NOT rolled back; the exception is propagating."
								: " - suppressed so it does not mask the original transaction exception.")
					);
				} catch (any logErr) {
				}
				if (arguments.propagateErrors) {
					rethrow;
				}
			}
		}
	}

	/**
	 * Internal. The per-connection queue array, or an empty array if none.
	 */
	public array function $transactionCallbackQueue(required string connection) {
		if (
			StructKeyExists(request, "wheels")
			&& StructKeyExists(request.wheels, "$txnCallbacks")
			&& StructKeyExists(request.wheels.$txnCallbacks, arguments.connection)
		) {
			return request.wheels.$txnCallbacks[arguments.connection].queue;
		}
		return [];
	}

	/**
	 * Internal. Fire `type` (afterCommit | afterRollback) across a CAPTURED queue
	 * of {object, operation} entries, FIFO; registration order within each
	 * instance. The caller captures the queue and clears both the open-transaction
	 * marker and the context BEFORE calling this, so a throwing callback can never
	 * leave a stuck transaction marker or a leaked queue.
	 */
	public void function $runQueueCallbacks(required array queue, required string type, boolean propagateErrors = true) {
		local.iEnd = ArrayLen(arguments.queue);
		for (local.i = 1; local.i <= local.iEnd; local.i++) {
			local.entry = arguments.queue[local.i];
			local.entry.object.$runTransactionCallbacks(
				type = arguments.type,
				operation = local.entry.operation,
				propagateErrors = arguments.propagateErrors
			);
		}
	}

	/**
	 * Internal. Capture the per-connection queue, CLEAR the context, then fire
	 * `type`. One method so callers (incl. exception catch blocks) do no local-scope
	 * writes in a catch (BoxLang-safe) and so a throwing callback cannot leave the
	 * queue behind. The caller must have already reset the open-transaction marker.
	 */
	public void function $resolveTransactionCallbacks(required string connection, required string type, boolean propagateErrors = true) {
		local.queue = $transactionCallbackQueue(arguments.connection);
		if (StructKeyExists(request, "wheels") && StructKeyExists(request.wheels, "$txnCallbacks")) {
			StructDelete(request.wheels.$txnCallbacks, arguments.connection);
		}
		$runQueueCallbacks(queue = local.queue, type = arguments.type, propagateErrors = arguments.propagateErrors);
	}

	/**
	 * Internal. Length of the owner's real callback queue when a savepoint unit
	 * starts, or -1 when there is no real queue (none/false mode, or a foreign raw
	 * transaction where callbacks are skipped). $rollbackSavepointCallbacks takes
	 * this mark to find the writes made inside the unit.
	 */
	public numeric function $savepointCallbackMark(required string connection) {
		if (
			StructKeyExists(request, "wheels")
			&& StructKeyExists(request.wheels, "$txnCallbacks")
			&& StructKeyExists(request.wheels.$txnCallbacks, arguments.connection)
			&& request.wheels.$txnCallbacks[arguments.connection].real
		) {
			return ArrayLen(request.wheels.$txnCallbacks[arguments.connection].queue);
		}
		return -1;
	}

	/**
	 * Internal. A savepoint unit rolled back: take the queue entries it added
	 * (after `mark`) out of the owner's queue, so they never get afterCommit, and
	 * fire afterRollback for them now (#3958). The rebuilt queue is written back
	 * through the request store, not a returned copy: Adobe CF passes arrays by value.
	 */
	public void function $rollbackSavepointCallbacks(required string connection, required numeric mark, boolean propagateErrors = true) {
		if (arguments.mark < 0 || $savepointCallbackMark(arguments.connection) <= arguments.mark) {
			return;
		}
		local.store = request.wheels.$txnCallbacks[arguments.connection];
		local.kept = [];
		local.rolledBack = [];
		local.iEnd = ArrayLen(local.store.queue);
		for (local.i = 1; local.i <= local.iEnd; local.i++) {
			if (local.i <= arguments.mark) {
				ArrayAppend(local.kept, local.store.queue[local.i]);
			} else {
				ArrayAppend(local.rolledBack, local.store.queue[local.i]);
			}
		}
		request.wheels.$txnCallbacks[arguments.connection].queue = local.kept;
		$runQueueCallbacks(queue = local.rolledBack, type = "afterRollback", propagateErrors = arguments.propagateErrors);
	}

</cfscript>
