/**
 * Test fixture for #4448: a transient service whose init() deterministically holds the Injector's
 * circular-dependency guard open for one thread while a second thread checks it.
 *
 * The FIRST thread to construct it signals `started` (it is now inside init(), so its name is in the
 * resolving stack) and then blocks on `proceed`; the second thread waits for `started`, does its own
 * getInstance (which is where the spurious CircularDependency used to throw), then releases `proceed`.
 * Latches live in application scope so they are shared whether or not a cfthread shares the parent's
 * request scope. Only the first construction coordinates — later ones return immediately — so the
 * post-fix path (both threads construct) cannot deadlock.
 */
component {

	public any function init() {
		if (StructKeyExists(application, "$di4448")) {
			var state = {mine = application.$di4448.firstTaken.compareAndSet(JavaCast("boolean", false), JavaCast("boolean", true))};
			if (state.mine) {
				application.$di4448.started.countDown();
				application.$di4448.proceed.await(
					JavaCast("long", 10),
					CreateObject("java", "java.util.concurrent.TimeUnit").SECONDS
				);
			}
		}
		return this;
	}

}
