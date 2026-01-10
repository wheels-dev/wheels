<cfoutput>
#contentFor("title", "Sign Up - Tweeter")#

<div class="min-h-screen flex items-center justify-center">
	<div class="max-w-md w-full space-y-8 bg-white p-8 rounded-lg shadow-md">
		<div>
			<h2 class="mt-6 text-center text-3xl font-extrabold text-gray-900">
				Create your account
			</h2>
		</div>

		#startFormTag(controller="users", action="create", method="post", class="mt-8 space-y-6")#
			<div class="space-y-4">
				<div>
					<label for="username" class="block text-sm font-medium text-gray-700 mb-1">
						Username
					</label>
					<input type="text"
						   name="user[username]"
						   id="username"
						   required
						   class="appearance-none rounded-md relative block w-full px-3 py-2 border border-gray-300 placeholder-gray-500 text-gray-900 focus:outline-none focus:ring-blue-500 focus:border-blue-500 sm:text-sm"
						   placeholder="Choose a username">
				</div>

				<div>
					<label for="email" class="block text-sm font-medium text-gray-700 mb-1">
						Email address
					</label>
					<input type="email"
						   name="user[email]"
						   id="email"
						   required
						   class="appearance-none rounded-md relative block w-full px-3 py-2 border border-gray-300 placeholder-gray-500 text-gray-900 focus:outline-none focus:ring-blue-500 focus:border-blue-500 sm:text-sm"
						   placeholder="Email address">
				</div>

				<div>
					<label for="password" class="block text-sm font-medium text-gray-700 mb-1">
						Password
					</label>
					<input type="password"
						   name="user[password]"
						   id="password"
						   required
						   class="appearance-none rounded-md relative block w-full px-3 py-2 border border-gray-300 placeholder-gray-500 text-gray-900 focus:outline-none focus:ring-blue-500 focus:border-blue-500 sm:text-sm"
						   placeholder="Password">
				</div>
			</div>

			<div>
				<button type="submit"
						class="group relative w-full flex justify-center py-2 px-4 border border-transparent text-sm font-medium rounded-md text-white bg-blue-600 hover:bg-blue-700 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-blue-500">
					Sign up
				</button>
			</div>

			<div class="text-center">
				<p class="text-sm text-gray-600">
					Already have an account?
					<a href="#urlFor(route='login')#" class="font-medium text-blue-600 hover:text-blue-500">
						Sign in here
					</a>
				</p>
			</div>
		#endFormTag()#
	</div>
</div>
</cfoutput>
