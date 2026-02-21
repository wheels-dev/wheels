<cfscript>
/**
 * HELPERS
 */

function $pluginObj(required struct config) {
	return $createObjectFromRoot(argumentCollection = arguments.config);
}

function $writeTestFile() {
	FileWrite($testFile(), "overwritten");
}

function $readTestFile() {
	return FileRead($testFile());
}

function $testFile() {
	var theFile = "";
	theFile = [config.pluginPath, "testglobalmixins", "index.cfm"];
	theFile = ExpandPath(ArrayToList(theFile, "/"));
	return theFile;
}

function $createDir() {
	DirectoryCreate(badDir);
}

function $deleteDirs() {
	if (DirectoryExists(badDir)) {
		DirectoryDelete(badDir, true);
	}
	if (DirectoryExists(goodDir)) {
		DirectoryDelete(goodDir, true);
	}
}

function $deleteTestFolders() {
	var q = DirectoryList(ExpandPath('/wheels/tests/_assets/plugins/unpacking'), false, "query");
	for (row in q) {
		dir = ListChangeDelims(ListAppend(row.directory, row.name, "/"), "/", "\");
		if (DirectoryExists(dir)) {
			DirectoryDelete(dir, true);
		}
	};
}
</cfscript>
