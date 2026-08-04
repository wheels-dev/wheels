/**
 * Fixture for #3337: the parent side of an association whose foreign key column uses the
 * `<name>_id` convention that `useUnderscoreReferenceColumns` makes the migrator emit.
 *
 * Exercises the hasMany branch of the association foreign-key default, where the column
 * lives on the ASSOCIATED model (`c_o_r_e_refchildren.refparent_id`).
 */
component extends="Model" {

	function config() {
		table("c_o_r_e_refparents");
		hasMany("refChildren");
	}

}
