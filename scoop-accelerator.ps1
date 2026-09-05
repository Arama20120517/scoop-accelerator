try {
    Microsoft.PowerShell.Core\Set-StrictMode -Off
} catch {
    return
}

function script:Test-IsPrivateOrLocalIP {
    param([System.Net.IPAddress]$ip)
    if ([System.Net.IPAddress]::IsLoopback($ip)) { return $true }

    if ($ip.AddressFamily -eq 'InterNetworkV6') {
        return ($ip.IsIPv6LinkLocal -or $ip.IsIPv6SiteLocal -or $ip.IsIPv6UniqueLocal)
    }

    $bytes = $ip.GetAddressBytes()
    if ($bytes.Length -eq 4) {
        if ($bytes[0] -eq 10) { return $true }                                               # 10.0.0.0/8
        if ($bytes[0] -eq 172 -and $bytes[1] -ge 16 -and $bytes[1] -le 31) { return $true }  # 172.16.0.0/12
        if ($bytes[0] -eq 192 -and $bytes[1] -eq 168) { return $true }                       # 192.168.0.0/16
        if ($bytes[0] -eq 169 -and $bytes[1] -eq 254) { return $true }                       # 169.254.0.0/16 (APIPA)
        if ($bytes[0] -eq 100 -and $bytes[1] -ge 64 -and $bytes[1] -le 127) { return $true } # 100.64.0.0/10 (CGNAT)
    }
    return $false
}

function script:Repair-URL {
    param([string]$url)

    $url = $url -replace 'https?://[^\s]*?(?=https?://)', ''

    if ($url -match 'github\.com|githubusercontent\.com') {
        success "github proxy: $url"
        return (get_config github_proxy_url 'https://v4.gh-proxy.org/') + $url
    } elseif ($url -match 'sourceforge\.net') {
        success "sourceforge proxy: $url"
        return (get_config sourceforge_proxy_url 'https://v4.gh-proxy.org/sourceforge/') + $url
    } elseif ($url -match '^https?://nodejs\.org/dist/') {
        success "nodejs proxy: $url"
        return $url -replace '^https?://nodejs\.org/dist/', (get_config nodejs_proxy_url 'https://registry.npmmirror.com/-/binary/node/')
    }

    $proxy_url = get_config proxy_url ((get_config url_proxy 'https://scoop.201704.xyz') + '/')

    try {
        $ip = [System.Net.Dns]::GetHostAddresses(([System.Uri]$url).Host)[0]
        if (Test-IsPrivateOrLocalIP $ip) {
            throw
        }

        $ipInfo = Invoke-RestMethod -Uri "http://ip-api.com/json/$($ip.IPAddressToString)?fields=status,countryCode" -TimeoutSec 10
        if ($ipInfo.status -eq 'success' -and $ipInfo.countryCode -ne 'CN') {
            success "proxy: $url"
            return $proxy_url + $url
        }
    } catch {}

    success "direct: $url"
    return $url
}


function script:Add-Handler {
    param([string]$Name, [scriptblock]$Logic)
    $HandlerName = "${Name}_sa_handler"
    Set-Item -Path "Function:\script:$HandlerName" -Value $Logic -Force
    Set-Alias -Name $Name -Value $HandlerName -Scope Script -Option ReadOnly -Force
}

Add-Handler -Name 'Url_Proxy' -Logic {
    param($url)
    return $url
}

Add-Handler -Name 'handle_special_urls' -Logic {
    param($url)
    $url = . ${function:handle_special_urls} $url
    if (get_config download_proxy_enabled $true) { $url = Repair-URL $url }
    return $url
}

Add-Handler -Name 'add_bucket' -Logic {
    param($name, $repo)
    if (get_config bucket_proxy_enabled $true) { $repo = Repair-URL $repo }
    return . ${function:add_bucket} $name $repo
}
