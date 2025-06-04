component extends="Controller" {

	function config() {
		verifies(except="index,new,create", params="key", paramsTypes="integer", handler="objectNotFound");
	}

	/**
	* View all Products
	**/
	function index() {
		products=model("product").findAll();
	}

	/**
	* View Product
	**/
	function show() {
		product=model("product").findByKey(params.key);
	}

	/**
	* Add New Product
	**/
	function new() {
		product=model("product").new();
	}

	/**
	* Create Product
	**/
	function create() {
		product=model("product").create(params.product);
		if(product.hasErrors()){
			renderView(action="new");
		} else {
			redirectTo(action="index", success="Product successfully created");
		}
	}

	/**
	* Edit Product
	**/
	function edit() {
		product=model("product").findByKey(params.key);
	}

	/**
	* Update Product
	**/
	function update() {
		product=model("product").findByKey(params.key);
		if(product.update(params.product)){
			redirectTo(action="index", success="Product successfully updated");
		} else {
			renderView(action="edit");
		}
	}

	/**
	* Delete Product
	**/
	function delete() {
		product=model("product").deleteByKey(params.key);
		redirectTo(action="index", success="Product successfully deleted");
	}

	/**
	* Redirect away if verifies fails, or if an object can't be found
	**/
	function objectNotFound() {
		redirectTo(action="index", error="That Product wasn't found");
	}

}
