$scoopDir = if ($env:SCOOP) { $env:SCOOP } else { "$env:USERPROFILE\scoop" }
. "$scoopDir/apps/scoop/current/lib/core.ps1"
. "$scoopDir/apps/scoop/current/lib/buckets.ps1"
. "$scoopDir/apps/scoop/current/lib/download.ps1"

function Repair-URL {
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

    $proxy_url = get_config proxy_url
    if (-not $proxy_url) {
        $proxy_url = get_config url_proxy 'https://scoop.201704.xyz'
        if ($proxy_url) { $proxy_url = "$proxy_url/" }
    }

    try {
        $ip = [System.Net.Dns]::GetHostAddresses(([System.Uri]$url).Host)[0].IPAddressToString
        $ipInfo = (Invoke-WebRequest -UseBasicParsing -Uri "https://ip.glimmer.ltd/1?ip=$ip" -Method Get -TimeoutSec 10).Content
        if (-not $ip -or ($ipInfo -notmatch '\u4E2D\u56FD|\u5185\u7F51')) {
            success "proxy: $url"
            return $proxy_url + $url
        }
    } catch {
        success "proxy: $url"
        return $proxy_url + $url
    }


    success "direct: $url"
    return $url
}


function Add-Handler {
    param([string]$Name, [scriptblock]$Logic)
    $HandlerName = "${Name}_sus_handler"
    Set-Item -Path "Function:global:$HandlerName" -Value $Logic -Force
    Set-Alias -Name $Name -Value $HandlerName -Scope Global -Option ReadOnly -Force
    Export-ModuleMember -Function $HandlerName -Alias $Name
}

Add-Handler -Name 'load_cfg' -Logic {
    param($file)
    $script:scoopConfig = . ${function:load_cfg} $file
    return $script:scoopConfig
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
