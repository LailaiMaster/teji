<p align="center">
  <img src="app/assets/brand/teji_icon_1024.png" width="128" alt="特迹图标">
</p>

<h1 align="center">特迹（Teji）</h1>

<p align="center">
  面向 TeslaMate 的开源、自托管 Android 车辆数据看板
</p>

<p align="center">
  <a href="LICENSE"><img src="https://img.shields.io/badge/license-AGPL--3.0-blue.svg" alt="AGPL-3.0"></a>
  <img src="https://img.shields.io/badge/client-Flutter-54C5F8.svg" alt="Flutter">
  <img src="https://img.shields.io/badge/API-FastAPI-009688.svg" alt="FastAPI">
  <img src="https://img.shields.io/badge/deployment-self--hosted-5A67D8.svg" alt="Self-hosted">
</p>

特迹把自己部署的 TeslaMate 数据整理成适合手机查看的原生界面，包括车辆状态、行程、充电、电池趋势、日历、路线和驾驶洞察。

它由一个 Flutter Android 客户端和一个只读 FastAPI 数据桥组成。特迹不连接或控制车辆，也不需要 Tesla 账号凭据；API 只查询用户自己的 TeslaMate PostgreSQL 数据库。

> [!IMPORTANT]
> API 当前没有内置身份认证，并会返回精确位置和完整行程。请只在家庭局域网、可信 VPN，或带 HTTPS 与身份认证的反向代理后使用。**不要把 API 或 PostgreSQL 端口直接暴露到公网。**

## 界面与功能

- 多车辆状态、电量、续航、温度、胎压和今日里程概览。
- 行程与充电记录，支持按车辆查看。
- 单次行程路线、速度、功率、海拔和电量变化。
- 月度行程日历、热力图和里程统计，支持切换查看历史月份。
- 电池趋势、路线对比、驾驶成就和统计报告。
- API 地址由用户配置，车辆与行程数据保留在自己的基础设施中。

## 工作方式

```text
TeslaMate ──写入──> PostgreSQL <──只读查询── 特迹 API <──HTTPS/VPN── 特迹 Android
                               FastAPI :8889
```

```text
app/                 Flutter Android 客户端
api/                 FastAPI + PostgreSQL 查询
app/third_party/     当前高德地图 Android 适配源码
```

## 准备条件

