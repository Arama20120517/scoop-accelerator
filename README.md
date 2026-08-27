# scoop-accelerator

Scoop 下载加速器. 支持将 GitHub、SourceForge、Node.js 的请求重定向至国内高速镜像, 告别下载超时.

## 安装

> 建议 [scoop国内镜像优化库](https://gitee.com/scoop-installer/scoop) 一起使用, 以达到加速自身安装的效果

### 1. 添加 Bucket

Gitee:

```powershell
scoop bucket add sa https://gitee.com/Arama20120517/scoop-accelerator
```

GitHub (可能无法连接):

```powershell
scoop bucket add sa https://github.com/Arama20120517/scoop-accelerator
```

### 2. 安装

```powershell
scoop install sa/scoop-accelerator
```

## 卸载

```powershell
scoop uninstall scoop-accelerator
scoop bucket rm sa
```

## 支持的配置

> [!WARNING]
> 请检查你的 URL 最后是否有一个 `/` 用于脚本拼接

请使用 `scoop config` 进行配置

例如: `scoop config github_proxy_url "https://v4.gh-proxy.org/"`

| 配置项                   | 描述                                                                                                  | 默认值                                          |
| ------------------------ | ----------------------------------------------------------------------------------------------------- | ----------------------------------------------- |
| `download_proxy_enabled` | 是否开启下载时自动替换镜像功能                                                                        | `$true`                                         |
| `bucket_proxy_enabled`   | 是否开启添加 `Bucket` 时自动替换镜像功能                                                              | `$true`                                         |
| `github_proxy_url`       | 用于 `github.com` 和 `*.githubusercontent.com` 的镜像网址                                             | `https://v4.gh-proxy.org/`                      |
| `sourceforge_proxy_url`  | 用于 `*.sourceforge.net` 的镜像网址                                                                   | `https://v4.gh-proxy.org/sourceforge/`          |
| `nodejs_proxy_url`       | 用于 `nodejs.org/dist` 的镜像网址                                                                     | `https://registry.npmmirror.com/-/binary/node/` |
| `proxy_url`              | 如果不匹配上面的规则, 根据 ip 判断为国外时进行替换; 如果本配置和 `url_proxy` 同时存在, 优先使用本配置 | `https://scoop.201704.xyz/`                     |
