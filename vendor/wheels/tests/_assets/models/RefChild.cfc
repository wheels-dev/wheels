/**
 * Fixture for #3337: the child side of an association whose foreign key column uses the
 * `<name>_id` convention that `useUnderscoreReferenceColumns` makes the migrator emit.
 *
 * The association passes no `foreignKey`, so the default derivation has to resolve
 * `refparent_id` on this model. Before #3337 it derived `refparentid` unconditionally and
 * any `include=` threw `key [refparentid] doesn't exist`.
 */
component extends="Model" {

	function config() {
		table("c_o_r_e_refchildren");
		belongsTo("refParent");
	}

}
