# 快件运营人备案管理 iOS 版

基于 SwiftUI 的原生 iOS 应用，功能与 Android 版对等，支持 iOS 16.0+。

## 功能

- 企业档案管理（新增/编辑/删除/搜索/分页）
- 备案流程时间轴（6 类节点，4 类可多次添加记录）
- 9 种备案状态管理
- 修改历史审计
- 数据统计（状态分布饼图、月度趋势折线图、平均打回次数/处理时长）
- 数据导出（Excel/CSV、Word/HTML）
- 数据备份与恢复
- PIN 应用锁
- 数据清理（过期已完成/终止档案）

## 技术栈

- SwiftUI + iOS 16+
- SQLite3 原生数据库（无第三方依赖）
- Swift Charts（系统内置）
- XcodeGen 生成 Xcode 工程

## 本地构建

```bash
brew install xcodegen
xcodegen generate
open FilingApp.xcodeproj
# 在 Xcode 中选择模拟器或设备，点击运行
```

## 云构建（GitHub Actions）

推送代码到 `main` 分支即自动触发构建，产出未签名 IPA。

构建产物在 Actions → 最新 run → Artifacts → `FilingApp-unsigned-ipa` 下载。

## 安装到真机

未签名 IPA 无法直接安装，需要用以下工具自签名：

1. **Sideloadly**（推荐，Windows/Mac 均支持）：https://sideloadly.io
   - 打开 Sideloadly，拖入 IPA
   - 输入你的 Apple ID（免费账号即可，7 天有效期）
   - 点击 Start，完成后手机设置 → 通用 → VPN与设备管理 → 信任开发者

2. **AltStore**：https://altstore.io

3. 如有 Apple 开发者账号（$99/年），可在 Xcode 中配置证书后直接打包签名 IPA。

## 导出格式说明

- Excel 导出为 `.csv`（Excel/WPS 可直接打开，支持中文）
- Word 导出为 `.doc`（HTML 格式，Word/WPS 可直接打开）

## 项目结构

```
Sources/
├── FilingApp.swift          # App 入口
├── Models/                  # 数据模型
├── Database/                # SQLite 封装 + DAO
├── Views/                   # SwiftUI 页面
├── Services/                # 导出、备份服务
└── Utils/                   # 工具类
```
