component extends="wheels.tests.Test" {

	function setup() {
		params = {controller = "test", action = "test"};
		_controller = controller("dummy", params);
		args = {};
		args.deliver = false;
	}

	function test_only_file_supplied() {
		args.directory = "/wheels/tests/_assets";
		args.file = "files/cfwheels-logo.png";
		r = _controller.sendFile(argumentCollection = args);
		assert('Right(r.file, 17) eq "cfwheels-logo.png"');
		assert('r.mime eq "image/png"');
		assert('r.name eq "cfwheels-logo.png"');
	}

	function test_get_test_info() {
		args.directory = "/wheels/tests/_assets";
		args.file = "files/cfwheels-logo.png";
		args.name = "A Weird FileName.png";
		_controller.sendFile(argumentCollection = args);
		r = _controller.getFiles();
		assert('Right(r[1].file, 17) eq "cfwheels-logo.png"');
		assert('r[1].mime eq "image/png"');
		assert('r[1].name eq "A Weird FileName.png"');
	}

	function test_file_and_name_supplied() {
		args.directory = "/wheels/tests/_assets";
		args.file = "files/cfwheels-logo.png";
		args.name = "A Weird FileName.png";
		r = _controller.sendFile(argumentCollection = args);
		assert('Right(r.file, 17) eq "cfwheels-logo.png"');
		assert('r.mime eq "image/png"');
		assert('r.name eq "A Weird FileName.png"');
	}

	function test_change_disposition() {
		args.directory = "/wheels/tests/_assets";
		args.file = "files/cfwheels-logo.png";
		args.disposition = "attachment";
		r = _controller.sendFile(argumentCollection = args);
		assert('Right(r.file, 17) eq "cfwheels-logo.png"');
		assert('r.disposition eq "attachment"');
		assert('r.mime eq "image/png"');
		assert('r.name eq "cfwheels-logo.png"');
	}

	function test_overload_mimetype() {
		args.directory = "/wheels/tests/_assets";
		args.file = "files/cfwheels-logo.png";
		args.type = "wheels/custom";
		r = _controller.sendFile(argumentCollection = args);
		assert('Right(r.file, 17) eq "cfwheels-logo.png"');
		assert('r.disposition eq "attachment"');
		assert('r.mime eq "wheels/custom"');
		assert('r.name eq "cfwheels-logo.png"');
	}

	function test_no_extension_one_file_exists() {
		args.directory = "/wheels/tests/_assets";
		args.file = "files/sendFile";
		r = _controller.sendFile(argumentCollection = args);
		assert('Right(r.file, 12) eq "sendFile.txt"');
		assert('r.mime eq "text/plain"');
		assert('r.name eq "sendFile.txt"');
	}

	function test_no_extension_multiple_files_exists() {
		args.file = "../wheels/tests/_assets/files/cfwheels-logo";
		r = raised("_controller.sendFile(argumentCollection=args)");
		assert('r eq "Wheels.FileNotFound"');
	}

	function test_specifying_a_directory() {
		args.directory = "/wheels/tests/_assets";
		args.file = "files/cfwheels-logo.png";
		r = _controller.sendFile(argumentCollection = args);
		assert('Right(r.file, 17) eq "cfwheels-logo.png"');
		assert('r.mime eq "image/png"');
		assert('r.name eq "cfwheels-logo.png"');
	}
	/*
	function test_ram_resource() {
		include "document.cfm"; // cfscript cfdocuemt isn't supported in cf10
		FileWrite("ram://cfwheels.pdf", cfwheels_pdf);
		args.file = "ram://cfwheels.pdf";
		args.deleteFile = true;
		r = _controller.sendFile(argumentCollection = args);
		assert('r.file eq "ram://cfwheels.pdf"');
		assert('r.mime eq "application/pdf"');
		assert('r.name eq "cfwheels.pdf"');
	}

	function test_non_existent_ram_resource() {
		args.file = "ram://doesnt_exist.pdf";
		r = raised("_controller.sendFile(argumentCollection=args)");
		assert('r eq "Wheels.FileNotFound"');
	}*/

}
