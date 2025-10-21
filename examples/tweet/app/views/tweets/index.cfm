<cfparam name="tweets">
<cfoutput>
#contentFor("title", "Home - Tweeter")#

<div class="grid grid-cols-1 md:grid-cols-3 gap-6">
	<!-- Left Sidebar (User Info) -->
	<div class="hidden md:block">
		<div class="bg-white rounded-lg shadow p-6">
			<h3 class="font-bold text-lg mb-4">Your Profile</h3>
			<cfif structKeyExists(session, "authenticated") AND session.authenticated>
				<div class="space-y-2">
					<p class="text-sm"><strong>Username:</strong> #session.username#</p>
					<a href="#urlFor(controller='users', action='show', key=session.userId)#"
					   class="text-blue-500 hover:text-blue-600 text-sm">
						View Profile
					</a>
				</div>
			</cfif>
		</div>
	</div>

	<!-- Main Content -->
	<div class="md:col-span-2">
		<!-- Tweet Composer -->
		<div class="bg-white rounded-lg shadow mb-6 p-6" x-data="{ content: '', charCount: 0, maxChars: 280 }">
			<h3 class="font-bold text-lg mb-4">What's happening?</h3>

			#startFormTag(controller="tweets", action="create", method="post")#
				<div class="mb-4">
					<textarea
						name="tweet[content]"
						x-model="content"
						@input="charCount = content.length"
						maxlength="280"
						class="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500 focus:border-transparent resize-none"
						rows="4"
						placeholder="What's on your mind?"
						required
					></textarea>
				</div>

				<div class="flex justify-between items-center">
					<div x-bind:class="{
						'text-gray-500': charCount < 260,
						'text-yellow-600': charCount >= 260 && charCount < 280,
						'text-red-600': charCount >= 280
					}" class="text-sm font-medium">
						<span x-text="charCount"></span> / <span x-text="maxChars"></span>
					</div>

					<button
						type="submit"
						x-bind:disabled="charCount === 0 || charCount > maxChars"
						x-bind:class="{
							'bg-blue-600 hover:bg-blue-700': charCount > 0 && charCount <= maxChars,
							'bg-gray-300 cursor-not-allowed': charCount === 0 || charCount > maxChars
						}"
						class="px-6 py-2 text-white rounded-md font-medium focus:outline-none focus:ring-2 focus:ring-blue-500 focus:ring-offset-2"
					>
						Tweet
					</button>
				</div>
			#endFormTag()#
		</div>

		<!-- Tweets Feed -->
		<div class="space-y-4">
			<h2 class="text-2xl font-bold mb-4">Recent Tweets</h2>

			<cfif tweets.recordCount GT 0>
				<cfloop query="tweets">
					<cfset tweetObj = model("Tweet").findByKey(tweets.id)>
					<cfset tweetUser = tweetObj.user()>

					<div class="bg-white rounded-lg shadow p-6">
						<!-- Tweet Header -->
						<div class="flex justify-between items-start mb-4">
							<div class="flex items-center space-x-3">
								<div class="w-12 h-12 bg-blue-500 rounded-full flex items-center justify-center text-white font-bold text-lg">
									#uCase(left(tweetUser.username, 1))#
								</div>
								<div>
									<a href="#urlFor(controller='users', action='show', key=tweets.userId)#"
									   class="font-bold text-gray-900 hover:text-blue-500">
										@#tweetUser.username#
									</a>
									<p class="text-sm text-gray-500">
										#dateFormat(tweets.createdAt, "mmm d, yyyy")# at #timeFormat(tweets.createdAt, "h:mm tt")#
									</p>
								</div>
							</div>

							<!-- Delete button (only for own tweets) -->
							<cfif structKeyExists(session, "userId") AND tweets.userId EQ session.userId>
								<form action="#urlFor(controller='tweets', action='delete', key=tweets.id)#" method="post" onsubmit="return confirm('Are you sure you want to delete this tweet?');">
									<button type="submit" class="text-red-500 hover:text-red-700 text-sm">
										Delete
									</button>
								</form>
							</cfif>
						</div>

						<!-- Tweet Content -->
						<div class="mb-4">
							<p class="text-gray-800">#tweets.content#</p>
						</div>

						<!-- Tweet Actions -->
						<div class="flex items-center space-x-6 text-gray-500">
							<!-- Like Button -->
							<cfif structKeyExists(session, "userId")>
								<cfset isLiked = tweetObj.isLikedBy(session.userId)>

								<cfif isLiked>
									<a href="#urlFor(route='unlikeTweet', tweetId=tweets.id)#"
									   class="flex items-center space-x-1 text-red-500 hover:text-red-600">
										<span>❤️</span>
										<span class="text-sm font-medium">#tweets.likesCount#</span>
									</a>
								<cfelse>
									<form action="#urlFor(route='likeTweet', tweetId=tweets.id)#" method="post" class="inline">
										<button type="submit" class="flex items-center space-x-1 hover:text-red-500">
											<span>🤍</span>
											<span class="text-sm font-medium">#tweets.likesCount#</span>
										</button>
									</form>
								</cfif>
							<cfelse>
								<span class="flex items-center space-x-1">
									<span>🤍</span>
									<span class="text-sm font-medium">#tweets.likesCount#</span>
								</span>
							</cfif>

							<!-- Reply Count (placeholder) -->
							<span class="flex items-center space-x-1">
								<span>💬</span>
								<span class="text-sm font-medium">#tweets.repliesCount#</span>
							</span>
						</div>
					</div>
				</cfloop>
			<cfelse>
				<div class="bg-white rounded-lg shadow p-8 text-center">
					<p class="text-gray-500 text-lg">No tweets yet. Be the first to tweet!</p>
				</div>
			</cfif>
		</div>
	</div>
</div>
</cfoutput>
