/**
 * Test fixture policy for the Post model. Exercises the grant/deny surface of
 * the authorization layer:
 * - index: any authenticated user (guest denies)
 * - show: everyone (including guests)
 * - update: only the post's author
 * - scope: authors see their own posts; guests see nothing (inherited default-deny)
 * - publish (custom action): intentionally NOT defined — must deny
 * - create/edit/delete/new: inherited default-deny from the base
 */
component extends="Policy" {

	public boolean function index() {
		return IsStruct(variables.user) && !StructIsEmpty(variables.user);
	}

	public boolean function show() {
		return true;
	}

	public boolean function update() {
		return IsStruct(variables.user)
			&& StructKeyExists(variables.user, "id")
			&& IsObject(variables.record)
			&& StructKeyExists(variables.record, "authorId")
			&& variables.user.id == variables.record.authorId;
	}

	public any function scope(required any collection) {
		if (IsStruct(variables.user) && StructKeyExists(variables.user, "id")) {
			return arguments.collection.where("authorid", variables.user.id);
		}
		return super.scope(arguments.collection);
	}

}
