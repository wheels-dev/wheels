/**
 * File-permission operations for files that hold secrets. Separate so the
 * failure path can be exercised in specs.
 */
component {

	/**
	 * chmod 600. Returns true when applied, false on a platform without POSIX
	 * file modes (Windows). Any other failure is thrown to the caller, which
	 * must not continue as though the file were protected.
	 */
	public boolean function ownerOnly(required string path) {
		if (findNoCase("windows", server.os.name)) {
			return false;
		}
		fileSetAccessMode(arguments.path, "600");
		return true;
	}

}
