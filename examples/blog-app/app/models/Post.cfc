component extends="Model" {
	
	function config() {
		// Associations
		belongsTo(name: "author", modelName: "User", foreignKey: "userId");
		hasMany(name: "comments", dependent: "delete", order: "createdAt ASC");
		hasAndBelongsToMany(
			name: "tags",
			joinTable: "posts_tags",
			foreignKey: "postId",
			associationForeignKey: "tagId"
		);
		
		// Properties
		property(name: "excerpt", sql: "SUBSTRING(content, 1, 200)");
		property(name: "commentCount", sql: "(SELECT COUNT(*) FROM comments WHERE post_id = posts.id)");
		
		// Validations
		validatesPresenceOf("title,content,userId");
		validatesUniquenessOf("slug");
		validatesLengthOf(property: "title", maximum: 200);
		validatesLengthOf(property: "content", minimum: 10);
		validate("validatePublishDate");
		
		// Callbacks
		beforeValidation("generateSlug");
		beforeCreate("setDefaults");
		afterSave("clearCache");
		afterDelete("removeImages");
	}
	
	// Public methods
	public function publish() {
		this.published = true;
		this.publishedAt = now();
		return this.save();
	}
	
	public function unpublish() {
		this.published = false;
		this.publishedAt = "";
		return this.save();
	}
	
	public function isPublished() {
		return this.published && (!len(this.publishedAt) || this.publishedAt <= now());
	}
	
	public function addTag(required string tagName) {
		var tag = model("Tag").findOrCreateByName(arguments.tagName);
		if (!this.hasTag(tag)) {
			arrayAppend(this.tags, tag);
			this.save();
		}
		return tag;
	}
	
	public function hasTag(required any tag) {
		for (var t in this.tags()) {
			if (t.id == arguments.tag.id) {
				return true;
			}
		}
		return false;
	}
	
	public function removeTag(required any tag) {
		var tags = this.tags();
		for (var i = arrayLen(tags); i >= 1; i--) {
			if (tags[i].id == arguments.tag.id) {
				arrayDeleteAt(tags, i);
				this.save();
				break;
			}
		}
	}
	
	// Scopes
	public function scopePublished() {
		return where("published = ? AND (published_at IS NULL OR published_at <= ?)", [true, now()]);
	}
	
	public function scopeDrafts() {
		return where("published = ?", false);
	}
	
	public function scopeByAuthor(required numeric authorId) {
		return where("user_id = ?", arguments.authorId);
	}
	
	public function scopeTagged(required string tagName) {
		return where("EXISTS (
			SELECT 1 FROM posts_tags pt
			JOIN tags t ON pt.tag_id = t.id
			WHERE pt.post_id = posts.id AND t.name = ?
		)", arguments.tagName);
	}
	
	public function scopeSearch(required string q) {
		var searchTerm = "%" & arguments.q & "%";
		return where("title LIKE ? OR content LIKE ?", [searchTerm, searchTerm]);
	}
	
	// URL generation
	public function url() {
		return URLFor(route: "post", key: this.id, slug: this.slug);
	}
	
	public function editUrl() {
		return URLFor(route: "editPost", key: this.id);
	}
	
	// Private callback methods
	private function generateSlug() {
		if (!len(this.slug) && len(this.title)) {
			this.slug = createSlug(this.title);
			// Ensure uniqueness
			var count = 1;
			var baseSlug = this.slug;
			while (model("Post").exists(where: "slug = '#this.slug#' AND id != '#this.id ?: 0#'")) {
				this.slug = baseSlug & "-" & count;
				count++;
			}
		}
	}
	
	private function setDefaults() {
		if (!structKeyExists(this, "published")) {
			this.published = false;
		}
		if (!structKeyExists(this, "viewCount")) {
			this.viewCount = 0;
		}
	}
	
	private function clearCache() {
		cacheRemove("recent_posts");
		cacheRemove("popular_posts");
		cacheRemove("post_" & this.id);
	}
	
	private function removeImages() {
		if (len(this.featuredImage)) {
			var imagePath = expandPath("/images/posts/" & this.featuredImage);
			if (fileExists(imagePath)) {
				fileDelete(imagePath);
			}
		}
	}
	
	private function validatePublishDate() {
		if (this.published && structKeyExists(this, "publishedAt") && len(this.publishedAt)) {
			if (this.publishedAt > dateAdd("yyyy", 1, now())) {
				this.addError("publishedAt", "Publish date cannot be more than 1 year in the future");
			}
		}
	}
	
	// Helper function for creating slugs
	private function createSlug(required string text) {
		// Convert to lowercase and replace spaces with hyphens
		var slug = lcase(arguments.text);
		slug = reReplace(slug, "[^a-z0-9\s-]", "", "all");
		slug = reReplace(slug, "[\s]+", "-", "all");
		slug = reReplace(slug, "^-+|-+$", "", "all");
		return slug;
	}
}