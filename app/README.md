# 特迹 Android 客户端

特迹的 Flutter Android 客户端，用于查看自托管的特迹 API 数据。

## 结构

- `lib/src/pages/`：概览、行程、充电、日历、报告和洞察页面。
- `lib/src/widgets/`：面板、地图、车辆选择器等复用组件。
- `lib/src/utils/`：里程、路线、电池与日历统计。
- `lib/src/theme/`：颜色、字体和共用视觉常量。
- `third_party/`：带本地 Android 适配的高德 Flutter 插件。

## 本地运行

```bash
flutter pub get
flutter run
```

默认不包含任何作者部署地址。首次打开后在“配置数据服务”中填写自己的 API 地址，或在运行/构建时传入：

```bash
flutter run --dart-define=TEJI_API_BASE_URL=http://192.168.1.100:8889
```

如需路线地图，在 `android/key.properties` 中加入自己的高德 Key。该文件已被 Git 忽略：

```properties
amapApiKey=your-amap-key
```

发布构建还可以在同一文件中配置 Android 签名字段；不要把它提交到仓库。

## 检查

```bash
flutter analyze
flutter test
flutter build apk --debug
```

增加页面时优先创建聚焦的 page/widget 文件。共享统计逻辑应放在 `utils/`，避免列表页与首页出现不同口径。
