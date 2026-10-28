# Disposable QA signing only. Never uploads the app or uses a store signing key.
param([Parameter(Mandatory = $true)][ValidateRange(1, 2100000000)][int]$BuildNumber, [switch]$IncludeBundle)
$ErrorActionPreference = 'Stop'
$repoRoot = Split-Path -Parent $PSScriptRoot
$qaKeyDir = Join-Path ([IO.Path]::GetTempPath()) ('aw-preview-' + [Guid]::NewGuid().ToString('N'))
$names = @('AW_ANDROID_STORE_FILE', 'AW_ANDROID_STORE_PASSWORD', 'AW_ANDROID_KEY_ALIAS', 'AW_ANDROID_KEY_PASSWORD')
$previous = @{}
foreach ($name in $names) { $previous[$name] = [Environment]::GetEnvironmentVariable($name, 'Process') }
New-Item -ItemType Directory -Path $qaKeyDir | Out-Null
Push-Location $repoRoot
try {
    $randomBytes = New-Object byte[] 32
    $rng = [Security.Cryptography.RandomNumberGenerator]::Create()
    try { $rng.GetBytes($randomBytes) } finally { $rng.Dispose() }
    $env:AW_ANDROID_STORE_FILE = Join-Path $qaKeyDir 'disposable-preview.jks'
    $env:AW_ANDROID_STORE_PASSWORD = [Convert]::ToBase64String($randomBytes)
    $env:AW_ANDROID_KEY_PASSWORD = $env:AW_ANDROID_STORE_PASSWORD
    $env:AW_ANDROID_KEY_ALIAS = 'aw-disposable-preview'
    & keytool -genkeypair -keystore $env:AW_ANDROID_STORE_FILE -storetype JKS -alias $env:AW_ANDROID_KEY_ALIAS -keyalg RSA -keysize 2048 -validity 3 -dname 'CN=AW Disposable Client Preview' -storepass:env AW_ANDROID_STORE_PASSWORD -keypass:env AW_ANDROID_KEY_PASSWORD
    if ($LASTEXITCODE -ne 0) { throw 'Could not create disposable QA key.' }
    & flutter pub get
    if ($LASTEXITCODE -ne 0) { throw 'Dependency resolution failed.' }
    & flutter build apk --release --build-number $BuildNumber --dart-define=API_BASE_URL=https://aestheticway.ae/api/v1/
    if ($LASTEXITCODE -ne 0) { throw 'QA APK compilation failed.' }
    $apk = Join-Path $repoRoot 'build/app/outputs/flutter-apk/app-release.apk'
    $sdk = $env:ANDROID_HOME
    if ([string]::IsNullOrWhiteSpace($sdk)) { $sdk = Join-Path $env:LOCALAPPDATA 'Android/Sdk' }
    $signer = Join-Path $sdk 'build-tools/36.0.0/apksigner.bat'
    if (-not (Test-Path -LiteralPath $signer)) { throw 'Install Android build-tools 36.0.0 to verify the APK.' }
    & $signer verify --verbose $apk
    if ($LASTEXITCODE -ne 0) { throw 'APK signature verification failed.' }
    Get-FileHash -LiteralPath $apk -Algorithm SHA256
    Write-Output "QA-signed APK: $apk"
    if ($IncludeBundle) {
        & flutter build appbundle --release --build-number $BuildNumber --dart-define=API_BASE_URL=https://aestheticway.ae/api/v1/
        if ($LASTEXITCODE -ne 0) { throw 'QA AAB compilation failed.' }
        $aab = Join-Path $repoRoot 'build/app/outputs/bundle/release/app-release.aab'
        & jarsigner -verify $aab
        if ($LASTEXITCODE -ne 0) { throw 'AAB signature verification failed.' }
        Get-FileHash -LiteralPath $aab -Algorithm SHA256
    }
    Write-Output 'No application, signing key or credential was uploaded. This key is disposable and cannot update store-signed installs.'
}
finally {
    Pop-Location
    Remove-Item -LiteralPath $qaKeyDir -Recurse -Force
    foreach ($name in $names) { [Environment]::SetEnvironmentVariable($name, $previous[$name], 'Process') }
}
