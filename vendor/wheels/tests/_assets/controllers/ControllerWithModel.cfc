component extends="Controller" {

	user = model("user").findOne(where = "lastname = 'Petruzzi'");

}
