# Builds the two test apps from the repository checkout (run from the repo root):
#   C:\wheels-iis\root  - the app at the site root
#   C:\wheels-iis\app1  - the same app served at /app1 (an IIS application)
# Each gets the fixture routes and Probes controller, a known stylesheet, and
# redirectAfterReload on. The web.config files are put in place by checks.ps1.
$ErrorActionPreference = 'Stop'
$repo = (Get-Location).Path
$fixture = Join-Path $repo 'tools\ci\iis\fixture'

foreach ($name in 'root', 'app1') {
	$dest = "C:\wheels-iis\$name"
	New-Item -ItemType Directory -Force -Path $dest | Out-Null
	# The framework's own tests and docs are not needed to serve the app, and are large.
	foreach ($dir in 'app', 'config', 'public', 'vendor') {
		robocopy (Join-Path $repo $dir) (Join-Path $dest $dir) /E /NFL /NDL /NJH /NJS /NP /XD 'tests' 'docs' | Out-Null
		if ($LASTEXITCODE -ge 8) { throw "robocopy $dir failed: $LASTEXITCODE" }
	}
	New-Item -ItemType Directory -Force -Path (Join-Path $dest 'db\h2') | Out-Null
	Copy-Item (Join-Path $fixture 'config\routes.cfm') (Join-Path $dest 'config\routes.cfm') -Force
	Copy-Item (Join-Path $fixture 'app\controllers\Probes.cfc') (Join-Path $dest 'app\controllers\Probes.cfc') -Force
	Set-Content -Path (Join-Path $dest 'public\stylesheets\iis-probe.css') -Value '/* iis-probe-static */'

	$settings = Join-Path $dest 'config\settings.cfm'
	$extra = "`n<cfscript>`n// IIS test job (runner only)`nset(redirectAfterReload = true);`n"
	if ($name -eq 'app1') { $extra += "set(subpath = ""/app1"");`n" }
	$extra += "</cfscript>`n"
	Add-Content -Path $settings -Value $extra

	if ($name -eq 'app1') {
		# A second app on the same engine needs its own application name.
		$appCfm = Join-Path $dest 'config\app.cfm'
		(Get-Content $appCfm -Raw) -replace 'this\.name = "wheels-dev";', 'this.name = "wheels-iis-app1";' | Set-Content $appCfm
	}
}
Write-Host 'Apps deployed to C:\wheels-iis\root and C:\wheels-iis\app1'
