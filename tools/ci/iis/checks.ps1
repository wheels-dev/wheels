# Runs the IIS checks for each web.config variant and writes a report.
#   guide     - the inline rule from the v4.2 IIS guide, at the site root
#   root      - tools/ci/iis/web.config.root, at the site root
#   subfolder - tools/ci/iis/web.config.subfolder, for the app at /app1
# A check marked 'required' fails the job when it doesn't hold. 'info' checks
# record known gaps (e.g. in the guide's rule) without failing the job.
$ErrorActionPreference = 'Stop'
$repo = (Get-Location).Path
$iisDir = Join-Path $repo 'tools\ci\iis'
$report = Join-Path $env:RUNNER_TEMP 'iis-report.md'
$results = New-Object System.Collections.Generic.List[object]

# A non-loopback address of this runner, used as the 'remote' peer.
$nicIp = (Get-NetIPAddress -AddressFamily IPv4 | Where-Object { $_.IPAddress -notlike '127.*' -and $_.IPAddress -notlike '169.254.*' -and $_.PrefixOrigin -ne 'WellKnown' } | Select-Object -First 1).IPAddress
Write-Host "non-loopback address: $nicIp"

function Invoke-Probe([string]$Url) {
	$body = Join-Path $env:RUNNER_TEMP 'iis-body.txt'
	$hdr = Join-Path $env:RUNNER_TEMP 'iis-headers.txt'
	$code = & curl.exe -s --path-as-is --max-time 120 -o $body -D $hdr -w '%{http_code}' $Url
	$location = ''
	foreach ($line in (Get-Content $hdr -ErrorAction SilentlyContinue)) {
		if ($line -match '^Location:\s*(.*)$') { $location = $Matches[1].Trim() }
	}
	$text = if (Test-Path $body) { Get-Content $body -Raw -ErrorAction SilentlyContinue } else { '' }
	if ($null -eq $text) { $text = '' }
	[pscustomobject]@{ Status = [int]$code; Location = $location; Body = $text }
}

function Add-Check([string]$Variant, [string]$Name, [string]$Url, [scriptblock]$Expect, [string]$Expected, [string]$Kind = 'required') {
	$r = Invoke-Probe $Url
	$ok = [bool](& $Expect $r)
	$outcome = if ($ok) { 'PASS' } elseif ($Kind -eq 'info') { 'INFO' } else { 'FAIL' }
	$got = "$($r.Status)"
	if ($r.Location) { $got += " -> $($r.Location)" }
	$snippet = ($r.Body -replace '\s+', ' ')
	if ($snippet.Length -gt 60) { $snippet = $snippet.Substring(0, 60) + '...' }
	$results.Add([pscustomobject]@{ Variant = $Variant; Check = $Name; Url = $Url; Expected = $Expected; Got = $got; Body = $snippet; Outcome = $outcome })
	Write-Host ("[{0}] {1,-9} {2}: {3} (got {4})" -f $outcome, $Variant, $Name, $Url, $got)
}

function Use-WebConfig([string]$Source, [string]$Target) {
	Copy-Item $Source $Target -Force
	Start-Sleep -Seconds 3
	# Warm up: the first request after a config change can be slow.
	& curl.exe -s -o NUL --max-time 120 'http://127.0.0.1/index.cfm' | Out-Null
}

function Test-Variant([string]$Variant, [string]$Base) {
	$h = 'http://127.0.0.1'
	Add-Check $Variant 'index.cfm directly' "$h$Base/index.cfm" { param($r) $r.Status -eq 200 } '200'
	Add-Check $Variant 'home' "$h$Base/" { param($r) $r.Status -eq 200 } '200'
	Add-Check $Variant 'pretty URL' "$h$Base/probe/hello" { param($r) $r.Status -eq 200 -and $r.Body -match 'probe:hello' } '200 probe:hello'
	Add-Check $Variant 'nested route' "$h$Base/probe/7/items/9" { param($r) $r.Status -eq 200 -and $r.Body -match 'probe:nested:7:9' } '200 probe:nested:7:9'
	Add-Check $Variant 'path info (index.cfm/...)' "$h$Base/index.cfm/probe/hello" { param($r) $r.Status -eq 200 -and $r.Body -match 'probe:hello' } '200 probe:hello'
	Add-Check $Variant 'static asset' "$h$Base/stylesheets/iis-probe.css" { param($r) $r.Status -eq 200 -and $r.Body -match 'iis-probe-static' } '200 file content'
	Add-Check $Variant 'unknown route is 404' "$h$Base/no-such-route-xyz" { param($r) $r.Status -eq 404 } '404'
	# The guide's {REQUEST_URI} prefix list also matches /files-gallery, so IIS serves its own 404 there.
	$kind = if ($Variant -eq 'guide') { 'info' } else { 'required' }
	Add-Check $Variant 'route named like a static folder' "$h$Base/files-gallery" { param($r) $r.Status -eq 200 -and $r.Body -match 'probe:hello' } '200 probe:hello (routed)' $kind
	Add-Check $Variant 'dev tools from loopback' "$h$Base/wheels/info" { param($r) $r.Status -eq 200 } '200'
	Add-Check $Variant 'dev tools from a non-loopback peer' "http://$nicIp$Base/wheels/info" { param($r) $r.Status -eq 403 } '403'
	Add-Check $Variant 'reload redirect back to the page' "$h$Base/probe/hello?reload=true&password=wheels-dev" `
		{ param($r) $r.Status -in 301, 302, 303, 307 -and $r.Location -eq "$Base/probe/hello" } "redirect to $Base/probe/hello"
	Add-Check $Variant 'reload redirect, "//"-leading path' "$h$Base//example.com/x?reload=true&password=wheels-dev" `
		{ param($r) $r.Status -in 301, 302, 303, 307 -and $r.Location -eq "$Base/example.com/x" } "redirect to $Base/example.com/x"
}

$rootWebConfig = 'C:\wheels-iis\root\public\web.config'
Use-WebConfig (Join-Path $iisDir 'web.config.guide') $rootWebConfig
Test-Variant 'guide' ''
Use-WebConfig (Join-Path $iisDir 'web.config.root') $rootWebConfig
Test-Variant 'root' ''
Use-WebConfig (Join-Path $iisDir 'web.config.subfolder') 'C:\wheels-iis\app1\public\web.config'
Add-Check 'subfolder' 'app root without slash' 'http://127.0.0.1/app1' { param($r) $r.Status -in 200, 301, 302 } '200 or redirect to /app1/'
Test-Variant 'subfolder' '/app1'

$lines = @('## IIS + URL Rewrite + BonCode + Lucee 7', '', '| Variant | Check | Expected | Got | Result |', '|---|---|---|---|---|')
foreach ($r in $results) { $lines += "| $($r.Variant) | $($r.Check) | $($r.Expected) | $($r.Got) | $($r.Outcome) |" }
$lines | Set-Content -Path $report
if ($env:GITHUB_STEP_SUMMARY) { $lines | Add-Content -Path $env:GITHUB_STEP_SUMMARY }
$failed = @($results | Where-Object { $_.Outcome -eq 'FAIL' })
Write-Host "$($results.Count) checks, $($failed.Count) failed"
if ($failed.Count -gt 0) { exit 1 }
