# Offline privacy regression: no HTTP request is made by this test.
$ErrorActionPreference = 'Stop'
$testProbe = @{ Requests = [Collections.Generic.List[string]]::new() }
$testId = '11111111-1111-4111-8111-111111111111'
$record = @{
    id = $testId; full_name = 'PRIVATE_SENTINEL'; phone = '+971501234567'; email = 'PRIVATE_SENTINEL@example.test'
    logo = 'https://aestheticway.ae/media/PRIVATE_SENTINEL.png?signature=PRIVATE_SENTINEL'
    cover_image = '/media/PRIVATE_SENTINEL.jpg'; gallery_images = @('/media/PRIVATE_SENTINEL.jpg')
    google_rating = '4.6'; google_reviews_count = 123; google_place_id = 'configured'
}
function Invoke-RestMethod {
    param($Uri, $Method, $MaximumRedirection, $TimeoutSec)
    $testProbe.Requests.Add([string]$Uri)
    if ($Method -ne 'Get' -or $Uri.Host -ne 'aestheticway.ae' -or $MaximumRedirection -ne 0) { throw 'Unsafe request' }
    if ($Uri.AbsolutePath.EndsWith('/home/feed/')) { return @{ nearby_clinics = @($record); featured_ads = @() } }
    if ($Uri.Query) { return @{ results = @($record) } }
    return $record
}
$destination = Join-Path ([IO.Path]::GetTempPath()) ('aw-public-contract-' + [guid]::NewGuid() + '.json')
try {
    & "$PSScriptRoot/capture_public_clinic_contract.ps1" -ClinicId $testId -OutputPath $destination
    $raw = [IO.File]::ReadAllText($destination)
    if ($raw.Contains('PRIVATE_SENTINEL') -or $raw.Contains('+971501234567') -or $raw.Contains('signature=')) { throw 'Sensitive response data escaped the allowlist' }
    $summary = $raw | ConvertFrom-Json
    if ($testProbe.Requests.Count -ne 3 -or $summary.detail.clinic.google_rating -ne 4.6 -or $summary.detail.clinic.google_reviews_count -ne 123) { throw ('Public contract summary is incomplete: requests={0}, rating={1}, count={2}' -f $testProbe.Requests.Count, $summary.detail.clinic.google_rating, $summary.detail.clinic.google_reviews_count) }
    if (!$summary.detail.clinic.logo.query_omitted -or !$summary.detail.clinic.logo.path_redacted -or $summary.detail.clinic.logo.path_sha256.Length -ne 64) { throw 'Media redaction failed' }
    Write-Output 'Offline public-contract privacy regression passed.'
} finally { if (Test-Path $destination) { Remove-Item $destination } }
