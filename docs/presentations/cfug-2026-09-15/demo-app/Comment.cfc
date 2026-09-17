/**
 * Reference config after: scaffold Comment body:text --belongsTo=post
 * Stock new apps use post_id. No author column is part of this demo.
 */
component extends="Model" {
	function config() {
		belongsTo(name="post");
		validatesPresenceOf("body,post_id");
	}
}
