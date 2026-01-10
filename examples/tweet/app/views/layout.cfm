<cfif application.contentOnly>
	<cfoutput>
		#flashMessages()#
		#includeContent()#
	</cfoutput>
<cfelse>
<!DOCTYPE html>
<html lang="en">
<head>
	<meta charset="UTF-8">
	<meta name="viewport" content="width=device-width, initial-scale=1.0">
	<cfoutput>#csrfMetaTags()#</cfoutput>
	<title><cfoutput>#contentFor("title", "Tweeter - Share Your Thoughts")#</cfoutput></title>

	<!-- Tailwind CSS CDN -->
	<script src="https://cdn.tailwindcss.com"></script>

	<!-- Alpine.js CDN -->
	<script defer src="https://cdn.jsdelivr.net/npm/alpinejs@3.x.x/dist/cdn.min.js"></script>

	<!-- Heroicons via CDN -->
	<style type="text/tailwindcss">
		[x-cloak] { display: none !important; }
	</style>
</head>
<body class="bg-gray-50">
	<cfoutput>
	<!-- Navigation -->
	<nav class="bg-white border-b border-gray-200 sticky top-0 z-50">
		<div class="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
			<div class="flex justify-between h-16">
				<div class="flex">
					<div class="flex-shrink-0 flex items-center">
						<a href="#urlFor(controller='tweets', action='index')#" class="text-2xl font-bold text-blue-500">
							Tweeter
						</a>
					</div>
				</div>

				<div class="flex items-center space-x-4">
					<cfif structKeyExists(session, "authenticated") AND session.authenticated>
						<!-- Authenticated User Menu -->
						<span class="text-gray-700">Hello, <strong>#session.username#</strong></span>

						<a href="#urlFor(controller='users', action='show', key=session.userId)#"
						   class="text-gray-700 hover:text-blue-500 px-3 py-2 rounded-md text-sm font-medium">
							Profile
						</a>

						<a href="#urlFor(route='logout')#"
						   class="bg-red-500 hover:bg-red-600 text-white px-4 py-2 rounded-md text-sm font-medium">
							Logout
						</a>
					<cfelse>
						<!-- Guest Menu -->
						<a href="#urlFor(route='login')#"
						   class="text-gray-700 hover:text-blue-500 px-3 py-2 rounded-md text-sm font-medium">
							Login
						</a>

						<a href="#urlFor(route='register')#"
						   class="bg-blue-500 hover:bg-blue-600 text-white px-4 py-2 rounded-md text-sm font-medium">
							Sign Up
						</a>
					</cfif>
				</div>
			</div>
		</div>
	</nav>

	<!-- Flash Messages -->
	<cfif flashKeyExists("success")>
		<div x-data="{ show: true }"
			 x-show="show"
			 x-init="setTimeout(() => show = false, 5000)"
			 x-cloak
			 class="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 mt-4">
			<div class="bg-green-50 border border-green-200 text-green-800 px-4 py-3 rounded relative">
				<span class="block sm:inline">#flash("success")#</span>
			</div>
		</div>
	</cfif>

	<cfif flashKeyExists("error")>
		<div x-data="{ show: true }"
			 x-show="show"
			 x-init="setTimeout(() => show = false, 5000)"
			 x-cloak
			 class="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 mt-4">
			<div class="bg-red-50 border border-red-200 text-red-800 px-4 py-3 rounded relative">
				<span class="block sm:inline">#flash("error")#</span>
			</div>
		</div>
	</cfif>

	<!-- Main Content -->
	<main class="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-8">
		#includeContent()#
	</main>

	<!-- Footer -->
	<footer class="bg-white border-t border-gray-200 mt-12">
		<div class="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-4">
			<p class="text-center text-gray-500 text-sm">
				&copy; 2025 Tweeter. Built with Wheels CFML, Tailwind CSS, and Alpine.js.
			</p>
		</div>
	</footer>
	</cfoutput>
</body>
</html>
</cfif>
