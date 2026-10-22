# Public GETs only. Raw responses stay in memory; only allowlisted diagnostics are saved.
# Never add Authorization, cookies, credentials, patient endpoints, or raw response logging.
[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)][guid]$ClinicId,
    [uri]$ApiBase = 'https://aestheticway.ae/api/v1/',
    [string]$OutputPath = './public-clinic-contract-sanitized.json'
)
$ErrorActionPreference = 'Stop'
if ($ApiBase.Scheme -ne 'https' -or $ApiBase.UserInfo -or $ApiBase.Query -or $ApiBase.Fragment) {
    throw 'Use an HTTPS API base without credentials, query parameters, or fragments.'
}
function Read-Public([string]$RelativePath) {
    try {
        $result = Invoke-RestMethod -Uri ([uri]::new($ApiBase, $RelativePath)) -Method Get -MaximumRedirection 0 -TimeoutSec 20
        return @{ ok = $true; data = $result }
    } catch {
        # Do not print exception bodies/URLs: they can contain response data.
        $status = $null
        if ($_.Exception.Response) { $status = [int]$_.Exception.Response.StatusCode }
        return @{ ok = $false; status = $status }
    }
}
function Describe-Media($Value) {
    if ($Value -isnot [string] -or [string]::IsNullOrWhiteSpace($Value)) {
        return @{ present = $false; type = $(if ($null -eq $Value) { 'null' } else { $Value.GetType().Name }) }
    }
    $uri = $null
    $absolute = $Value.Trim() -match '^https?://' -and [uri]::TryCreate($Value.Trim(), [UriKind]::Absolute, [ref]$uri)
    $path = if ($absolute) { $uri.AbsolutePath } else { ($Value -split '[?#]', 2)[0] }
    $sha = [Security.Cryptography.SHA256]::Create()
    try { $hash = ([BitConverter]::ToString($sha.ComputeHash([Text.Encoding]::UTF8.GetBytes($path)))).Replace('-', '').ToLowerInvariant() }
    finally { $sha.Dispose() }
    # Paths/filenames may include personal names or numbers; share hashes, not paths.
    return [ordered]@{
        present = $true; type = 'string'; absolute = $absolute
        scheme = $(if ($absolute) { $uri.Scheme } else { $null })
        hostname = $(if ($absolute) { $uri.Host } else { $null })
        media_prefix = $path.StartsWith('/media/'); path_sha256 = $hash
        query_omitted = ($Value.Contains('?')); path_redacted = $true
    }
}
function Select-Clinic($Record) {
    if ($null -eq $Record) { return $null }
    $parsedId = [guid]::Empty
    $safeId = if ([guid]::TryParse([string]$Record.id, [ref]$parsedId)) { $parsedId.ToString() } else { $null }
    $rating = 0.0; $count = 0
    $validRating = [double]::TryParse([string]$Record.google_rating, [Globalization.NumberStyles]::Float, [Globalization.CultureInfo]::InvariantCulture, [ref]$rating)
    $validCount = [int]::TryParse([string]$Record.google_reviews_count, [ref]$count)
    return [ordered]@{
        id = $safeId
        logo = (Describe-Media $Record.logo); logo_url = (Describe-Media $Record.logo_url)
        cover_image = (Describe-Media $Record.cover_image); cover_image_url = (Describe-Media $Record.cover_image_url)
        video_url = (Describe-Media $Record.video_url); video_ad_file = (Describe-Media $Record.video_ad_file)
        gallery_images = @($Record.gallery_images | ForEach-Object { Describe-Media $_ })
        google_rating = $(if ($validRating -and $rating -ge 1 -and $rating -le 5) { $rating } else { $null })
        google_reviews_count = $(if ($validCount -and $count -ge 0) { $count } else { $null })
        google_place_id_configured = -not [string]::IsNullOrWhiteSpace([string]$Record.google_place_id)
        google_maps_url_configured = -not [string]::IsNullOrWhiteSpace([string]$Record.google_maps_url)
    }
}
$detailPath = "clinics/$ClinicId/"
$detail = Read-Public $detailPath
$directory = Read-Public 'clinics/?page_size=20'
$homeFeed = Read-Public 'home/feed/'
$directoryRows = if ($directory.ok) { @($directory.data.results) } else { @() }
$report = [ordered]@{
    schema = 'aestheticway-public-clinic-diagnostics-v1'
    captured_utc = [DateTime]::UtcNow.ToString('o'); api_hostname = $ApiBase.Host
    detail = @{ endpoint = "/api/v1/$detailPath"; ok = $detail.ok; status_on_failure = $detail.status; clinic = $(if ($detail.ok) { Select-Clinic $detail.data } else { $null }) }
    directory = @{ endpoint = '/api/v1/clinics/?page_size=20'; ok = $directory.ok; status_on_failure = $directory.status; first_page_only = $true; matches = @($directoryRows | Where-Object { $_.id -eq $ClinicId.ToString() } | ForEach-Object { Select-Clinic $_ }) }
    home = @{ endpoint = '/api/v1/home/feed/'; ok = $homeFeed.ok; status_on_failure = $homeFeed.status; nearby_matches = @($homeFeed.data.nearby_clinics | Where-Object { $_.id -eq $ClinicId.ToString() } | ForEach-Object { Select-Clinic $_ }); featured_matches = @($homeFeed.data.featured_ads | Where-Object { $_.clinic.id -eq $ClinicId.ToString() } | ForEach-Object { @{ clinic = (Select-Clinic $_.clinic); image_url = (Describe-Media $_.image_url); video_url = (Describe-Media $_.video_url) } }) }
}
$json = $report | ConvertTo-Json -Depth 12
[IO.File]::WriteAllText([IO.Path]::GetFullPath($OutputPath), $json, [Text.UTF8Encoding]::new($false))
Write-Output 'Saved allowlisted public diagnostics. No names, contact details, credentials, raw URLs, or patient data were saved.'
