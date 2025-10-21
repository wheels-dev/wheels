<cfparam name="user">
<cfoutput>
#contentFor("title", "Edit Profile - Tweeter")#

<div class="max-w-2xl mx-auto">
	<div class="bg-white rounded-lg shadow p-8">
		<h2 class="text-2xl font-bold text-gray-900 mb-6">Edit Profile</h2>

		#startFormTag(controller="users", action="update", key=user.id, method="put")#
			<div class="space-y-6">
				<div>
					<label for="username" class="block text-sm font-medium text-gray-700 mb-1">
						Username
					</label>
					<input type="text"
						   name="user[username]"
						   id="username"
						   value="#user.username#"
						   required
						   class="appearance-none rounded-md block w-full px-3 py-2 border border-gray-300 placeholder-gray-500 text-gray-900 focus:outline-none focus:ring-blue-500 focus:border-blue-500 sm:text-sm">
				</div>

				<div>
					<label for="email" class="block text-sm font-medium text-gray-700 mb-1">
						Email
					</label>
					<input type="email"
						   name="user[email]"
						   id="email"
						   value="#user.email#"
						   required
						   class="appearance-none rounded-md block w-full px-3 py-2 border border-gray-300 placeholder-gray-500 text-gray-900 focus:outline-none focus:ring-blue-500 focus:border-blue-500 sm:text-sm">
				</div>

				<div>
					<label for="bio" class="block text-sm font-medium text-gray-700 mb-1">
						Bio
					</label>
					<textarea
						name="user[bio]"
						id="bio"
						rows="4"
						class="appearance-none rounded-md block w-full px-3 py-2 border border-gray-300 placeholder-gray-500 text-gray-900 focus:outline-none focus:ring-blue-500 focus:border-blue-500 sm:text-sm"
						placeholder="Tell us about yourself..."
					>#user.bio#</textarea>
					<p class="mt-1 text-sm text-gray-500">Max 500 characters</p>
				</div>

				<div>
					<label for="location" class="block text-sm font-medium text-gray-700 mb-1">
						Location
					</label>
					<input type="text"
						   name="user[location]"
						   id="location"
						   value="#user.location#"
						   class="appearance-none rounded-md block w-full px-3 py-2 border border-gray-300 placeholder-gray-500 text-gray-900 focus:outline-none focus:ring-blue-500 focus:border-blue-500 sm:text-sm"
						   placeholder="San Francisco, CA">
				</div>

				<div>
					<label for="website" class="block text-sm font-medium text-gray-700 mb-1">
						Website
					</label>
					<input type="url"
						   name="user[website]"
						   id="website"
						   value="#user.website#"
						   class="appearance-none rounded-md block w-full px-3 py-2 border border-gray-300 placeholder-gray-500 text-gray-900 focus:outline-none focus:ring-blue-500 focus:border-blue-500 sm:text-sm"
						   placeholder="https://example.com">
				</div>
			</div>

			<div class="mt-8 flex justify-end space-x-4">
				<a href="#urlFor(controller='users', action='show', key=user.id)#"
				   class="px-6 py-2 border border-gray-300 rounded-md text-gray-700 hover:bg-gray-50 font-medium">
					Cancel
				</a>
				<button type="submit"
						class="px-6 py-2 bg-blue-600 hover:bg-blue-700 text-white rounded-md font-medium">
					Save Changes
				</button>
			</div>
		#endFormTag()#
	</div>
</div>
</cfoutput>
