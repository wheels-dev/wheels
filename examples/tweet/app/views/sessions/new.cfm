<cfoutput>
#contentFor("title", "Login - Tweeter")#

<div class="min-h-screen flex items-center justify-center">
	<div class="max-w-md w-full space-y-8 bg-white p-8 rounded-lg shadow-md">
		<div>
			<h2 class="mt-6 text-center text-3xl font-extrabold text-gray-900">
				Sign in to Tweeter
			</h2>
		</div>

		#startFormTag(route="authenticate", method="post", class="mt-8 space-y-6")#
			<div class="rounded-md shadow-sm -space-y-px">
				<div class="mb-4">
					<label for="email" class="block text-sm font-medium text-gray-700 mb-1">
						Email address
					</label>
					<input type="email"
						   name="email"
						   id="email"
						   required
						   class="appearance-none rounded-md relative block w-full px-3 py-2 border border-gray-300 placeholder-gray-500 text-gray-900 focus:outline-none focus:ring-blue-500 focus:border-blue-500 focus:z-10 sm:text-sm"
						   placeholder="Email address">
				</div>

				<div class="mb-4">
					<label for="password" class="block text-sm font-medium text-gray-700 mb-1">
						Password
					</label>
					<input type="password"
						   name="password"
						   id="password"
						   required
						   class="appearance-none rounded-md relative block w-full px-3 py-2 border border-gray-300 placeholder-gray-500 text-gray-900 focus:outline-none focus:ring-blue-500 focus:border-blue-500 focus:z-10 sm:text-sm"
						   placeholder="Password">
				</div>
			</div>

			<div>
				<button type="submit"
						class="group relative w-full flex justify-center py-2 px-4 border border-transparent text-sm font-medium rounded-md text-white bg-blue-600 hover:bg-blue-700 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-blue-500">
					Sign in
				</button>
			</div>

			<div class="text-center">
				<p class="text-sm text-gray-600">
					Don't have an account?
					<a href="#urlFor(route='register')#" class="font-medium text-blue-600 hover:text-blue-500">
						Sign up here
					</a>
				</p>
			</div>
		#endFormTag()#
	</div>
</div>
</cfoutput>
