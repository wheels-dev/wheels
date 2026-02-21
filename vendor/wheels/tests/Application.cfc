component {

	this.name = createUUID();
	this.bufferOutput = true;
	// this.localMode = "modern"; <--- don't use this, logbox chokes.
	// this.applicationTimeout = createTimeSpan( 0, 0, 0, 1 );

	// We turn on "sessionManagement" by default since the Flash uses it.
	this.sessionManagement = true;

	// Put variables we just need internally inside a wheels struct.
	this.wheels = {};
	this.wheels.rootPath = GetDirectoryFromPath(GetBaseTemplatePath());

	this.webrootDir = getDirectoryFromPath( getCurrentTemplatePath() );
	this.appDir     = getCanonicalPath("_assets");

	this.mappings['/app']      = this.appDir;
	// this.mappings['/tests']    = this.testDir;
	// this.mappings['/testbox']  = this.vendorDir & 'testbox';
	// this.mappings['/wirebox']  = this.vendorDir & 'wheels/vendor/wirebox';
	this.mappings['/wheels']   = this.webrootDir & 'wheels';

	//If a plugin has a jar or class file, automatically add the mapping to this.javasettings.
	 this.wheels.pluginDir = this.appDir & "plugins";
	 this.wheels.pluginFolders = DirectoryList(
	 	this.wheels.pluginDir,
	 	"true",
	 	"path",
	 	"*.class|*.jar|*.java"
	 );
     public void function onRequestEnd( string targetPage ) {

     }

}