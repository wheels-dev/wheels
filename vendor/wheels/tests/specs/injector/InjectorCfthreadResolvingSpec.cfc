/**
 * #4448: the Injector's circular-dependency guard was keyed on a request-scoped struct shared by a
 * request's cfthreads (on Lucee a cfthread shares its parent's request scope). While one thread was
 * inside a slow init() of transient service X — holding X in the resolving stack — a second thread's
 * getInstance("X") saw X already present and threw a spurious Wheels.DI.CircularDependency. Keying the
 * stack by thread id fixes it while keeping the request-scoped outer struct's #2331 semantics.
 *
 * This is deterministic (no timing sleeps): LatchedService.init() holds the FIRST thread inside init()
 * via a latch until the second thread has gone through the guard. Threads are spawned from a component
 * method, not an it() closure — cfthread can't be declared in a closure on Lucee. The latches are
 * java.util.concurrent, so the spec skips on an engine without them (e.g. a JVM-free one).
 */
component extends="wheels.WheelsTest" {

	function run() {

		describe("Injector circular-dependency guard across a request's cfthreads (4448)", () => {

			it("does not throw a spurious CircularDependency when two threads resolve the same transient at once", () => {
				if (!$di4448Supported()) {
					skip("requires java.util.concurrent latches (JVM engine)");
				}
				var results = $runDiConcurrencyProbe();
				expect(results.t1).toBe("ok");
				expect(results.t2).toBe("ok");
			});

		});

	}

	private boolean function $di4448Supported() {
		try {
			CreateObject("java", "java.util.concurrent.CountDownLatch").init(JavaCast("int", 1));
			return true;
		} catch (any e) {
			return false;
		}
	}

	/**
	 * Spawn two cfthreads that resolve the same transient service concurrently, overlapped so thread 2
	 * passes the guard while thread 1 is inside the service's init(). Returns both thread results.
	 */
	private struct function $runDiConcurrencyProbe() {
		application.$di4448 = {
			started = CreateObject("java", "java.util.concurrent.CountDownLatch").init(JavaCast("int", 1)),
			proceed = CreateObject("java", "java.util.concurrent.CountDownLatch").init(JavaCast("int", 1)),
			firstTaken = CreateObject("java", "java.util.concurrent.atomic.AtomicBoolean").init(JavaCast("boolean", false))
		};
		var di = new wheels.Injector(binderPath = "wheels.tests._assets.di.TestBindings");
		di.map("latched4448").to("wheels.tests._assets.di.LatchedService");
		application.$di4448Injector = di;

		try {
			thread name="di4448_t1" action="run" {
				thread.result = "unset";
				try {
					application.$di4448Injector.getInstance("latched4448");
					thread.result = "ok";
				} catch (any e) {
					thread.result = e.type;
				}
			}
			thread name="di4448_t2" action="run" {
				thread.result = "unset";
				try {
					// Wait until t1 is inside init() (holding the guard), then resolve.
					application.$di4448.started.await(
						JavaCast("long", 10),
						CreateObject("java", "java.util.concurrent.TimeUnit").SECONDS
					);
					application.$di4448Injector.getInstance("latched4448");
					thread.result = "ok";
				} catch (any e) {
					thread.result = e.type;
				} finally {
					// Release t1 whether t2 passed or threw, so t1 always finishes.
					application.$di4448.proceed.countDown();
				}
			}
			thread action="join" name="di4448_t1,di4448_t2" timeout="20000";
			return {t1 = cfthread.di4448_t1.result, t2 = cfthread.di4448_t2.result};
		} finally {
			StructDelete(application, "$di4448");
			StructDelete(application, "$di4448Injector");
		}
	}

}
