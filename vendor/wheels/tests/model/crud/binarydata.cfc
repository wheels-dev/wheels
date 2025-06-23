component extends="wheels.tests.Test" {

	function setup() {
		binaryData = FileReadBinary(ExpandPath('/wheels/tests/_assets/files/cfwheels-logo.png'));
	}

	function test_update() {
		transaction action="begin" {
			photo = model("photo").findOne();
			photo.update(filename = "somefilename", fileData = binaryData);
			photo = model("photo").findByKey(photo.id);
			_binary = photo.filedata;
			transaction action="rollback";
		}
		assert('IsBinary(ToBinary(_binary))');
	}

	function test_insert() {
		gallery = model("gallery").findOne(include = "user", where = "_c_o_r_e_users.lastname = 'Petruzzi'", orderby = "id");
		transaction action="begin" {
			photo = model("photo").create(
				galleryid = "#gallery.id#",
				filename = "somefilename",
				fileData = binaryData,
				description1 = "something something"
			);
			photo = model("photo").findByKey(photo.id);
			_binary = photo.filedata;
			transaction action="rollback";
		}
		assert('IsBinary(ToBinary(_binary))');
	}

}
