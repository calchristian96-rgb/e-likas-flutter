<#
  Builds the release APK and prepares the two files to upload:
    dist/E-LIKAS-Mobile.apk   dist/version.json
  Windows PowerShell 5.1. See RELEASING.md. Example:
    .\tool\release.ps1 -NotesEn "Hazard map overlays" -NotesFil "Mga overlay ng hazard map"
#>
param(
  [string]$NotesEn = '',
  [string]$NotesFil = '',
  [string]$NotesBcl = '',
  [int]$MinBuild = 0,
  [string]$ApkUrl = 'https://e-likasligao.online/downloads/E-LIKAS-Mobile.apk'
)
$ErrorActionPreference = 'Stop'
Set-Location (Split-Path -Parent $PSScriptRoot)

if (-not (Test-Path 'android\key.properties')) {
  throw 'android\key.properties is missing: this build would be signed with the debug key and could not update installed apps.'
}
$v = Select-String -Path pubspec.yaml -Pattern '^version:\s*(\S+)\+(\d+)\s*$'
if (-not $v) { throw 'Could not read "version: x.y.z+N" from pubspec.yaml.' }
$version = $v.Matches[0].Groups[1].Value
$build = [int]$v.Matches[0].Groups[2].Value

flutter build apk --release --target-platform android-arm,android-arm64
if ($LASTEXITCODE -ne 0) { throw 'flutter build failed.' }
$built = 'build\app\outputs\flutter-apk\app-release.apk'

$sdk = @($env:ANDROID_HOME, $env:ANDROID_SDK_ROOT, "$env:LOCALAPPDATA\Android\Sdk") |
  Where-Object { $_ -and (Test-Path "$_\build-tools") } | Select-Object -First 1
if (-not $sdk) { throw 'Android SDK build-tools not found (set ANDROID_HOME).' }
$apksigner = Get-ChildItem "$sdk\build-tools" -Recurse -Filter apksigner.bat |
  Sort-Object { try { [version]$_.Directory.Name } catch { [version]'0.0' } } -Descending |
  Select-Object -First 1
if (-not $apksigner) { throw 'apksigner.bat not found in build-tools.' }
if (-not $env:JAVA_HOME -and -not (Get-Command java -ErrorAction SilentlyContinue)) {
  $jbr = "$env:ProgramFiles\Android\Android Studio\jbr"   # Android Studio's bundled JDK
  if (Test-Path "$jbr\bin\java.exe") { $env:JAVA_HOME = $jbr }
}
$certs = (& $apksigner.FullName verify --print-certs $built) -join "`n"
if ($LASTEXITCODE -ne 0) { throw "apksigner verify failed:`n$certs" }
if ($certs -match 'Android Debug') { throw 'The APK is signed with the Android Debug certificate.' }

New-Item -ItemType Directory -Force dist | Out-Null
Copy-Item $built 'dist\E-LIKAS-Mobile.apk' -Force
$apk = Get-Item 'dist\E-LIKAS-Mobile.apk'
$manifest = [ordered]@{
  latest_build   = $build
  latest_version = $version
  min_build      = $(if ($MinBuild -gt 0) { $MinBuild } else { 1 })
  apk_url        = $ApkUrl
  sha256         = (Get-FileHash $apk.FullName -Algorithm SHA256).Hash.ToLower()
  size_bytes     = [int64]$apk.Length
}
$notes = [ordered]@{}
if ($NotesEn) { $notes.en = $NotesEn }
if ($NotesFil) { $notes.fil = $NotesFil }
if ($NotesBcl) { $notes.bcl = $NotesBcl }
if ($notes.Count -gt 0) { $manifest.notes = $notes }
$json = $manifest | ConvertTo-Json -Depth 4
[IO.File]::WriteAllText((Join-Path (Get-Location) 'dist\version.json'), $json, (New-Object Text.UTF8Encoding $false))

Write-Host "Built $version (build $build), $([math]::Round($apk.Length / 1MB, 1)) MB. Signer OK."
Write-Host 'Upload dist\E-LIKAS-Mobile.apk FIRST, then dist\version.json LAST.'
