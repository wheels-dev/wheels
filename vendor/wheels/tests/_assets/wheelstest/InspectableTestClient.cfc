/**
 * A TestClient that exposes the headers and cookies it would send, so
 * TestClientContextSpec can check them right after init() without making a
 * request.
 */
component extends="wheels.wheelstest.TestClient" {

	public struct function capturedDefaults() {
		return {headers = StructCopy(variables.defaultHeaders), cookies = StructCopy(variables.cookies)};
	}

}
