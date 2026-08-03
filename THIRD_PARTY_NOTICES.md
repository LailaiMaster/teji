# 第三方组件说明

## TeslaMate

特迹是独立的非官方兼容工具，不包含 TeslaMate 源码或容器镜像。TeslaMate 由其项目维护者依据自己的许可证与商标政策发布：

- https://github.com/teslamate-org/teslamate
- https://github.com/teslamate-org/teslamate/blob/main/TRADEMARK.md

## 高德 Flutter 插件

`app/third_party/amap_flutter_base` 与 `app/third_party/amap_flutter_map` 包含当前 Android 地图适配使用的插件源码。其目录内保留了原始 `LICENSE`、README 和版权声明，采用 BSD 3-Clause 风格许可证。

高德地图 SDK、服务与 API Key 的使用还受高德开放平台条款约束。使用者需要自行申请 Key 并确认自己的使用方式符合相关条款；仓库不提供或分发 API Key。

## Flutter/Dart 与 Python 依赖

其余依赖通过 `app/pubspec.lock` 与 `api/requirements.txt` 固定或声明，版权和许可归各自项目所有。构建或再分发二进制文件时，应根据目标分发渠道生成并附带完整的第三方许可证清单。
