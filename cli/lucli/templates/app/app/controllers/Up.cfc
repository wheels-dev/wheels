component extends="Controller" {

	/**
	 * Liveness / warm-up endpoint.
	 *
	 * `wheels deploy`'s proxy healthcheck probes `/up` before flipping traffic
	 * to a freshly deployed node (the default healthcheck path), and load
	 * balancers can use it as a readiness check. Returning 200 here also
	 * compiles the dispatch -> controller -> render path on the new host, so the
	 * first real visitor sees warm latency instead of the one-time first-request
	 * compile (which is otherwise the bulk of cold-start time).
	 *
	 * To warm your hottest ORM metadata too, touch your key models here before
	 * cutover, e.g.:
	 *
	 *   model("Post").count();
	 *
	 * Keep this action read-only, cheap, and free of authentication so the probe
	 * is never blocked.
	 */
	function index() {
		renderText("OK");
	}

}
