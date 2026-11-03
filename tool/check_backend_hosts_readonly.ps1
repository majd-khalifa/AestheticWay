# PowerShell 7.2+ (.NET6 or newer). Public GET only: no credentials, cookies, redirects or response values.
$ErrorActionPreference = 'Stop'
Add-Type -AssemblyName System.Net.Http
foreach ($hostName in @('aestheticway.ae', 'api.aestheticway.ae')) {
    $dnsOk = $false
    try {
        $addresses = [Net.Dns]::GetHostAddresses($hostName)
        $dnsOk = $addresses.Count -gt 0
    } catch { }
    $tlsOk = $false
    $expiry = $null
    $tcp = [Net.Sockets.TcpClient]::new()
    $ssl = $null
    try {
        $tcp.ConnectAsync($hostName, 443).WaitAsync([TimeSpan]::FromSeconds(15)).GetAwaiter().GetResult()
        $ssl = [Net.Security.SslStream]::new($tcp.GetStream(), $false)
        # Default validation checks hostname, trust chain and certificate dates.
        $ssl.AuthenticateAsClientAsync($hostName).WaitAsync([TimeSpan]::FromSeconds(15)).GetAwaiter().GetResult()
        $tlsOk = $ssl.IsAuthenticated -and $ssl.IsEncrypted
        $expiry = $ssl.RemoteCertificate.GetExpirationDateString()
    } catch { } finally {
        if ($null -ne $ssl) { $ssl.Dispose() }
        $tcp.Dispose()
    }
    [pscustomobject]@{ Host = $hostName; DnsResolved = $dnsOk; TlsValidated = $tlsOk; CertificateExpires = $expiry } | ConvertTo-Json -Compress
    $handler = [Net.Http.HttpClientHandler]::new()
    $handler.AllowAutoRedirect = $false
    $handler.UseCookies = $false
    $client = [Net.Http.HttpClient]::new($handler)
    $client.Timeout = [TimeSpan]::FromSeconds(20)
    $client.MaxResponseContentBufferSize = 1048576
    $client.DefaultRequestHeaders.Accept.ParseAdd('application/json')
    try {
        $root = "https://$hostName/api/v1/"
        $response = $client.GetAsync($root + 'clinics/?page_size=1').GetAwaiter().GetResult()
        try {
            $text = $response.Content.ReadAsStringAsync().GetAwaiter().GetResult()
            $jsonOk = $false
            $keys = @()
            $itemKeys = @()
            try {
                $json = $text | ConvertFrom-Json
                $jsonOk = $null -ne $json -and ($text.TrimStart().StartsWith('{') -or $text.TrimStart().StartsWith('['))
                if ($text.TrimStart().StartsWith('{')) { $keys = @($json.PSObject.Properties.Name) }
                $items = if ($null -ne $json.results) { @($json.results) } elseif ($json -is [array]) { @($json) } else { @() }
                if ($items.Count -gt 0) { $itemKeys = @($items[0].PSObject.Properties.Name) }
            } catch { }
            # Report only the redirect origin/path: never query, fragment or body values.
            $location = $null
            if ($null -ne $response.Headers.Location) {
                $target = [Uri]::new([Uri]$root, $response.Headers.Location)
                $location = $target.GetLeftPart([UriPartial]::Path)
            }
            [pscustomobject]@{
                ApiRoot = $root
                Status = [int]$response.StatusCode
                ContentType = [string]$response.Content.Headers.ContentType
                RedirectTarget = $location
                JsonParsed = $jsonOk
                TopLevelKeys = $keys
                FirstClinicFieldNames = $itemKeys
            } | ConvertTo-Json -Depth 4 -Compress
        } finally { $response.Dispose() }
    } catch {
        [pscustomobject]@{ Host = $hostName; PublicGet = 'FAILED_OR_UNVERIFIED'; ErrorType = $_.Exception.GetType().Name } | ConvertTo-Json -Compress
    } finally { $client.Dispose() }
}
