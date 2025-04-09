component {
	/**
	 * Returns the value of a specific key in the Flash (or the entire Flash as a struct if no key is passed in).
	 *
	 * [section: Controller]
	 * [category: Flash Functions]
	 *
	 * @key The key to get the value for.
	 */
	public any function flash(string key) {
		local.flash = $readFlash();
		if (StructKeyExists(arguments, "key")) {
			if (flashKeyExists(key = arguments.key)) {
				local.flash = local.flash[arguments.key];
			} else {
				local.flash = "";
			}
		}

		// We can just return the flash since it is created at the beginning of the request.
		// This way we always return what is expected - a struct.
		return local.flash;
	}

	/**
	 * Deletes everything from the Flash.
	 *
	 * [section: Controller]
	 * [category: Flash Functions]
	 */
	public void function flashClear() {
		$writeFlash();
	}

	/**
	 * Returns how many keys exist in the Flash.
	 *
	 * [section: Controller]
	 * [category: Flash Functions]
	 */
	public numeric function flashCount() {
		local.flash = $readFlash();
		local.rv = StructCount(local.flash);
		return local.rv;
	}

	/**
	 * Deletes a specific key from the Flash.
	 * Returns `true` if the key exists.
	 *
	 * [section: Controller]
	 * [category: Flash Functions]
	 *
	 * @key The key to delete
	 */
	public any function flashDelete(required string key) {
		local.flash = $readFlash();
		local.rv = StructDelete(local.flash, arguments.key, true);
		$writeFlash(local.flash);
		return local.rv;
	}

	/**
	 * Inserts a new key / value into the Flash.
	 *
	 * [section: Controller]
	 * [category: Flash Functions]
	 */
	public void function flashInsert() {
		local.flash = $readFlash();

		for (local.key in arguments) {
			// Does the user want us to append new messages or just replace?
			if ($getFlashAppend() && StructKeyExists(local.flash, local.key)) {
				// Are we dealing with just an existing string or an array?
				if (IsArray(local.flash[local.key])) {
					ArrayAppend(local.flash[local.key], arguments[local.key]);
				} else {
					// Capture previous value, make it an array and append new value
					local.tempArr = [];
					ArrayAppend(local.tempArr, local.flash[local.key]);
					ArrayAppend(local.tempArr, arguments[local.key]);
					StructInsert(local.flash, local.key, local.tempArr, true);
				}
			} else {
				StructInsert(local.flash, local.key, arguments[local.key], true);
			}
		}
		$writeFlash(local.flash);
	}

	/**
	 * Returns whether or not the Flash is empty.
	 *
	 * [section: Controller]
	 * [category: Flash Functions]
	 */
	public boolean function flashIsEmpty() {
		if (flashCount()) {
			return false;
		} else {
			return true;
		}
	}

	/**
	 * Make the entire Flash or specific key in it stick around for one more request.
	 *
	 * [section: Controller]
	 * [category: Flash Functions]
	 */
	public void function flashKeep(string key = "") {
		$args(args = arguments, name = "flashKeep", combine = "key/keys");
		request.wheels.flashKeep = arguments.key;
	}

	/**
	 * Checks if a specific key exists in the Flash.
	 *
	 * [section: Controller]
	 * [category: Flash Functions]
	 *
	 * @key The key to check.
	 */
	public boolean function flashKeyExists(required string key) {
		local.flash = $readFlash();
		return StructKeyExists(local.flash, arguments.key);
	}

	/**
	 * Internal function.
	 */
	public struct function $readFlash() {
		local.rv = {};
		if (!StructKeyExists(arguments, "$locked")) {
			local.lockName = "flashLock" & application.applicationName;
			local.rv = $simpleLock(name = local.lockName, type = "readonly", execute = "$readFlash", executeArgs = arguments);
		} else if ($getFlashStorage() == "cookie" && StructKeyExists(cookie, "flash")) {
			if (isJSON(cookie.flash)) {
				local.rv = DeserializeJSON(cookie.flash);
			} else {
				local.rv = {
					"action": cookie.flash
				};
			}
		} else if ($getFlashStorage() == "session" && StructKeyExists(session, "flash")) {
			if (isStruct(session.flash)) {
				local.rv = Duplicate(session.flash);
			} else {
				local.rv = {
					"action": Duplicate(session.flash)
				};
			}
		}
		return local.rv;
	}

	/**
	 * Internal function.
	 */
	public any function $writeFlash(struct flash = {}) {
		if (!StructKeyExists(arguments, "$locked")) {
			local.lockName = "flashLock" & application.applicationName;
			local.rv = $simpleLock(name = local.lockName, type = "exclusive", execute = "$writeFlash", executeArgs = arguments);
		} else {
			if ($getFlashStorage() == "cookie") {
				cookie.flash = SerializeJSON(arguments.flash);
			} else if ($getFlashStorage() == "session") {
				session.flash = arguments.flash;
			}
		}
		if (StructKeyExists(local, "rv")) {
			return local.rv;
		}
	}

	/**
	 * Internal function.
	 */
	public void function $flashClear() {
		// Only save the old flash if they want to keep anything.
		if (StructKeyExists(request.wheels, "flashKeep")) {
			local.flash = $readFlash();
		}

		// Clear the current flash.
		flashClear();

		// See if they wanted to keep anything.
		if (StructKeyExists(local, "flash")) {
			// Delete any keys they don't want to keep.
			if (Len(request.wheels.flashKeep)) {
				for (local.key in local.flash) {
					if (!ListFindNoCase(request.wheels.flashKeep, local.key)) {
						StructDelete(local.flash, local.key);
					}
				}
			}

			// Write to the flash.
			$writeFlash(local.flash);
		}
	}

	/**
	 * Internal function.
	 */
	public void function $setFlashStorage(required string storage) {
		variables.$class.flashStorage = arguments.storage;
	}

	/**
	 * Internal function.
	 */
	public string function $getFlashStorage() {
		return variables.$class.flashStorage;
	}

	/**
	 * Internal function.
	 */
	public void function $setFlashAppend(required boolean append) {
		variables.$class.flashAppend = arguments.append;
	}

	/**
	 * Internal function.
	 */
	public string function $getFlashAppend() {
		return variables.$class.flashAppend;
	}
}
