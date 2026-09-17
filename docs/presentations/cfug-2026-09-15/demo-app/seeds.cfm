<!--- Optional deterministic fallback, not the main `seed --generate` track.
      Copy to app/db/seeds.cfm after the Post migration, then:
      wheels seed --mode=convention
      Safe before the Comment scaffold; publishedAt is required by the Post model. --->
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
</cfscript>
