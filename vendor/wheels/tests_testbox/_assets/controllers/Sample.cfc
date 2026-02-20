component extends="Controller" {

	function badRequest(){
        variables.message = "400-BAD-REQUEST";
        header statuscode=400;
    }

}