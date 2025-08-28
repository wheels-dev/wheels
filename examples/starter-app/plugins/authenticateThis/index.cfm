<h1>Authenticate This!</h1>
<h3>A plugin for <a href="http://cfwheels.org" target="_blank">Coldfusion on Wheels</a> by <a href="http://cfwheels.org/user/profile/24" target="_blank">Andy Bellenie</a></h3>
<p>Adds bCrypt authentication helper methods to any model.</p>
<h2>Database</h2>
<p>Requires a CHAR(60) column to store the hashed password. Default property name is 'passwordHash'</p>
<h2>Setup</h2>
<p>Add authenticateThis() to the `config()` block of any model.</p>
<pre>&lt;cfcomponent extends=&quot;Wheels&quot; output=&quot;false&quot;&gt;
	&lt;cffunction name=&quot;init&quot;&gt;
		&lt;cfset authenticateThis()&gt;
	&lt;/cffunction&gt;<br />&lt;/cfcomponent&gt;</pre>
<h2>Methods</h2>
<ul>
	<li>
		Setup
		<ul>
			<li>authenticateThis()</li>
		</ul>
	</li>
	<li>
		Callbacks
		<ul>
			<li>hashPassword()</li>
		</ul>
	</li>
	<li>
		API
		<ul>
			<li>checkPassword()</li>
			<li>resetPassword()</li>
			<li>generateRandomPassword()</li>
		</ul>
	</li>
</ul>
<h2>Usage</h2>
<p>To create a new hashed password, set a 'password' property and save, e.g. user.create(password="foobar", name=etc.). See method arguments for further usage information.</p>
<h2>Work factor / Performance</h2>
<p>The default work factor for bCrypt is set at 12 for a balance of security and performance. This can be increased or decreased using the workFactor argument of authenticateThis()</p>
<h2>Support</h2>
<p>I try to keep my plugins free from bugs and up to date with Wheels releases, but life often gets in the way. If you encounter a problem please log an issue using the tracker on github, where you can also browse my other plugins.<br />
<a href="https://github.com/andybellenie" target="_blank">https://github.com/andybellenie</a></p>
