component {
	/**
	 * Sends an email using a template and an optional layout to wrap it in.
	 * Besides the Wheels-specific arguments documented here, you can also pass in any argument that is accepted by the `cfmail` tag as well as your own arguments to be used by the view.
	 * Note that only arguments whose names match a known `cfmail` attribute are passed through to `cfmail`; every other argument is made available to the email view as a variable instead.
	 *
	 * [section: Controller]
	 * [category: Miscellaneous Functions]
	 *
	 * @template The path to the email template or two paths if you want to send a multipart email (a maximum of two templates, one text and one html version, is supported). if the `detectMultipart` argument is `false`, the template for the text version should be the first one in the list. This argument is also aliased as `templates`.
	 * @from Email address to send from.
	 * @to List of email addresses to send the email to.
	 * @subject The subject line of the email.
	 * @layout Layout(s) to wrap the email template in. This argument is also aliased as `layouts`.
	 * @file A list of the names of the files to attach to the email. This will reference files stored in the `files` folder (or a path relative to it). This argument is also aliased as `files`.
	 * @detectMultipart When set to `true` and multiple values are provided for the `template` argument, Wheels will detect which of the templates is text and which one is HTML (by counting the `<` characters).
	 * @deliver When set to `false`, the email will not be sent.
	 * @writeToFile The file to which the email contents will be written
	 */
	public any function sendEmail(
		string template = "",
		required string from,
		required string to,
		required string subject,
		any layout,
		string file = "",
		boolean detectMultipart,
		boolean deliver,
		string writeToFile = ""
	) {
		local.writeToFile = Duplicate(arguments.writeToFile);
		$args(
			args = arguments,
			name = "sendEmail",
			combine = "template/templates/!,layout/layouts,file/files",
			required = "template,from,to,subject"
		);
		local.deliver = Duplicate(arguments.deliver);
		local.nonPassThruArgs = "writetofile,template,templates,layout,layouts,file,files,detectMultipart,deliver";
		local.mailTagArgs = "from,to,bcc,cc,charset,debug,encrypt,encryptionalgorithm,failto,group,groupcasesensitive,keyalias,keypassword,keystore,keystorepassword,mailerid,mailparams,maxrows,mimeattach,password,port,priority,query,recipientcert,replyto,server,sign,spoolenable,startrow,subject,timeout,type,username,useSSL,useTLS,wraptext,remove";

		// Coerce a zero-length layout to `false` (no layout) so the layout list below always has at least one entry.
		if (!Len(arguments.layout)) {
			arguments.layout = false;
		}

		// Multipart emails support a maximum of two templates (one text and one html version).
		if (ListLen(arguments.template) > 2) {
			Throw(
				type = "Wheels.IncorrectArguments",
				message = "The `template` argument passed to `sendEmail` contains #ListLen(arguments.template)# templates but a maximum of `2` (one text and one html version) is supported.",
				extendedInfo = "Pass in one template for a single part email or two templates for a multipart (text and html) email."
			);
		}

		// If two templates but only one layout was passed in we set the same layout to be used on both.
		if (ListLen(arguments.template) > 1 && ListLen(arguments.layout) == 1) {
			arguments.layout = ListAppend(arguments.layout, arguments.layout);
		}

		// Set the variables that should be available to the email view template (i.e. the custom named arguments passed in by the developer).
		// We snapshot what we touch so the controller's `variables` scope can be restored after rendering (otherwise the custom arguments would leak into, or overwrite parts of, the rest of the request).
		local.customViewVariables = [];
		local.shadowedVariables = {};
		for (local.key in arguments) {
			if (!ListFindNoCase(local.nonPassThruArgs, local.key) && !ListFindNoCase(local.mailTagArgs, local.key)) {
				if (StructKeyExists(variables, local.key)) {
					local.shadowedVariables[local.key] = variables[local.key];
				}
				ArrayAppend(local.customViewVariables, local.key);
				variables[local.key] = arguments[local.key];
				StructDelete(arguments, local.key);
			}
		}

		// Get the content of the email templates and store them as cfmailparts.
		arguments.mailparts = [];
		local.templateArray = ListToArray(arguments.template);
		local.layoutArray = ListToArray(arguments.layout);
		local.iEnd = ArrayLen(local.templateArray);
		for (local.i = 1; local.i <= local.iEnd; local.i++) {
			// Include the email template and return it,
			local.item = local.templateArray[local.i];
			local.content = $renderView($template = local.item, $layout = local.layoutArray[local.i]);

			local.mailpart = {};
			local.mailpart.tagContent = local.content;
			if (ArrayIsEmpty(arguments.mailparts)) {
				ArrayAppend(arguments.mailparts, local.mailpart);
			} else {
				if (arguments.detectMultipart) {
					// Make sure the text version is the first one in the array.
					local.existingContentCount = ListLen(arguments.mailparts[1].tagContent, "<");
					local.newContentCount = ListLen(local.content, "<");
					if (local.newContentCount < local.existingContentCount) {
						ArrayPrepend(arguments.mailparts, local.mailpart);
					} else {
						ArrayAppend(arguments.mailparts, local.mailpart);
					}
				} else {
					// When multipart detection is turned off we preserve the order that the templates were passed in (text version first).
					ArrayAppend(arguments.mailparts, local.mailpart);
				}
				arguments.mailparts[1].type = "text";
				arguments.mailparts[2].type = "html";
			}
		}

		// Restore the controller's `variables` scope now that the email templates have been rendered.
		local.iEnd = ArrayLen(local.customViewVariables);
		for (local.i = 1; local.i <= local.iEnd; local.i++) {
			local.key = local.customViewVariables[local.i];
			if (StructKeyExists(local.shadowedVariables, local.key)) {
				variables[local.key] = local.shadowedVariables[local.key];
			} else {
				StructDelete(variables, local.key);
			}
		}

		// Return a struct containing mailpart content using type as the key.
		local.rv = {};
		local.rv["html"] = "";
		local.rv["text"] = "";

		// Figure out if the email should be sent as html or text when only one template is used and the developer did not specify the type explicitly.
		if (ArrayLen(arguments.mailparts) == 1) {
			arguments.tagContent = arguments.mailparts[1].tagContent;
			StructDelete(arguments, "mailparts");
			if (arguments.detectMultipart && !StructKeyExists(arguments, "type")) {
				if (Find("<", arguments.tagContent) && Find(">", arguments.tagContent)) {
					arguments.type = "html";
				} else {
					arguments.type = "text";
				}
			} else if (!StructKeyExists(arguments, "type")) {
				// Match the default of the `cfmail` tag itself when multipart detection is turned off.
				arguments.type = "text";
			}
			local.rv[arguments.type] = arguments.tagContent;
		} else {
			// Return a struct containing mailparts using type the the key.
			local.iEnd = ArrayLen(arguments.mailparts);
			for (local.i = 1; local.i <= local.iEnd; local.i++) {
				local.rv[arguments.mailparts[local.i].type] = arguments.mailparts[local.i].tagContent;
			}
		}

		// Attach files using the cfmailparam tag.
		if (Len(arguments.file)) {
			arguments.mailparams = [];
			local.fileArray = ListToArray(arguments.file);
			local.iEnd = ArrayLen(local.fileArray);
			for (local.i = 1; local.i <= local.iEnd; local.i++) {
				local.item = local.fileArray[local.i];
				arguments.mailparams[local.i] = {};
				if (!ReFindNoCase("\\|/", local.item)) {
					// no directory delimiter is present so append the path
					local.item = ExpandPath($get("filePath")) & "/" & local.item;
				}
				arguments.mailparams[local.i].file = local.item;
			}
		}

		// Delete arguments that we don't want to pass through to the cfmail tag.
		local.nonPassThruKeysArray = ListToArray(local.nonPassThruArgs);
		local.iEnd = ArrayLen(local.nonPassThruKeysArray);
		for (local.i = 1; local.i <= local.iEnd; local.i++) {
			local.item = local.nonPassThruKeysArray[local.i];
			StructDelete(arguments, local.item);
		}

		// Also return the args passed to cfmail but delete "tagContent" since we already have that as either "text" or "html".
		StructAppend(local.rv, arguments);
		StructDelete(local.rv, "tagContent");

		// Write the email body to file (the text and html versions separated by a blank line when both exist).
		// Plain concatenation is used because CFML list functions treat each character of a multi-character delimiter as a separate delimiter.
		if (Len(local.writeToFile)) {
			if (Len(local.rv.text) && Len(local.rv.html)) {
				local.output = local.rv.text & Chr(13) & Chr(10) & Chr(13) & Chr(10) & local.rv.html;
			} else {
				local.output = local.rv.text & local.rv.html;
			}
			$file(action = "write", file = "#local.writeToFile#", output = "#local.output#");
		}

		// Send the email using the cfmail tag.
		if (local.deliver) {
			$mail(argumentCollection = arguments);
		} else {
			if (!$sentEmails()) {
				variables.$instance.emails = [];
			}
			ArrayAppend(variables.$instance.emails, local.rv);
		}

		return local.rv;
	}

	/**
	 * Sends a file to the user (from the `files` folder or a path relative to it by default).
	 *
	 * [section: Controller]
	 * [category: Miscellaneous Functions]
	 *
	 * @file The file to send to the user.
	 * @name The file name to show in the browser download dialog box.
	 * @type The HTTP content type to deliver the file as.
	 * @disposition Set to `inline` to have the browser handle the opening of the file (possibly inline in the browser) or set to `attachment` to force a download dialog box.
	 * @directory Directory outside of the web root where the file exists. Must be a full path.
	 * @deleteFile Pass in `true` to delete the file on the server after sending it.
	 * @deliver When set to `false`, the file will not be sent to the browser (used for testing).
	 */
	public any function sendFile(
		required string file,
		string name = "",
		string type = "",
		string disposition,
		string directory = "",
		boolean deleteFile = false,
		boolean deliver
	) {
		$args(name = "sendFile", args = arguments);

		// Strip null bytes and check for path traversal after URL-decoding and normalizing backslashes so encoded variants are caught as well (same guard as `$generateIncludeTemplatePath`).
		arguments.file = Replace(arguments.file, Chr(0), "", "all");
		arguments.directory = Replace(arguments.directory, Chr(0), "", "all");
		if (
			Find("..", Replace(URLDecode(arguments.file), "\", "/", "all"))
			|| Find("..", Replace(URLDecode(arguments.directory), "\", "/", "all"))
		) {
			Throw(
				type = "Wheels.InvalidPath",
				message = "The `file` or `directory` argument passed to `sendFile` contains invalid path characters.",
				extendedInfo = "These arguments must not contain `..` (including URL-encoded variants) so that files outside the intended folder cannot be accessed."
			);
		}

		// Check whether the resource is a ram resource or physical file.
		if (!ListFirst(arguments.file, "://") == "ram") {
			local.relativeRoot = $get("rootPath");
			if (Right(local.relativeRoot, 1) != "/") {
				local.relativeRoot &= "/";
			}
			local.root = ExpandPath(local.relativeRoot);
			local.folder = arguments.directory;
			if (!Len(local.folder)) {
				local.folder = local.relativeRoot & $get("filePath");
			}
			if (Left(local.folder, Len(local.root)) == local.root) {
				local.folder = RemoveChars(local.folder, 1, Len(local.root));
			}
			local.fullPath = Replace(local.folder, "\", "/", "all");
			local.fullPath = ListAppend(local.fullPath, arguments.file, "/");
			// https://github.com/wheels-dev/wheels/issues/873 Don't expand path if already contains root
			if (local.fullPath DOES NOT CONTAIN Replace(local.root, "\", "/", "all")) {
				//added this section for the "/wheels" mapping to work correctly
				if (local.fullPath CONTAINS "/wheels") {
					local.startPos = findNoCase("/wheels", local.fullPath);
					
					// Prefer /vendor/wheels if available
					local.vendorWheelsPos = findNoCase("/vendor/wheels/", local.fullPath);
					if (local.vendorWheelsPos > 0) {
						local.startPos = local.vendorWheelsPos + len("/vendor");
					}

					if (local.startPos > 0) {
						local.fullPath = ExpandPath(mid(local.fullPath, local.startPos, len(local.fullPath) - local.startPos + 1));
						local.fullPath = Replace(local.fullPath, "\", "/", "all");
						local.file = ListLast(local.fullPath, "/");
						local.directory = Reverse(ListRest(Reverse(local.fullPath), "/"));
					}
				} else{
					local.fullPath = ExpandPath(local.fullPath);
					local.fullPath = Replace(local.fullPath, "\", "/", "all");
					local.file = ListLast(local.fullPath, "/");
					local.directory = Reverse(ListRest(Reverse(local.fullPath), "/"));
				}
			}

			// If the file is not found, try searching for it.
			if (!FileExists(local.fullPath)) {
				local.match = $directory(action = "list", directory = local.directory, filter = "#local.file#.*");

				// Only extract the extension if we find a single match.
				if (local.match.recordCount == 1) {
					local.file &= "." & ListLast(local.match.name, ".");
					local.fullPath = local.directory & "/" & local.file;
				} else {
					Throw(
						type = "Wheels.FileNotFound",
						message = "A file could not be found.",
						extendedInfo = "Make sure a file with the name `#local.file#` exists in the `#local.directory#` folder."
					);
				}
			}
			local.name = local.file;
		} else {
			local.fullPath = arguments.file;
			local.file = arguments.file;

			// For ram:// resources, skip the physical file check but still check the thing exists.
			if (!FileExists(local.fullPath)) {
				Throw(
					type = "Wheels.FileNotFound",
					message = "ram:// resource could not be found.",
					extendedInfo = "Make sure a resource with the name `#local.file#` exists in memory"
				);
			}

			// Make the default display name behaviour the same as physical files.
			local.name = Replace(arguments.file, "ram://", "", "one");
		}

		local.extension = ListLast(local.file, ".");

		// Replace the display name for the file if supplied.
		if (Len(arguments.name)) {
			local.name = arguments.name;
		}

		// Strip CR / LF / double quotes / backslashes from the display name so it cannot break out of the quoted `filename` parameter in the `Content-Disposition` header.
		local.name = ReReplace(local.name, "[\r\n""\\]", "", "all");

		local.mime = arguments.type;
		if (!Len(local.mime)) {
			local.mime = mimeTypes(local.extension);
		}

		// If testing, return the variables, else prompt the user to download the file.
		if (arguments.deliver) {
			$header(name = "Content-Disposition", value = "#arguments.disposition#; filename=""#local.name#""");
			$content(type = local.mime, file = local.fullPath, deleteFile = arguments.deleteFile);
		} else {
			local.rv = {disposition = arguments.disposition, file = local.fullPath, mime = local.mime, name = local.name};
			if (!$sentFiles()) {
				variables.$instance.files = [];
			}
			ArrayAppend(variables.$instance.files, local.rv);
			return local.rv;
		}
	}

	/**
	 * Returns whether Wheels is communicating over a secure port.
	 *
	 * [section: Controller]
	 * [category: Miscellaneous Functions]
	 */
	public boolean function isSecure() {
		return request.cgi.http_x_forwarded_proto == "https" || request.cgi.server_port_secure == "true";
	}

	/**
	 * Returns whether the page was called from JavaScript or not.
	 *
	 * [section: Controller]
	 * [category: Miscellaneous Functions]
	 */
	public boolean function isAjax() {
		return request.cgi.http_x_requested_with == "XMLHTTPRequest";
	}

	/**
	 * Returns whether the request was a normal `GET` request or not.
	 *
	 * [section: Controller]
	 * [category: Miscellaneous Functions]
	 */
	public boolean function isGet() {
		return request.cgi.request_method == "get";
	}

	/**
	 * Returns whether the request came from a form `POST` submission or not.
	 *
	 * [section: Controller]
	 * [category: Miscellaneous Functions]
	 */
	public boolean function isPost() {
		return request.cgi.request_method == "post";
	}

	/**
	 * Returns whether the request was a `PUT` request or not.
	 *
	 * [section: Controller]
	 * [category: Miscellaneous Functions]
	 */
	public boolean function isPut() {
		return request.cgi.request_method == "put";
	}

	/**
	 * Returns whether the request was a `PATCH` request or not.
	 *
	 * [section: Controller]
	 * [category: Miscellaneous Functions]
	 */
	public boolean function isPatch() {
		return request.cgi.request_method == "patch";
	}

	/**
	 * Returns whether the request was a `DELETE` request or not.
	 *
	 * [section: Controller]
	 * [category: Miscellaneous Functions]
	 */
	public boolean function isDelete() {
		return request.cgi.request_method == "delete";
	}

	/**
	 * Returns whether the request was a `HEAD` request or not.
	 *
	 * [section: Controller]
	 * [category: Miscellaneous Functions]
	 */
	public boolean function isHead() {
		return request.cgi.request_method == "head";
	}

	/**
	 * Returns whether the request was an `OPTIONS` request or not.
	 *
	 * [section: Controller]
	 * [category: Miscellaneous Functions]
	 */
	public boolean function isOptions() {
		return request.cgi.request_method == "options";
	}
}
