$ErrorActionPreference = 'Stop'

$Root = Split-Path -Parent $PSScriptRoot
$ReleaseDir = Join-Path $Root 'releases\V26.1.2-BETA'
$SuiteName = 'GIB2A-VS-v26.1.2-BETA-ETHOS-Suite.zip'
$SdName = 'GIB2A-VS-v26.1.2-BETA-SD.zip'
$SuitePath = Join-Path $ReleaseDir $SuiteName
$SdPath = Join-Path $ReleaseDir $SdName
$Main = Join-Path $Root 'main.lua'
$ExpectedMainHash = 'D73337350B8021984F82D2CA3198A88CE3A29AECEF14462A75D1D2E643F9AC0D'
$ExpectedLogoHash = '14EDE1DE9DDE6F644000F1481DCA817C6E782E183D1AB7D9314FCA6D99F4FA7B'
$Failures = [Collections.Generic.List[string]]::new()

function Check([bool]$Condition, [string]$Message) {
    if ($Condition) { Write-Output "PASS: $Message" }
    else { Write-Output "FAIL: $Message"; $script:Failures.Add($Message) }
}

$Raw = [IO.File]::ReadAllBytes($Main)
$Text = [Text.UTF8Encoding]::new($false, $true).GetString($Raw)
Check ((Get-Content -Raw -LiteralPath (Join-Path $Root 'VERSION')).Trim() -eq '26.1.2-BETA') 'VERSION'
Check ((Get-FileHash -Algorithm SHA256 -LiteralPath $Main).Hash -eq $ExpectedMainHash) 'main.lua SHA-256'
Check ($Raw.Length -eq 44581 -and ([IO.File]::ReadAllLines($Main)).Count -eq 1024) 'main.lua size and line count'
Check (-not ($Raw.Length -ge 3 -and $Raw[0] -eq 0xEF -and $Raw[1] -eq 0xBB -and $Raw[2] -eq 0xBF)) 'main.lua has no UTF-8 BOM'
Check (-not ($Raw -contains 13)) 'main.lua uses LF line endings'
Check ($Text.Contains('local WIDGET_VERSION = "V 26.1.2 BETA"')) 'internal widget version'
Check ($Text.Contains('local WIDGET_KEY = "GIB2AVS"')) 'internal widget key'
Check ($Text.Contains('name = "GIB2A TURBINE VSPEAK " .. WIDGET_VERSION')) 'registered widget title'
Check ($Text.Contains('local GIB2A_LOGO_PATH = "gib2a_logo_ethos_180.png"')) 'runtime logo path'
Check (-not $Text.Contains('sport.push') -and -not $Text.Contains('sport.write')) 'no S.Port control injection'

$PaintStart = $Text.IndexOf('local function paint(widget)')
$PaintEnd = $Text.IndexOf("`nlocal function addSourceLine", $PaintStart)
$Paint = if ($PaintStart -ge 0 -and $PaintEnd -gt $PaintStart) { $Text.Substring($PaintStart, $PaintEnd - $PaintStart) } else { '' }
Check ($Paint -ne '' -and $Paint -notmatch 'system\.getSource\s*\(' -and $Paint -notmatch '[:.]value\s*\(') 'paint uses cached telemetry only'

$Manifest = Get-Content -Raw -LiteralPath (Join-Path $Root 'packaging\ethos_lua_manifest.json') | ConvertFrom-Json
$ExpectedFiles = @('main.lua','gib2a_logo_ethos_180.png','README.md','CHANGELOG.md','INSTALLATION.md')
Check ($Manifest.manifestVersion -eq 1) 'manifestVersion = 1'
Check ($Manifest.name -eq 'GIB2A VS - VSpeak Telemetry Dashboard') 'manifest name'
Check ($Manifest.key -eq 'com.gib2a.ethos.vspeaktelemetry') 'manifest package key'
Check ($Manifest.version -eq '26.1.2-BETA') 'manifest version'
Check ($Manifest.folder -eq 'GIB2AVS') 'manifest install folder'
Check ($Manifest.folder -match '^[A-Za-z0-9][A-Za-z0-9._-]{0,63}$') 'manifest folder format'
Check ((Compare-Object $ExpectedFiles @($Manifest.files)).Count -eq 0 -and @($Manifest.files).Count -eq $ExpectedFiles.Count) 'manifest file list'
Check ((Get-FileHash -Algorithm SHA256 -LiteralPath (Join-Path $Root 'gib2a_logo_ethos_180.png')).Hash -eq $ExpectedLogoHash) 'runtime logo SHA-256'
Check (Test-Path -LiteralPath (Join-Path $Root 'docs\GIB2A-VS.png')) 'README image exists'

