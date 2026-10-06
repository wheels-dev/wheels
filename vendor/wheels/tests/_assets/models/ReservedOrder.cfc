/**
 * A table whose columns are reserved words (order, group), created and dropped by
 * OrderReservedWordSpec, for ordering by them through order="table.column".
 */
component extends="Model" {

	function config() {
		table("c_o_r_e_reservedorders");
	}

}
