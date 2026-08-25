component extends="wheels.storage.drivers.S3Disk" {

	variables.objects = {};
	variables.lastRequest = {};

	public void function seed(required string key) {
		variables.objects[arguments.key] = true;
	}

	public struct function lastRequest() {
		return variables.lastRequest;
	}

	public struct function $request(
		required string method,
		required string key,
		required struct headers,
		any body = "",
		string contentType = "",
		boolean getAsBinary = false
	) {
		local.copiedHeaders = {};
		for (local.name in arguments.headers) {
			local.copiedHeaders[local.name] = arguments.headers[local.name];
		}
		variables.lastRequest = {
			method = arguments.method,
			key = arguments.key,
			headers = local.copiedHeaders,
			contentType = arguments.contentType
		};

		if (arguments.method == "HEAD") {
			if (StructKeyExists(variables.objects, arguments.key)) {
				return {statusCode = "200 OK", fileContent = ""};
			}
			return {statusCode = "404 Not Found", fileContent = ""};
		}
		if (arguments.method == "DELETE") {
			StructDelete(variables.objects, arguments.key);
			return {statusCode = "204 No Content", fileContent = ""};
		}
		if (arguments.method == "PUT") {
			variables.objects[arguments.key] = true;
			return {statusCode = "200 OK", fileContent = ""};
		}
		return {statusCode = "200 OK", fileContent = ""};
	}

}
