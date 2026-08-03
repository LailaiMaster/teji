# 特迹 API

只读 FastAPI 数据桥，为特迹 Android 客户端查询用户自己的 TeslaMate PostgreSQL 数据。默认监听 `8889`。

## 安全边界

API 当前没有内置身份认证，返回内容包含位置与行程信息。请只在局域网、可信 VPN，或带 HTTPS 和身份认证的反向代理后使用。不要直接将端口暴露到公网。

## 部署

```bash
cp .env.example .env
# 编辑 .env，填写数据库连接信息
docker compose up -d --build
```

建议为 API 创建只允许读取所需 TeslaMate 表的数据库用户。默认 Compose 会把服务加入现有的 `teslamate_default` Docker 网络；如果你的网络名不同，请相应修改。

## 健康检查

```bash
curl http://127.0.0.1:8889/health
```

## 接口

- `GET /health`
- `GET /api/cars`
- `GET /api/overview`
- `GET /api/drives?car_id=2&limit=50`
- `GET /api/drives/{drive_id}`
- `GET /api/charging-processes?car_id=2&limit=50`

所有查询均为读取操作，时间字段转换为 `Asia/Shanghai`。如需支持其他时区，应先把时区改为显式配置，而不是直接修改客户端时间。
