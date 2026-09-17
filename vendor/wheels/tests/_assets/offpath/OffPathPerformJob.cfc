/**
 * Off-path component with perform(). S8: CreateObject must not run this
 * just because perform() exists. The component body sets a request flag so
 * specs can see whether instantiation happened at all.
 */
component {

	if (!StructKeyExists(request, "$wheelsOffPathConstructed")) {
		request.$wheelsOffPathConstructed = true;
	}

	public void function perform(struct data = {}) {
		request.$wheelsOffPathRan = true;
	}

}
