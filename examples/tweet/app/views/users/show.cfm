<cfparam name="user">
<cfparam name="tweets">
<cfparam name="isFollowingUser" default="false">
<cfoutput>
#contentFor("title", "@#user.username# - Tweeter")#

<div class="max-w-4xl mx-auto">
	<!-- Profile Header -->
	<div class="bg-white rounded-lg shadow mb-6">
		<!-- Cover Photo Placeholder -->
		<div class="h-48 bg-gradient-to-r from-blue-400 to-blue-600 rounded-t-lg"></div>

		<div class="px-6 pb-6">
			<!-- Avatar -->
			<div class="flex justify-between items-start -mt-16 mb-4">
				<div class="w-32 h-32 bg-blue-500 rounded-full border-4 border-white flex items-center justify-center text-white font-bold text-4xl">
					#uCase(left(user.username, 1))#
				</div>

				<!-- Follow/Edit Button -->
				<div class="mt-16">
					<cfif structKeyExists(session, "userId")>
						<cfif session.userId EQ user.id>
							<a href="#urlFor(controller='users', action='edit', key=user.id)#"
							   class="bg-blue-500 hover:bg-blue-600 text-white px-6 py-2 rounded-full font-medium">
								Edit Profile
							</a>
						<cfelse>
							<cfif isFollowingUser>
								<a href="#urlFor(route='unfollowUser', userId=user.id)#"
								   class="bg-gray-500 hover:bg-gray-600 text-white px-6 py-2 rounded-full font-medium">
									Unfollow
								</a>
							<cfelse>
								<form action="#urlFor(route='followUser', userId=user.id)#" method="post" class="inline">
									<button type="submit"
											class="bg-blue-500 hover:bg-blue-600 text-white px-6 py-2 rounded-full font-medium">
										Follow
									</button>
								</form>
							</cfif>
						</cfif>
					</cfif>
				</div>
			</div>

			<!-- User Info -->
			<div class="mb-4">
				<h1 class="text-2xl font-bold text-gray-900">@#user.username#</h1>

				<cfif len(user.bio)>
					<p class="text-gray-600 mt-2">#user.bio#</p>
				</cfif>

				<div class="flex items-center space-x-4 mt-3 text-sm text-gray-500">
					<cfif len(user.location)>
						<span>📍 #user.location#</span>
					</cfif>
					<cfif len(user.website)>
						<span>🔗 <a href="#user.website#" target="_blank" class="text-blue-500 hover:underline">#user.website#</a></span>
					</cfif>
					<span>📅 Joined #dateFormat(user.createdAt, "mmmm yyyy")#</span>
				</div>

				<!-- Stats -->
				<div class="flex items-center space-x-6 mt-4">
					<div>
						<span class="font-bold text-gray-900">#user.tweetsCount#</span>
						<span class="text-gray-500 text-sm">Tweets</span>
					</div>
					<div>
						<span class="font-bold text-gray-900">#user.followingCount#</span>
						<span class="text-gray-500 text-sm">Following</span>
					</div>
					<div>
						<span class="font-bold text-gray-900">#user.followersCount#</span>
						<span class="text-gray-500 text-sm">Followers</span>
					</div>
				</div>
			</div>
		</div>
	</div>

	<!-- User's Tweets -->
	<div class="space-y-4">
		<h2 class="text-2xl font-bold mb-4">Tweets</h2>

		<cfif tweets.recordCount GT 0>
			<cfloop query="tweets">
				<div class="bg-white rounded-lg shadow p-6">
					<!-- Tweet Header -->
					<div class="flex justify-between items-start mb-4">
						<div class="flex items-center space-x-3">
							<div class="w-12 h-12 bg-blue-500 rounded-full flex items-center justify-center text-white font-bold text-lg">
								#uCase(left(user.username, 1))#
							</div>
							<div>
								<p class="font-bold text-gray-900">@#user.username#</p>
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
						<span class="flex items-center space-x-1">
							<span>🤍</span>
							<span class="text-sm font-medium">#tweets.likesCount#</span>
						</span>
						<span class="flex items-center space-x-1">
							<span>💬</span>
							<span class="text-sm font-medium">#tweets.repliesCount#</span>
						</span>
					</div>
				</div>
			</cfloop>
		<cfelse>
			<div class="bg-white rounded-lg shadow p-8 text-center">
				<p class="text-gray-500 text-lg">No tweets yet.</p>
			</div>
		</cfif>
	</div>
</div>
</cfoutput>
