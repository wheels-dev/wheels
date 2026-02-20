<!--- cfformat-ignore-start --->
<cfinclude template="../layout/_header.cfm">
<cfset thisVersion = SpanExcluding(ListGetAt(get("version"), 1, ".") & "." & ListGetAt(get("version"), 2, "."), " ")>
<cfoutput>
	<div class="ui container">

	#pageHeader("Congratulations!")#

	<p>
		<i class="fa fa-check-circle"></i>
		<strong>
			You have successfully installed<cfif Len(get("version"))> version #get("version")# of</cfif> Wheels.dev
		</strong>
		<br>
		Welcome to the wonderful world of Wheels. We hope you will enjoy it! Now start coding...
	</p>

	<h2>Now What?</h2>
	<p>Now that you have a working installation of Wheels, you may be wondering what to do next. Here are some suggestions.</p>

	<div class="row">
		<div class="column">
			<a class="" href="https://wheels.dev/3.0.0/guides/introduction/readme/beginner-tutorial-hello-world" target="_blank">View and code along with our
		&quot;Hello World&quot; tutorial.</a>
		</div>
		<div class="column">
			<a class="" href="https://wheels.dev/3.0.0/guides" target="_blank">Have a look at the rest of our documentation.</a>
		</div>
		<div class="column">
			<a class="" href="https://github.com/wheels-dev/wheels/discussions" target="_blank">Say &quot;Hello!&quot; to everyone in the Wheels community.</a>
		</div>
		<div class="column">Build the next killer website on the World Wide Web...</div>
	</div>

	<p>
		<strong>Good Luck!</strong>
	</p>

	<h3>How to Make this Message Go Away</h3>
	<p>
		Want to have another page load when your application loads this URL? You can configure your own <em>home route</em>.
	</p>
	<ol>
		<li>
			Open the routes configuration file at <code>/config/routes.cfm</code>.
		</li>
		<li>
			You will see a line similar to this for a route named <code>root</code>:
			<pre>
				<code>.root(to=&quot;wheels####wheels&quot;, method=&quot;get&quot;)</code>
			</pre>
		</li>
		<li>
			Simply change the <code>to</code>
			 parameter to specify a <code>controller####action</code>
			 of your choosing.
		</li>
		<li>Reload your Wheels application.</li>
	</ol>
</cfoutput>

<cfinclude template="../layout/_footer.cfm">
<!--- cfformat-ignore-end --->
