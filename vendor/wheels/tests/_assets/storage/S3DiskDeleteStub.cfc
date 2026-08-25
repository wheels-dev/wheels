component extends="wheels.storage.drivers.S3Disk" {

	public struct function $request(
		required string method,
		required string key,
		required struct headers,
		any body = "",
		string contentType = "",
		boolean getAsBinary = false
	) {
		return {statusCode = "204 No Content", fileContent = ""};
	}

}
