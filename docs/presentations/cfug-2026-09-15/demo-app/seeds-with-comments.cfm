<!--- Deterministic association fallback: copy to app/db/seeds.cfm ONLY after
      both Post and Comment migrations. Run `wheels seed --mode=convention`.
      Resolves real parent IDs; repeat runs skip matching Posts and Comments. --->
<cfscript>
seedOnce(modelName="Post", uniqueProperties="title", properties={
	title: "Hello, Wheels",
	body: "A first post from wheels seed — no form-filling required.",
	publishedAt: CreateDateTime(2026, 9, 15, 19, 0, 0)
});

seedOnce(modelName="Post", uniqueProperties="title", properties={
	title: "Convention over configuration",
	body: "Post maps to posts, Posts.cfc, and /posts. The naming is the wiring.",
	publishedAt: CreateDateTime(2026, 9, 15, 19, 5, 0)
});

local.cfugHelloPost = model("Post").findOne(where="title = 'Hello, Wheels'");
local.cfugConventionPost = model("Post").findOne(where="title = 'Convention over configuration'");
if (!IsObject(local.cfugHelloPost) || !IsObject(local.cfugConventionPost)) {
	throw(type="CFUG.SeedParentMissing", message="Both demo Posts must save before their Comments can be seeded.");
}

seedOnce(modelName="Comment", uniqueProperties="post_id,body", properties={
	post_id: local.cfugHelloPost.id,
	body: "This Comment belongs to Hello, Wheels through its actual Post ID."
});

seedOnce(modelName="Comment", uniqueProperties="post_id,body", properties={
	post_id: local.cfugConventionPost.id,
	body: "A repeatable association example without a hard-coded foreign key."
});
</cfscript>
