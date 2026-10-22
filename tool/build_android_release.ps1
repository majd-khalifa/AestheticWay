param(
    [Parameter(Mandatory = $true)]
    [ValidateRange(1, 2100000000)] [int] $BuildNumber,
    [ValidatePattern('^\d+\.\d+\.\d+$')] [string] $BuildName = '1.0.0'
)
$ErrorActionPreference = 'Stop'
$repoRoot = Split-Path -Parent $PSScriptRoot
foreach ($name in @('AW_ANDROID_STORE_FILE', 'AW_ANDROID_STORE_PASSWORD', 'AW_ANDROID_KEY_ALIAS', 'AW_ANDROID_KEY_PASSWORD')) {
    if ([string]::IsNullOrWhiteSpace([Environment]::GetEnvironmentVariable($name))) {
        throw "Missing external signing setting: $name"
    }
}
$storePath = [IO.Path]::GetFullPath($env:AW_ANDROID_STORE_FILE)
if (-not (Test-Path -LiteralPath $storePath -PathType Leaf)) { throw 'External signing file was not found.' }
if ($storePath.StartsWith($repoRoot + [IO.Path]::DirectorySeparatorChar, [StringComparison]::OrdinalIgnoreCase)) {
    throw 'Keep signing material outside the repository.'
}
Push-Location $repoRoot
try {
    & flutter pub get
    if ($LASTEXITCODE -ne 0) { throw 'Flutter dependency resolution failed.' }
    & flutter build appbundle --release --build-name $BuildName --build-number $BuildNumber --dart-define=API_BASE_URL=https://aestheticway.ae/api/v1/
    if ($LASTEXITCODE -ne 0) { throw 'Android release compilation failed.' }
    $bundle = Join-Path $repoRoot 'build/app/outputs/bundle/release/app-release.aab'
    if (-not (Test-Path -LiteralPath $bundle)) { throw 'Release AAB is missing.' }
    & jarsigner -verify $bundle
    if ($LASTEXITCODE -ne 0) { throw 'AAB signature verification failed.' }
    Get-FileHash -LiteralPath $bundle -Algorithm SHA256
    Write-Output "Signed AAB: $bundle"
    Write-Output 'Built locally; no application or signing credential was uploaded.'
}
finally { Pop-Location }
