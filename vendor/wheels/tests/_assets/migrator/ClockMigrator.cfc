/**
 * Test double for the migration lock's waits (PR A of the approved performance slice).
 *
 * The migrator's lock code reads the inherited $tick() from wheels.Global and waits through the
 * new $sleep() passthrough. Under travelTo() the clock is frozen at request.$wheelsClock.tick, so
 * this double advances that frozen tick by the requested wait instead of sleeping. Outside
 * travelTo() there is no frozen clock and it behaves exactly like the production migrator.
 */
component extends="wheels.Migrator" output=false {

	public void function $sleep(required numeric milliseconds) {
		if (
			StructKeyExists(request, "$wheelsClock")
			&& StructKeyExists(request.$wheelsClock, "tick")
		) {
			request.$wheelsClock.tick = request.$wheelsClock.tick + arguments.milliseconds;
			return;
		}
		Sleep(arguments.milliseconds);
	}

}
