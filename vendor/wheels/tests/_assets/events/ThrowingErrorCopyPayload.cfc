/**
 * An ErrorCopyPayload whose build() throws, so AgentReadableErrorsSpec can pin
 * the fallback body the development JSON/Markdown errors use instead.
 */
component extends="wheels.events.onerror.ErrorCopyPayload" output="false" {

	public struct function build(required any wheelsError) {
		throw(type = "UnitTest.PayloadFailure", message = "forced payload failure");
	}

}
