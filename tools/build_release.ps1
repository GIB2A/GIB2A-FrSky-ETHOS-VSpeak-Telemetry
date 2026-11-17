$ErrorActionPreference = 'Stop'

$Root = Split-Path -Parent $PSScriptRoot
$Version = (Get-Content -Raw -LiteralPath (Join-Path $Root 'VERSION')).Trim()
$ExpectedVersion = '26.1.2-BETA'
$ExpectedMainHash = 'D73337350B8021984F82D2CA3198A88CE3A29AECEF14462A75D1D2E643F9AC0D'
$ExpectedLogoHash = '14EDE1DE9DDE6F644000F1481DCA817C6E782E183D1AB7D9314FCA6D99F4FA7B'
$Main = Join-Path $Root 'main.lua'
$Logo = Join-Path $Root 'gib2a_logo_ethos_180.png'
$Manifest = Join-Path $Root 'packaging\ethos_lua_manifest.json'
$ReleaseDir = Join-Path $Root 'releases\V26.1.2-BETA'
$SuiteName = 'GIB2A-VS-v26.1.2-BETA-ETHOS-Suite.zip'
$SdName = 'GIB2A-VS-v26.1.2-BETA-SD.zip'

if ($Version -ne $ExpectedVersion) { throw "Unexpected VERSION: $Version" }
if ((Get-FileHash -Algorithm SHA256 -LiteralPath $Main).Hash -ne $ExpectedMainHash) { throw 'main.lua hash mismatch' }
if ((Get-FileHash -Algorithm SHA256 -LiteralPath $Logo).Hash -ne $ExpectedLogoHash) { throw 'runtime logo hash mismatch' }

$Raw = [IO.File]::ReadAllBytes($Main)
if ($Raw.Length -ne 44581 -or ([IO.File]::ReadAllLines($Main)).Count -ne 1024) { throw 'main.lua size or line count mismatch' }
if ($Raw.Length -ge 3 -and $Raw[0] -eq 0xEF -and $Raw[1] -eq 0xBB -and $Raw[2] -eq 0xBF) { throw 'main.lua contains a UTF-8 BOM' }
if ($Raw -contains 13) { throw 'main.lua must use LF line endings' }
$null = [Text.UTF8Encoding]::new($false, $true).GetString($Raw)

$ManifestObject = Get-Content -Raw -LiteralPath $Manifest | ConvertFrom-Json
if ($ManifestObject.version -ne $ExpectedVersion -or $ManifestObject.folder -ne 'GIB2AVS') { throw 'manifest version or folder mismatch' }

New-Item -ItemType Directory -Force -Path $ReleaseDir | Out-Null
$SuitePath = Join-Path $ReleaseDir $SuiteName
$SdPath = Join-Path $ReleaseDir $SdName
foreach ($Path in @($SuitePath, $SdPath)) {
    if (Test-Path -LiteralPath $Path) { Remove-Item -LiteralPath $Path -Force }
}

Add-Type -AssemblyName System.IO.Compression
$Timestamp = [DateTimeOffset]::new(2026, 11, 17, 0, 0, 0, [TimeSpan]::Zero)

function New-DeterministicZip([string]$Path, [Collections.IDictionary]$Entries) {
    $Stream = [IO.File]::Open($Path, [IO.FileMode]::CreateNew)
    $Archive = [IO.Compression.ZipArchive]::new($Stream, [IO.Compression.ZipArchiveMode]::Create)
    try {
        foreach ($Name in @($Entries.Keys | Sort-Object)) {
            $Entry = $Archive.CreateEntry($Name, [IO.Compression.CompressionLevel]::Optimal)
            $Entry.LastWriteTime = $Timestamp
            $Input = [IO.File]::OpenRead($Entries[$Name])
            $Output = $Entry.Open()
            try { $Input.CopyTo($Output) } finally { $Output.Dispose(); $Input.Dispose() }
        }
    } finally {
        $Archive.Dispose()
        $Stream.Dispose()
    }
}

$SuiteEntries = [ordered]@{
    'CHANGELOG.md' = (Join-Path $Root 'CHANGELOG.md')
    'INSTALLATION.md' = (Join-Path $Root 'docs\INSTALLATION.md')
    'README.md' = (Join-Path $Root 'README.md')
    'ethos_lua_manifest.json' = $Manifest
    'gib2a_logo_ethos_180.png' = $Logo
    'main.lua' = $Main
}
$SdEntries = [ordered]@{
    'SCRIPTS/GIB2AVS/gib2a_logo_ethos_180.png' = $Logo
    'SCRIPTS/GIB2AVS/main.lua' = $Main
}

New-DeterministicZip $SuitePath $SuiteEntries
New-DeterministicZip $SdPath $SdEntries

$SuiteHash = (Get-FileHash -Algorithm SHA256 -LiteralPath $SuitePath).Hash
$SdHash = (Get-FileHash -Algorithm SHA256 -LiteralPath $SdPath).Hash
$ChecksumText = "$SuiteHash  $SuiteName`n$SdHash  $SdName`n$ExpectedMainHash  main.lua`n"
[IO.File]::WriteAllText((Join-Path $ReleaseDir 'SHA256SUMS.txt'), $ChecksumText, [Text.UTF8Encoding]::new($false))
Copy-Item -LiteralPath (Join-Path $Root 'docs\release-notes\V26.1.2-BETA.md') -Destination (Join-Path $ReleaseDir 'GITHUB_RELEASE_NOTES.md') -Force

Write-Output "${SuiteName}: $((Get-Item -LiteralPath $SuitePath).Length) bytes"
Write-Output "SHA-256: $SuiteHash"
Write-Output "${SdName}: $((Get-Item -LiteralPath $SdPath).Length) bytes"
Write-Output "SHA-256: $SdHash"
Write-Output 'Build: PASS'