$Readme = Get-Content -Raw -LiteralPath (Join-Path $Root 'README.md')
Check ($Readme -match '^# GIB2A VS\s+### Advanced VSpeak Turbine Telemetry Dashboard for FrSky ETHOS\s+!\[GIB2A VS telemetry dashboard\]\(docs/GIB2A-VS\.png\)\s+\[Download GIB2A VS V26\.1\.2-BETA — ETHOS Suite ZIP\]\(https://github\.com/GIB2A/GIB2A-FrSky-ETHOS-VSpeak-Telemetry/releases/download/v26\.1\.2-BETA/GIB2A-VS-v26\.1\.2-BETA-ETHOS-Suite\.zip\)') 'README title, subtitle, image and direct download link order'
Check ($Readme.Contains('Tag: `v26.1.2-BETA`')) 'README release tag'
Check (-not $Readme.Contains('Auto Bind')) 'README does not claim Auto Bind'

Add-Type -AssemblyName System.IO.Compression.FileSystem
Check (Test-Path -LiteralPath $SuitePath) 'ETHOS Suite ZIP exists'
Check (Test-Path -LiteralPath $SdPath) 'SD ZIP exists'

if (Test-Path -LiteralPath $SuitePath) {
    $Archive = [IO.Compression.ZipFile]::OpenRead($SuitePath)
    try {
        $Names = @($Archive.Entries | ForEach-Object FullName)
        $ExpectedEntries = @('CHANGELOG.md','INSTALLATION.md','README.md','ethos_lua_manifest.json','gib2a_logo_ethos_180.png','main.lua')
        Check ((Compare-Object $ExpectedEntries $Names).Count -eq 0 -and $Names.Count -eq $ExpectedEntries.Count) 'exact ETHOS Suite ZIP structure'
        Check (-not ($Names | Where-Object { $_ -match '/' })) 'ETHOS Suite files are all at ZIP root'
        Check (-not ($Names | Where-Object { $_ -match '(^|/)\.git/|(^|/)tests?/|\.tmp$|\.bak$|\.orig$' })) 'ETHOS Suite contains no development files'
        $EmbeddedManifest = $Archive.GetEntry('ethos_lua_manifest.json')
        Check ($null -ne $EmbeddedManifest) 'manifest is at ZIP root'
        if ($null -ne $EmbeddedManifest) {
            $Reader = [IO.StreamReader]::new($EmbeddedManifest.Open(), [Text.Encoding]::UTF8)
            try { $Embedded = $Reader.ReadToEnd() | ConvertFrom-Json } finally { $Reader.Dispose() }
            Check ($Embedded.folder -eq 'GIB2AVS' -and $Embedded.version -eq '26.1.2-BETA') 'embedded manifest identity'
            $Missing = @($Embedded.files | Where-Object { $null -eq $Archive.GetEntry([string]$_) })
            Check ($Missing.Count -eq 0) 'all manifest files resolve from ZIP root'
        }
        $MainEntry = $Archive.GetEntry('main.lua')
        if ($null -ne $MainEntry) {
            $Stream = $MainEntry.Open(); $Memory = [IO.MemoryStream]::new()
            try { $Stream.CopyTo($Memory) } finally { $Stream.Dispose() }
            $Sha = [Security.Cryptography.SHA256]::Create()
            try { $Hash = ([BitConverter]::ToString($Sha.ComputeHash($Memory.ToArray()))).Replace('-','') } finally { $Sha.Dispose(); $Memory.Dispose() }
            Check ($Hash -eq $ExpectedMainHash) 'ETHOS Suite main.lua hash'
        } else { Check $false 'main.lua is at ZIP root' }
    } finally { $Archive.Dispose() }
}

if (Test-Path -LiteralPath $SdPath) {
    $Archive = [IO.Compression.ZipFile]::OpenRead($SdPath)
    try {
        $Names = @($Archive.Entries | ForEach-Object FullName)
        $ExpectedEntries = @('SCRIPTS/GIB2AVS/gib2a_logo_ethos_180.png','SCRIPTS/GIB2AVS/main.lua')
        Check ((Compare-Object $ExpectedEntries $Names).Count -eq 0 -and $Names.Count -eq $ExpectedEntries.Count) 'exact SD ZIP structure'
    } finally { $Archive.Dispose() }
}

$ChecksumPath = Join-Path $ReleaseDir 'SHA256SUMS.txt'
Check (Test-Path -LiteralPath $ChecksumPath) 'SHA256SUMS.txt exists'
if (Test-Path -LiteralPath $ChecksumPath) {
    $Checksums = @{}
    foreach ($Line in Get-Content -LiteralPath $ChecksumPath) {
        if ($Line -match '^([A-F0-9]{64})\s+(.+)$') { $Checksums[$Matches[2]] = $Matches[1] }
    }
    Check ($Checksums[$SuiteName] -eq (Get-FileHash -Algorithm SHA256 -LiteralPath $SuitePath).Hash) 'ETHOS Suite checksum'
    Check ($Checksums[$SdName] -eq (Get-FileHash -Algorithm SHA256 -LiteralPath $SdPath).Hash) 'SD ZIP checksum'
    Check ($Checksums['main.lua'] -eq $ExpectedMainHash) 'published main.lua checksum'
}

Write-Output 'LUA COMPILATION: requires a local Lua compiler or ETHOS validation environment'
Write-Output 'ETHOS SUITE / RADIO: installation and hardware validation remain external gates'
if ($Failures.Count -gt 0) { throw "Validation failed: $($Failures.Count) check(s)" }
Write-Output 'Result: PASS'
