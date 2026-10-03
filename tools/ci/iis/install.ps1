# Installs the IIS test stack on a GitHub-hosted Windows runner (elevated):
# IIS + URL Rewrite, Lucee Express (Tomcat, AJP on 127.0.0.1:8009) and the BonCode
# IIS-to-Tomcat connector. Every download is pinned by SHA-256.
# Expects the apps to be deployed already (deploy.ps1): C:\wheels-iis\root and C:\wheels-iis\app1.
$ErrorActionPreference = 'Stop'
$ProgressPreference = 'SilentlyContinue'

$work = 'C:\wheels-iis-setup'
New-Item -ItemType Directory -Force -Path $work | Out-Null

function Get-Pinned([string]$Url, [string]$Sha256, [string]$OutFile) {
	Invoke-WebRequest -Uri $Url -OutFile $OutFile -UseBasicParsing
	$actual = (Get-FileHash -Path $OutFile -Algorithm SHA256).Hash.ToLowerInvariant()
	if ($actual -ne $Sha256) { throw "Checksum mismatch for ${Url}: expected $Sha256, got $actual" }
	Write-Host "verified $OutFile"
}

# 1. IIS. ASP.NET 4.5 is needed by BonCode's managed handler.
Install-WindowsFeature -Name Web-Server, Web-Default-Doc, Web-Static-Content, Web-Http-Errors, `
	Web-Asp-Net45, Web-Net-Ext45, Web-ISAPI-Ext, Web-ISAPI-Filter, Web-Mgmt-Console -IncludeManagementTools | Out-Host

# 2. IIS URL Rewrite 2.1
$msi = Join-Path $work 'rewrite_amd64_en-US.msi'
Get-Pinned 'https://download.microsoft.com/download/1/2/8/128E2E22-C1B9-44A4-BE2A-5859ED1D4592/rewrite_amd64_en-US.msi' `
	'37342ff2f585f263f34f48e9de59eb1051d61015a8e967dbde4075716230a32a' $msi
$p = Start-Process msiexec.exe -ArgumentList '/i', $msi, '/qn', '/norestart' -Wait -PassThru
if ($p.ExitCode -notin 0, 3010) { throw "URL Rewrite install failed: $($p.ExitCode)" }

# 3. Lucee Express (Tomcat). The AJP connector on 8009 is enabled in its server.xml.
$luceeZip = Join-Path $work 'lucee-express.zip'
Get-Pinned 'https://cdn.lucee.org/lucee-express-7.0.1.100.zip' `
	'e2f995d8993747dc782a1c50899aeca40db3cf8993eaf025f8adc61c7dce87e9' $luceeZip
Expand-Archive -Path $luceeZip -DestinationPath 'C:\lucee' -Force
$serverXml = 'C:\lucee\conf\server.xml'
$xml = Get-Content $serverXml -Raw
# Bind AJP to loopback only.
$xml = $xml -replace '(<Connector protocol="AJP/1\.3"\s+port="8009")', '$1 address="127.0.0.1"'
Set-Content -Path $serverXml -Value $xml
# One Tomcat context per IIS application; no default ROOT webapp.
Remove-Item -Recurse -Force 'C:\lucee\webapps\ROOT' -ErrorAction SilentlyContinue
$ctxDir = 'C:\lucee\conf\Catalina\localhost'
New-Item -ItemType Directory -Force -Path $ctxDir | Out-Null
Set-Content -Path (Join-Path $ctxDir 'ROOT.xml') -Value '<Context docBase="C:\wheels-iis\root\public" />'
Set-Content -Path (Join-Path $ctxDir 'app1.xml') -Value '<Context docBase="C:\wheels-iis\app1\public" />'
Start-Process -FilePath 'C:\lucee\bin\catalina.bat' -ArgumentList 'start' -WorkingDirectory 'C:\lucee\bin' -WindowStyle Hidden
$up = $false
foreach ($i in 1..90) {
	try { $r = Invoke-WebRequest -Uri 'http://127.0.0.1:8888/index.cfm' -UseBasicParsing -TimeoutSec 10; $up = $true; break }
	catch { if ($_.Exception.Response) { $up = $true; break }; Start-Sleep -Seconds 2 }
}
if (-not $up) { Get-ChildItem C:\lucee\logs | ForEach-Object { Write-Host "== $($_.Name)"; Get-Content $_.FullName -Tail 40 }; throw 'Lucee did not start' }
Write-Host 'Lucee Express is up on 127.0.0.1:8888'

# 4. IIS site at the root app's public\, and /app1 as an application at app1\public\.
# appcmd rather than the WebAdministration module, which PowerShell 7 only loads through a
# compatibility session (no IIS: drive).
$appcmd = Join-Path $env:windir 'system32\inetsrv\appcmd.exe'
& $appcmd set vdir 'Default Web Site/' '-physicalPath:C:\wheels-iis\root\public' | Out-Host
if ($LASTEXITCODE -ne 0) { throw "appcmd set vdir failed: $LASTEXITCODE" }
& $appcmd add app '/site.name:Default Web Site' '/path:/app1' '/physicalPath:C:\wheels-iis\app1\public' | Out-Host
if ($LASTEXITCODE -ne 0) { throw "appcmd add app failed: $LASTEXITCODE" }
icacls 'C:\wheels-iis' /grant 'IIS_IUSRS:(OI)(CI)RX' 'IUSR:(OI)(CI)RX' /T /Q | Out-Null

# 5. BonCode connector, global install with the CFML handlers (silent mode, per its manual).
$bonZip = Join-Path $work 'AJP13.zip'
Get-Pinned 'https://github.com/Bilal-S/iis2tomcat/releases/download/1.0.50/AJP13_v1050.zip' `
	'0683eb0dbf8939563408d1cc8b6ab726a81db4869c8a70616187d527ce951b11' $bonZip
Expand-Archive -Path $bonZip -DestinationPath $work -Force
$bonDir = Join-Path $work 'AJP13'
@"
[Setup]
installType=global
acceptLicense=1
enableRemote=0

[Handlers]
installCF=1
installJSP=0
installWildCard=0

[Tomcat]
server=127.0.0.1
ajpPort=8009
configureServerXml=0
"@ | Set-Content -Path (Join-Path $bonDir 'installer.settings')
$p = Start-Process -FilePath (Join-Path $bonDir 'Connector_Setup.exe') `
	-ArgumentList '/VERYSILENT', '/SUPPRESSMSGBOXES', '/LOG', '/SP-', '/NOCANCEL', '/NORESTART' -Wait -PassThru
if ($p.ExitCode -ne 0) { throw "BonCode install failed: $($p.ExitCode)" }
if (Test-Path 'C:\Windows\BonCodeAJP13.settings') { Write-Host '== BonCodeAJP13.settings'; Get-Content 'C:\Windows\BonCodeAJP13.settings' }

iisreset /restart | Out-Host
Write-Host '== CFML handler mappings for Default Web Site'
& $appcmd list config 'Default Web Site' /section:handlers | Select-String -Pattern '\.cf' | Out-Host
exit 0
