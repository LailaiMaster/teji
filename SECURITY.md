# 安全说明

## 数据敏感性

特迹读取的数据可能包含车辆精确位置、家庭和工作地址、实时状态、行程历史及充电记录。请把 API 和 TeslaMate 数据库视为敏感的家庭基础设施。

## 部署边界

当前 API 没有内置用户认证。推荐仅通过以下方式访问：

- 家庭局域网；
- WireGuard、Tailscale、ZeroTier 等可信 VPN；
- 配置了 HTTPS 和身份认证的反向代理。

不要把 API 端口直接映射到公网。数据库端口也不应暴露给客户端或公网。

生产部署应使用权限受限、只允许读取所需表的 PostgreSQL 账号，并限制 `CORS_ALLOW_ORIGINS`，避免使用默认的通配符配置。

## 凭据与日志

- 不要提交 `.env`、`key.properties`、签名文件、高德 Key 或数据库密码。
- 不要在 Issue 中粘贴包含地址、坐标、车辆名称或私有域名的完整响应。
- 分享截图前检查地图、起终点和车辆昵称。

## 报告漏洞

请不要公开披露尚未修复的安全问题。仓库公开后，优先通过 GitHub 的 private vulnerability reporting / Security Advisory 联系维护者。