- 已正常运行并产生数据的 [TeslaMate](https://github.com/teslamate-org/teslamate)。
- Docker Compose，用于运行特迹 API。
- Flutter 3.29+ / Dart 3.8+，用于开发或构建 Android 客户端。
- 如需显示路线地图，需要自行申请高德 Android API Key。

## 使用 Codex 部署 Skill

仓库附带公开的 [`teji-deploy`](skills/teji-deploy/SKILL.md) Skill，可帮助 Codex 检查 TeslaMate/Docker 环境、选择安全的局域网或 VPN 访问方式、部署特迹 API、配置 Android 客户端并排查常见问题。

```bash
cp -R skills/teji-deploy ~/.codex/skills/
```

安装后可以这样调用：

```text
使用 $teji-deploy 帮我把特迹部署到现有的 TeslaMate NAS 上。
```

Skill 不包含任何 NAS 地址、密码或车辆数据，执行时也会避免输出配置中的敏感值。

## 快速开始

### 1. 获取代码

```bash
git clone https://github.com/LailaiMaster/teji.git
cd teji
```

### 2. 配置并启动 API

```bash
cp api/.env.example api/.env
```

编辑 `api/.env`：

```dotenv
TESLAMATE_DB_HOST=teslamate-database-1
TESLAMATE_DB_PORT=5432
TESLAMATE_DB_NAME=teslamate
TESLAMATE_DB_USER=teslamate
TESLAMATE_DB_PASSWORD=replace-with-your-password
TESLAMATE_DB_SSLMODE=disable
CORS_ALLOW_ORIGINS=*
```

默认 Compose 配置会把 API 加入现有的 `teslamate_default` Docker 网络。如果你的 TeslaMate 网络或数据库容器名称不同，请相应修改 `api/docker-compose.yml` 与 `.env`。

```bash
docker compose -f api/docker-compose.yml up -d --build
curl http://127.0.0.1:8889/health
```

健康检查返回 `{"ok": true, ...}` 即表示 API 已连接数据库。完整说明见 [API 文档](api/README.md)。

### 3. 建议使用只读数据库账号

示例 SQL 如下，请根据自己的 PostgreSQL 管理方式执行并使用强密码：

```sql
CREATE USER teji_reader WITH PASSWORD 'replace-with-a-strong-password';
GRANT CONNECT ON DATABASE teslamate TO teji_reader;
GRANT USAGE ON SCHEMA public TO teji_reader;
GRANT SELECT ON ALL TABLES IN SCHEMA public TO teji_reader;
ALTER DEFAULT PRIVILEGES IN SCHEMA public
  GRANT SELECT ON TABLES TO teji_reader;
```

然后把 `.env` 中的用户和密码切换为 `teji_reader`。不要把 `.env` 提交到 Git。

### 4. 配置 Android 地图

在高德开放平台创建 Android Key 时，应用包名填写：

```text
com.lailaima.teji
```

把 Key 写入未纳入版本控制的 `app/android/key.properties`：

```properties
amapApiKey=your-amap-key
```

高德还会校验签名证书 SHA-1。Debug 与 Release 使用不同证书时，需要分别创建匹配的 Key。仓库不会提供或收集高德 Key。

### 5. 运行客户端

```bash
cd app
flutter pub get
flutter run
```

首次打开后，点击“配置数据服务”，填写手机能够访问的 API 地址，例如：

```text
http://192.168.1.100:8889
```

也可以在运行或构建时预置地址：

```bash
flutter run --dart-define=TEJI_API_BASE_URL=http://192.168.1.100:8889
```

Android 模拟器访问宿主机时通常使用 `http://10.0.2.2:8889`；真机需要使用局域网/VPN 中可达的地址。

## API

| 方法 | 路径 | 用途 |
|---|---|---|
| GET | `/health` | 数据库连接健康检查 |
| GET | `/api/cars` | 车辆列表 |
| GET | `/api/overview` | 车辆状态与今日概览 |
| GET | `/api/drives` | 已完成行程列表 |
| GET | `/api/drives/{drive_id}` | 行程详情与抽样路线点 |
| GET | `/api/charging-processes` | 已完成充电记录 |

列表接口支持 `car_id` 和 `limit` 查询参数，`limit` 范围为 1–200。

## 开发与验证

```bash
cd app
dart format --output=none --set-exit-if-changed lib test
flutter analyze
flutter test
flutter build apk --debug
```

FastAPI 入口位于 `api/app/main.py`。提交涉及数据库查询的改动时，请使用脱敏或虚构数据验证，不要上传真实位置响应。

## 已知限制

- 当前仅包含 Android 客户端。
- 地图实现使用高德 SDK，更适合中国大陆环境。
- API 没有内置认证，公网部署必须自行增加可靠的认证层。
- 数据库时间目前按 `Asia/Shanghai` 转换，其他时区尚未配置化。
- 不同 TeslaMate 版本的数据库结构可能变化；遇到兼容问题请附版本号和脱敏错误信息。

## 隐私与安全

TeslaMate 数据可能暴露家庭/工作地址、实时车辆位置和长期活动规律。提交 Issue、截图或日志前，请删除：

- 车辆名称、VIN 和账号信息；
- 经纬度、地图、起终点和围栏名称；
- 私有域名、IP、Token、Cookie、数据库连接信息；
- 高德 Key、Android 签名文件和证书信息。

详细建议见 [SECURITY.md](SECURITY.md)。

## 非官方项目声明

This project is an unofficial community tool and is not affiliated with, endorsed by, or supported by the official TeslaMate project.

Tesla、TeslaMate 及其他名称和标志归各自权利人所有。本项目不使用其官方标志，也不代表获得 Tesla, Inc. 或 TeslaMate 项目的认可。“compatible with TeslaMate”仅用于说明技术兼容性。

## 参与贡献

欢迎提交 Issue 和 Pull Request：

1. Fork 仓库并从 `main` 创建功能分支。
2. 保持页面、Widget 和统计逻辑职责清晰。
3. 运行格式、静态分析和测试。
4. 确保提交内容不含任何真实车辆或部署隐私。
5. 在 PR 中说明影响的 TeslaMate 版本和验证方式。

首次公开与发布二进制文件前，还应检查 [开源发布清单](OPEN_SOURCE_CHECKLIST.md) 和 [第三方组件说明](THIRD_PARTY_NOTICES.md)。

## 开源许可证

除 `app/third_party/` 中保留各自许可证的第三方组件外，特迹源码采用 [GNU Affero General Public License v3.0](LICENSE) 发布。

你可以使用、研究、修改和再分发本项目；如果分发修改版本，或通过网络向用户提供修改后的程序功能，需要按照 AGPLv3 向相应用户提供完整对应源码，并保留版权与许可证声明。具体权利和义务以 `LICENSE` 原文为准。
