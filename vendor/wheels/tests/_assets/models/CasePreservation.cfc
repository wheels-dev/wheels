component extends="Model" {

	function config() {
		// Intentionally declares NO property() mappings so that every property
		// is auto-derived from the database column metadata. The table has an
		// undeclared mixed-case `isHidden` column used to assert that Wheels
		// preserves the database's column casing for auto-derived properties.
		table("c_o_r_e_casepreservation");
	}

}
