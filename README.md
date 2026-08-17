# FaxFlow

iPhone 与 iPad 上的现代传真应用，使用 SwiftUI、VisionKit、PDFKit 与 StoreKit 2 构建。

## 运行

1. 安装 [XcodeGen](https://github.com/yonaskolb/XcodeGen)：`brew install xcodegen`
2. 在仓库根目录生成工程：`xcodegen generate`
3. 打开 `FaxFlow.xcodeproj`，选择 iOS 17+ 模拟器或真机运行

最低部署版本：iOS 17.0。多语言：英语、简体中文、繁体中文、日语、韩语。支持系统浅色 / 深色模式。

## 目录

| 路径 | 说明 |
| --- | --- |
| `Sources/` | 应用入口、功能页、服务层 |
| `Resources/` | 资源与 String Catalog |
| `Supporting Files/` | Info.plist |
| `Docs/` | 需求、架构、模块与进度文档 |
| `Metadata/` | App Store / 内购元数据模板 |
| `PrivacyDocs/` | 隐私政策与用户协议页面（可部署到独立仓库的 GitHub Pages） |
| `project.yml` | XcodeGen 工程定义 |

更完整的说明见 [Docs/README.md](Docs/README.md)。架构见 [Docs/ARCHITECTURE.md](Docs/ARCHITECTURE.md)。
