# scoop-accelerator

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

如果你想要直接使用请运行以下命令:

```powershell
# GitHub
scoop config scoop-accelerator-rule-github "^https://github.com -> https://v4.gh-proxy.org/https://github.com"
scoop config scoop-accelerator-rule-github-raw "^https://raw.githubusercontent.com -> https://v4.gh-proxy.org/https://raw.githubusercontent.com"
scoop config scoop-accelerator-rule-github-gist "^https://gist.githubusercontent.com -> https://v4.gh-proxy.org/https://gist.githubusercontent.com"
# SourceForge
scoop config scoop-accelerator-rule-sourceforge "^https://downloads.sourceforge.net -> https://v4.gh-proxy.org/sourceforge/https://downloads.sourceforge.net"
# NodeJS
scoop config scoop-accelerator-rule-nodejs "^https://nodejs.org/dist/ -> https://registry.npmmirror.com/-/binary/node/"
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
    if ($property.Name -like 'scoop-accelerator-rule-*') {
        scoop config rm $property.Name
    }
}
```

## 配置

本应用使用 `scoop config` 进行配置

| 配置项                     | 描述                                             | 默认值  |
| -------------------------- | ------------------------------------------------ | ------- |
| `download_proxy_enabled`   | 是否开启下载时自动替换镜像功能                   | `$true` |
| `bucket_proxy_enabled`     | 是否开启添加 `Bucket` 时自动替换镜像功能         | `$true` |
| `scoop-accelerator-rule-*` | 按照 `原内容正则 -> 替换内容` 的格式进行替换     | 无      |
| `proxy_url`                | 如果没有匹配到规则, 根据 ip 判断为国外时进行替换 | 无      |

## 灵感来源

- [scoop-tools](https://github.com/abgox/scoop-tools)
- [scoop-i18n](https://github.com/abgox/scoop-i18n)
