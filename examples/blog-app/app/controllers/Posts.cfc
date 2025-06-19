component extends="Controller" {
	
	function config() {
		// Allow HTML and JSON responses
		provides("html,json,xml,rss");
		
		// Cache public pages
		caches(actions: "index,show", time: 10);
		
		// Require authentication for certain actions
		filters(through: "authenticate", only: "new,create,edit,update,delete");
		filters(through: "findPost", only: "show,edit,update,delete");
		filters(through: "authorizeEdit", only: "edit,update,delete");
	}
	
	function index() {
		// Get published posts with pagination
		posts = model("Post").published().findAll(
			include: "author,comments",
			order: "publishedAt DESC",
			page: params.page ?: 1,
			perPage: 10
		);
		
		// Handle different formats
		switch($requestContentType()) {
			case "json":
			case "xml":
				renderWith(posts);
				break;
			case "rss":
				renderView("index_rss", layout: false);
				break;
		}
	}
	
	function show() {
		// Post is set by findPost filter
		// Increment view count
		post.updateByKey(key: post.id, viewCount: post.viewCount + 1);
		
		// Get comments with nested structure
		comments = post.comments(include: "author");
		
		// Get related posts
		relatedPosts = model("Post").published().findAll(
			where: "id != ? AND user_id = ?",
			values: [post.id, post.userId],
			order: "RANDOM()",
			maxRows: 5
		);
		
		// Set meta tags for SEO
		contentFor(pageTitle: post.title);
		contentFor(metaDescription: left(stripTags(post.content), 160));
		
		// Handle JSON requests
		if ($requestContentType() == "json") {
			renderWith({
				post: post,
				comments: comments,
				relatedPosts: relatedPosts
			});
		}
	}
	
	function new() {
		post = model("Post").new();
		// Pre-populate with draft status
		post.published = false;
	}
	
	function create() {
		// Set the current user as author
		params.post.userId = session.userId;
		
		// Handle featured image upload
		if (structKeyExists(params.post, "featuredImage") && len(params.post.featuredImage)) {
			params.post.featuredImage = handleImageUpload(params.post.featuredImage);
		}
		
		// Create the post
		post = model("Post").new(params.post);
		
		if (post.save()) {
			// Handle tags
			if (structKeyExists(params, "tags") && len(params.tags)) {
				var tagNames = listToArray(params.tags);
				for (var tagName in tagNames) {
					post.addTag(trim(tagName));
				}
			}
			
			flashInsert(success: "Post created successfully!");
			redirectTo(route: "post", key: post.id, slug: post.slug);
		} else {
			flashInsert(error: "Please correct the errors below.");
			renderView("new");
		}
	}
	
	function edit() {
		// Post is set by findPost filter
		// Load existing tags
		params.tags = arrayToList(post.tags().columnize("name"));
	}
	
	function update() {
		// Handle featured image upload
		if (structKeyExists(params.post, "featuredImage") && len(params.post.featuredImage)) {
			// Delete old image if exists
			if (len(post.featuredImage)) {
				deleteImage(post.featuredImage);
			}
			params.post.featuredImage = handleImageUpload(params.post.featuredImage);
		}
		
		if (post.update(params.post)) {
			// Update tags
			if (structKeyExists(params, "tags")) {
				// Remove all existing tags
				post.tags = [];
				post.save();
				
				// Add new tags
				if (len(params.tags)) {
					var tagNames = listToArray(params.tags);
					for (var tagName in tagNames) {
						post.addTag(trim(tagName));
					}
				}
			}
			
			flashInsert(success: "Post updated successfully!");
			redirectTo(route: "post", key: post.id, slug: post.slug);
		} else {
			flashInsert(error: "Please correct the errors below.");
			params.tags = arrayToList(post.tags().columnize("name"));
			renderView("edit");
		}
	}
	
	function delete() {
		if (post.delete()) {
			flashInsert(success: "Post deleted successfully!");
			redirectTo(route: "posts");
		} else {
			flashInsert(error: "Could not delete the post.");
			redirectTo(route: "post", key: post.id, slug: post.slug);
		}
	}
	
	// Private filter methods
	private function authenticate() {
		if (!structKeyExists(session, "userId")) {
			flashInsert(notice: "Please log in to continue.");
			redirectTo(controller: "sessions", action: "new");
		}
	}
	
	private function findPost() {
		post = model("Post").findByKey(key: params.key, include: "author,tags");
		if (!isObject(post)) {
			flashInsert(error: "Post not found.");
			redirectTo(route: "posts");
		}
	}
	
	private function authorizeEdit() {
		var user = model("User").findByKey(session.userId);
		if (!user.canEdit(post)) {
			flashInsert(error: "You don't have permission to edit this post.");
			redirectTo(route: "post", key: post.id, slug: post.slug);
		}
	}
	
	// Private helper methods
	private function handleImageUpload(required any fileField) {
		var uploadPath = expandPath("/images/posts/");
		var allowedExtensions = "jpg,jpeg,png,gif";
		
		// Ensure upload directory exists
		if (!directoryExists(uploadPath)) {
			directoryCreate(uploadPath);
		}
		
		// Generate unique filename
		var fileExt = listLast(arguments.fileField.clientFile, ".");
		var fileName = createUUID() & "." & fileExt;
		
		// Upload file
		var uploadResult = fileUpload(
			destination: uploadPath,
			fileField: "post[featuredImage]",
			nameConflict: "makeUnique",
			allowedExtensions: allowedExtensions
		);
		
		if (uploadResult.fileWasSaved) {
			// Resize image if needed
			var imagePath = uploadPath & uploadResult.serverFile;
			resizeImage(imagePath, 1200, 800);
			
			return uploadResult.serverFile;
		}
		
		return "";
	}
	
	private function deleteImage(required string fileName) {
		var imagePath = expandPath("/images/posts/" & arguments.fileName);
		if (fileExists(imagePath)) {
			fileDelete(imagePath);
		}
	}
	
	private function resizeImage(required string imagePath, required numeric maxWidth, required numeric maxHeight) {
		// Image resizing logic would go here
		// This is a placeholder - actual implementation would use an image manipulation library
	}
}