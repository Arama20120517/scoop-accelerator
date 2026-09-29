# scoop-accelerator (sa)

Scoop 下载加速器. 支持按照自定义规则进行重定向.

## 安装

> 建议 [scoop国内镜像优化库](https://gitee.com/scoop-installer/scoop) 一起使用, 以达到加速自身安装的效果

### 1. 添加 Bucket

Gitee:

```powershell
scoop bucket add arama https://gitee.com/Arama20120517/scoop-bucket
```

GitHub (可能无法连接):

```powershell
scoop bucket add arama https://github.com/Arama20120517/scoop-bucket
```

### 2. 安装应用

```powershell
scoop install arama/scoop-accelerator
```

### 3. 设置规则

本应用会识别 `scoop-accelerator-rule` 为开头的 `Scoop` 配置并按照 `原内容正则 -> 替换内容` 的格式进行替换

运行类似以下的命令以配置推荐规则, 命令将会在安装完成后自动输出:

```powershell
. "C:\Users\Example\scoop\apps\scoop-accelerator\current\setup-rules.ps1"
```

## 卸载

### 1. 卸载应用

```powershell
scoop uninstall scoop-accelerator
```

### 2. 卸载 Bucket

```powershell
scoop bucket rm arama
```

### 3. 删除规则

```powershell
foreach ($property in $(scoop config).PSObject.Properties) {
    if ($property.Name -like 'sa-rule-*') {
        scoop config rm $property.Name
    }
}
```

## 配置

本应用使用 `scoop config` 进行配置

### sa-download-enabled

是否开启在下载时根据规则替换链接的功能

此配置默认为开启 (`$true`)

使用以下命令切换开启和关闭:

```powershell
# 关闭
scoop config sa-download-enabled $false
# 开启
scoop config sa-download-enabled $true
```

### sa-bucket-enabled

是否开启添加 `Bucket` 时根据规则替换链接的功能

此配置默认为开启 (`$true`)

使用以下命令切换开启和关闭:

```powershell
# 关闭
scoop config sa-bucket-enabled $false
# 开启
scoop config sa-bucket-enabled $true
```

### sa-rule

如果启用了 `sa-download-proxy-enabled` 或者 `sa-bucket-proxy-enabled`, 将自动根据规则替换链接

配置名称格式为 `sa-rule-提示内容`

规则格式为 `原内容正则表达式` -> `替换内容`

例如:

```powershell
scoop config sa-rule-github '^https://github.com -> https://v4.gh-proxy.org/https://github.com'

scoop download uv
# 下载链接将会被替换为: https://v4.gh-proxy.org/https://github.com/astral-sh/uv/releases/download/0.12.20/uv-x86_64-pc-windows-msvc.zip
# 应用会输出类似以下内容:
# github proxy: https://github.com/astral-sh/uv/releases/download/0.12.20/uv-x86_64-pc-windows-msvc.zip
```

### sa-general-rule

如果启用了 `sa-download-proxy-enabled` 或者 `sa-bucket-proxy-enabled`时,
在没有匹配到任何规则时将使用本配置替换下载链接

应用会自动将配置中的 `{{url}}` 替换为下载链接

例如:

```powershell
scoop config sa-general-rule "https://example.com/{{url}}"

scoop download uv
# 下载链接将会被替换为: https://example.com/https://github.com/astral-sh/uv/releases/download/0.12.20/uv-x86_64-pc-windows-msvc.zip
# 应用会输出类似以下内容:
# proxy: https://github.com/astral-sh/uv/releases/download/0.12.20/uv-x86_64-pc-windows-msvc.zip
```

## 灵感来源

- [scoop-tools](https://github.com/abgox/scoop-tools)
- [scoop-i18n](https://github.com/abgox/scoop-i18n)
