component extends="wheels.WheelsTest" {

	/*
	 * Regression spec for issue 3770.
	 *
	 * A reload runs applicationStop() while it holds the exclusive reload lock.
	 * BoxLang ends the active sessions on ForkJoin worker threads inside that
	 * call, and each onSessionEnd asks for the read lock of the same name, so
	 * every session end waited out its 180 s lock timeout (and then never ran).
	 *
	 * $simpleLock now marks the application scope while the exclusive restart
	 * runs, and a read-locked session end that finds the marker for its own lock
	 * in the application scope it was handed runs without waiting: the only
	 * writer is the restart, parked waiting for exactly that work.
	 */

	variables.PROBE = "wheels.tests._assets.global.RestartLockProbe";

	// Hold the exclusive lock NAME on another thread for holdMs.
	private string function $holdExclusiveOnOtherThread(required string lockName, numeric holdMs = 3000) {
		var threadName = "restartLockHolder_" & Replace(CreateUUID(), "-", "", "all");
		thread name="#threadName#" action="run" lockName="#arguments.lockName#" holdMs="#arguments.holdMs#" {
			lock name="#attributes.lockName#" type="exclusive" timeout="10" {
				sleep(attributes.holdMs);
			}
		}
		// Give the holder time to take the lock.
		sleep(500);
		return threadName;
	}

	private void function $joinThread(required string threadName) {
		thread action="join" name="#arguments.threadName#" timeout="15000";
	}

	private struct function $sessionEndArgs(required struct appScope) {
		return {
			componentReference = variables.PROBE,
			sessionScope = {},
			applicationScope = arguments.appScope
		};
	}

	private struct function $restartMarker(required string lockName, numeric expiresInSeconds = 120) {
		return {
			name = arguments.lockName,
			token = CreateUUID(),
			expiresAt = DateAdd("s", arguments.expiresInSeconds, Now())
		};
	}

	function run() {

		describe("$simpleLock during a restart (issue 3770)", () => {

			beforeEach(() => {
				request.$restartLockProbe = {sawMarker = false, sessionEndRan = false};
			});

			afterEach(() => {
				StructDelete(application, "$wheelsRestartLock");
			});

			describe("the exclusive restart path", () => {

				it("marks the application scope with this lock while the restart runs", () => {
					var lockName = "restartLockSpec_" & CreateUUID();
					application.wo.$simpleLock(
						name = lockName,
						type = "exclusive",
						execute = "$handleRestartAppRequest",
						executeArgs = {componentReference = variables.PROBE},
						timeout = 5
					);
					expect(request.$restartLockProbe.sawMarker).toBeTrue();
					expect(request.$restartLockProbe.marker.name).toBe(lockName);
					expect(Len(request.$restartLockProbe.marker.token)).toBeGT(0);
					expect(IsDate(request.$restartLockProbe.marker.expiresAt)).toBeTrue();
				});

				it("clears the marker after the restart returns", () => {
					application.wo.$simpleLock(
						name = "restartLockSpec_" & CreateUUID(),
						type = "exclusive",
						execute = "$handleRestartAppRequest",
						executeArgs = {componentReference = variables.PROBE},
						timeout = 5
					);
					expect(StructKeyExists(application, "$wheelsRestartLock")).toBeFalse();
				});

				it("clears the marker when the restart throws", () => {
					var state = {threw = false};
					try {
						application.wo.$simpleLock(
							name = "restartLockSpec_" & CreateUUID(),
							type = "exclusive",
							execute = "$handleRestartAppRequest",
							executeArgs = {componentReference = variables.PROBE, shouldThrow = true},
							timeout = 5
						);
					} catch (any e) {
						state.threw = true;
					}
					expect(state.threw).toBeTrue();
					expect(request.$restartLockProbe.sawMarker).toBeTrue();
					expect(StructKeyExists(application, "$wheelsRestartLock")).toBeFalse();
				});

				it("does not mark the scope for other exclusive work", () => {
					application.wo.$simpleLock(
						name = "restartLockSpec_" & CreateUUID(),
						type = "exclusive",
						execute = "$runOnSessionEnd",
						executeArgs = $sessionEndArgs({}),
						timeout = 5
					);
					expect(request.$restartLockProbe.sessionEndRan).toBeTrue();
					expect(StructKeyExists(application, "$wheelsRestartLock")).toBeFalse();
				});

			});

			describe("a read-locked session end while another thread holds the lock", () => {

				it("runs promptly when the scope it was handed carries this lock's restart marker", () => {
					var lockName = "restartLockSpec_" & CreateUUID();
					var appScope = {wheels = {eventPath = "/app/events"}, "$wheelsRestartLock" = $restartMarker(lockName)};
					var holder = $holdExclusiveOnOtherThread(lockName);
					var started = GetTickCount();
					application.wo.$simpleLock(
						name = lockName,
						type = "readOnly",
						execute = "$runOnSessionEnd",
						executeArgs = $sessionEndArgs(appScope),
						timeout = 2
					);
					var elapsed = GetTickCount() - started;
					$joinThread(holder);
					expect(request.$restartLockProbe.sessionEndRan).toBeTrue();
					expect(elapsed).toBeLT(1500);
				});

				it("still waits for the lock when there is no restart marker", () => {
					var lockName = "restartLockSpec_" & CreateUUID();
					var state = {threw = false};
					var holder = $holdExclusiveOnOtherThread(lockName);
					try {
						application.wo.$simpleLock(
							name = lockName,
							type = "readOnly",
							execute = "$runOnSessionEnd",
							executeArgs = $sessionEndArgs({wheels = {eventPath = "/app/events"}}),
							timeout = 1
						);
					} catch (any e) {
						state.threw = true;
					}
					$joinThread(holder);
					expect(state.threw).toBeTrue();
					expect(request.$restartLockProbe.sessionEndRan).toBeFalse();
				});

				it("still waits for the lock when the marker names a different lock", () => {
					var lockName = "restartLockSpec_" & CreateUUID();
					var state = {threw = false};
					var appScope = {wheels = {eventPath = "/app/events"}, "$wheelsRestartLock" = $restartMarker("someOtherLock")};
					var holder = $holdExclusiveOnOtherThread(lockName);
					try {
						application.wo.$simpleLock(
							name = lockName,
							type = "readOnly",
							execute = "$runOnSessionEnd",
							executeArgs = $sessionEndArgs(appScope),
							timeout = 1
						);
					} catch (any e) {
						state.threw = true;
					}
					$joinThread(holder);
					expect(state.threw).toBeTrue();
					expect(request.$restartLockProbe.sessionEndRan).toBeFalse();
				});

				it("still waits for the lock when the marker has expired", () => {
					var lockName = "restartLockSpec_" & CreateUUID();
					var state = {threw = false};
					var appScope = {wheels = {eventPath = "/app/events"}, "$wheelsRestartLock" = $restartMarker(lockName, -5)};
					var holder = $holdExclusiveOnOtherThread(lockName);
					try {
						application.wo.$simpleLock(
							name = lockName,
							type = "readOnly",
							execute = "$runOnSessionEnd",
							executeArgs = $sessionEndArgs(appScope),
							timeout = 1
						);
					} catch (any e) {
						state.threw = true;
					}
					$joinThread(holder);
					expect(state.threw).toBeTrue();
					expect(request.$restartLockProbe.sessionEndRan).toBeFalse();
				});

				it("returns without running or waiting when the marked scope is already torn down", () => {
					var lockName = "restartLockSpec_" & CreateUUID();
					var appScope = {"$wheelsRestartLock" = $restartMarker(lockName)};
					var holder = $holdExclusiveOnOtherThread(lockName);
					var started = GetTickCount();
					application.wo.$simpleLock(
						name = lockName,
						type = "readOnly",
						execute = "$runOnSessionEnd",
						executeArgs = $sessionEndArgs(appScope),
						timeout = 2
					);
					var elapsed = GetTickCount() - started;
					$joinThread(holder);
					expect(request.$restartLockProbe.sessionEndRan).toBeFalse();
					expect(elapsed).toBeLT(1500);
				});

			});

		});

	}

}
