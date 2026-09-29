try {
    Microsoft.PowerShell.Core\Set-StrictMode -Off
} catch {
    return
}

function Script:Test-IsPrivateOrLocalIP {
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

function Script:Repair-URL {
    param([string]$url)

    $url = $url -replace 'https?://[^\s]*?(?=https?://)', ''

    foreach ($property in $scoopConfig.PSObject.Properties) {
        if ($property.Name -match '^sa-rule-(.+)$') {
            $ruleName = $Matches[1]

            $parts = $property.Value -split ' -> '
            if ($parts.Count -ne 2) {
                warn "检测到无效规则: $($property.Name)"
                continue
            }

            $originPattern, $replacePattern = $parts
            if ($url -match $originPattern) {
                success "$ruleName proxy: $url"
                return $url -replace $originPattern, $replacePattern
            }
        }
    }

    $rule = get_config sa-general-rule
    if ($rule) {
        try {
            $ip = [System.Net.Dns]::GetHostAddresses(([System.Uri]$url).Host)[0]
            if (Test-IsPrivateOrLocalIP $ip) {
                success "local direct: $url"
                return $url
            }
            $ipInfo = Invoke-RestMethod -Uri "https://ip9.com.cn/get?ip=$($ip.IPAddressToString)" -TimeoutSec 10
            if ($ipInfo.ret -eq 200 -and $ipInfo.data.country_code -ne 'cn') {
                success "proxy: $url"
                return $rule -replace '{{url}}', $url
            }
        } catch {
            success "fallback: $url"
            return $url
        }
    }

    success "direct: $url"
    return $url
}

function Script:Add-Handler {
    param([string]$Name, [scriptblock]$Logic)
    $HandlerName = "${Name}_sa_handler"
    Set-Item -Path "Function:\Script:$HandlerName" -Value $Logic -Force
    Set-Alias -Name $Name -Value $HandlerName -Scope Script -Option ReadOnly -Force
}

function Script:Update-Shim([switch]$EnableI18N) {
    Get-ChildItem "$(appdir scoop-accelerator)\current\template" | ForEach-Object {
        $content = Get-Content $_.FullName -Raw
        $content = $content.Replace('${scoop.ps1}', ". '$(appdir scoop)\current\bin\scoop.ps1'")
        $content = $content.Replace('${scoop-accelerator.ps1}', ". '$(appdir scoop-accelerator)\current\scoop-accelerator.ps1'")
        if ($EnableI18N) {
            $content = $content.Replace('${scoop-i18n.ps1}', ". '$(appdir 'abgox.scoop-i18n')\current\app\scoop-i18n.ps1'")
        } else {
            $content = $content.Replace('${scoop-i18n.ps1}', '')
        }
        [System.IO.File]::WriteAllText("$(appdir scoop-accelerator)\current\shims\$($_.Name)", ($content -join [System.Environment]::NewLine), [System.Text.UTF8Encoding]::new($false))
    }
}

Add-Handler -Name 'Url_Proxy' -Logic {
    param($url)
    return $url
}

Add-Handler -Name 'url_manifest' -Logic {
    param($url)
    if (get_config sa-download-enabled $true) { $url = Repair-URL $url }
    return . ${function:url_manifest} $url
}

Add-Handler -Name 'handle_special_urls' -Logic {
    param($url)
    $url = . ${function:handle_special_urls} $url
    if (get_config sa-download-enabled $true) { $url = Repair-URL $url }
    return $url
}

Add-Handler -Name 'add_bucket' -Logic {
    param($name, $repo)
    if (get_config sa-bucket-enabled $true) { $repo = Repair-URL $repo }
    return . ${function:add_bucket} $name $repo
}

Add-Handler -Name 'shim' -Logic {
    param($path, $global, $name, $arg)
    if ($path -eq ((versiondir 'scoop' 'current') + '\bin\scoop.ps1')) {
        Get-ChildItem "$(appdir scoop-accelerator)\current\shims" | ForEach-Object {
            Copy-Item $_.FullName "$scoopdir\shims" -Force
        }
        return
    }
    return . ${function:shim} $path $global $name $arg
}

Add-Handler -Name 'Invoke-HookScript' -Logic {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [ValidateSet('installer', 'pre_install', 'post_install', 'uninstaller', 'pre_uninstall', 'post_uninstall')]
        [String] $HookType,
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [PSCustomObject] $Manifest,
        [Parameter(Mandatory = $true)]
        [Alias('Arch', 'Architecture')]
        [ValidateSet('32bit', '64bit', 'arm64')]
        [string]
        $ProcessorArchitecture
    )

    if ($Manifest.homepage -eq 'https://scoop-i18n.abgox.com' -and $Manifest.autoupdate.url -eq 'https://github.com/abgox/scoop-i18n/archive/$matchSha.zip') {
        if ($HookType -eq 'pre_install') {
            # "    Move-Item \"$scoopdir\\shims\\$($_.Name)\" \"$dir\\app\\original\"",
            $Manifest.pre_install[6] = '    Copy-Item "$scoopdir\apps\scoop-accelerator\current\original\$($_.Name)" "$dir\app\original" -Force'
            # "Get-ChildItem \"$dir\\app\\shims\" | ForEach-Object {",
            $Manifest.pre_install[12] = 'Get-ChildItem "$scoopdir\apps\scoop-accelerator\current\shims" | ForEach-Object {'
            Update-Shim -EnableI18N
        } elseif ($HookType -eq 'pre_uninstall') {
            # "Get-ChildItem \"$dir\\app\\original\" | ForEach-Object {",
            $Manifest.pre_uninstall[3] = 'Get-ChildItem "$scoopdir\apps\scoop-accelerator\current\shims" | ForEach-Object {'
            Update-Shim
        }
    }

    return . ${function:Invoke-HookScript} -HookType $HookType -Manifest $Manifest -ProcessorArchitecture $ProcessorArchitecture
}
