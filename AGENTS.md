# APP 复刻流水线 - 反重力强制规则（必须严格遵守）

## 1. 总原则

- 必须使用 XcodeGen 生成工程，禁止直接生成混乱的 `.xcodeproj`。
- 先建标准目录 → 写 `project.yml` → 执行 `xcodegen generate`。
- 生成的工程必须能成功编译（至少 Simulator Debug）。
- 所有固定模块必须一次性注入，不允许后期再补。

## 2. 标准目录结构（强制）

项目根目录必须包含：

```
project.yml
Sources/
Resources/
Supporting Files/
Docs/
  README.md
  ARCHITECTURE.md
  MODULES.md
  STATUS.md
  REQUIREMENTS.md          # 阶段1产出
Metadata/                  # 后期生成
Screenshots/               # 后期生成
  iPhone/
  iPad/
```

## 3. 多语言（强制）

必须支持以下语言：

- `en`（英语）
- `zh-Hans`（简体中文）
- `zh-Hant`（繁体中文）
- `ja`（日语）
- `ko`（韩语）

优先使用 String Catalog（`.xcstrings`）。  
所有用户可见文案必须本地化，禁止硬编码中文或英文。

## 4. 深色 / 浅色模式（强制）

- 完美支持系统深色与浅色模式。
- 使用语义颜色或 `@Environment(\.colorScheme)`。
- 禁止写死导致深色模式不可读的颜色。

## 5. 隐私协议（强制）

- 隐私政策与用户协议必须放在**独立 GitHub 仓库**，用 GitHub Pages 部署。
- App 内只放链接，不内嵌长文本。
- 生成项目时同步给出隐私仓库的基础结构和说明。

## 6. 内购模块（强制）

- 必须包含完整 StoreKit 2 封装（购买、恢复、状态监听）。
- 至少支持一种内购类型（根据原 App 决定：非消耗型 / 自动续期订阅等）。
- 同步生成内购元数据模板，方便后续上传 ASC。

## 7. 文档（强制）

必须生成并保持更新：

- `README.md`：项目说明、如何运行、模块列表
- `ARCHITECTURE.md`：架构说明
- `MODULES.md`：各固定模块状态
- `STATUS.md`：P0/P1 问题与整体进度（格式见标准模板）

## 8. 技术要求

- 使用 SwiftUI
- 建议最低部署版本 iOS 17.0
- Bundle ID、Display Name、版本号规范
- 代码清晰、可维护，便于后续 Grok 分析和 Codex 审查
- 建议开启 `SCREENSHOT_MODE` 开关，方便自动化截图时控制界面状态

## 9. 编译验证

生成完成后必须验证：

```bash
xcodegen generate
xcodebuild -scheme APP_NAME -destination 'platform=iOS Simulator,name=iPhone 16' build
```

编译失败则视为本阶段未完成，不得进入后续分析阶段。
