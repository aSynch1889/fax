# FaxFlow 项目深度问题分析与解决方案

**日期：** 2026-08-19  
**范围：** 全仓库（架构、业务、内购、合规、工程、产品需求落差）  
**原则：** 只诊断与给方案，本文不包含实现代码。  
**结论先说：** 当前工程是一套完成度很高的 **UI + 本地状态机演示**，尚不能作为真实传真产品上架。最大风险集中在：传真网关缺失、内购可被绕过、`SCREENSHOT_MODE` 打进全量构建、隐私/订阅合规、以及文档声称已完成但代码未实现的能力。

---

## 1. 项目画像

FaxFlow 是对标 BPMobile《FAX from iPhone & iPad》的 SwiftUI 复刻：扫描/导入图片 → 编辑页 → 封面页 → 模拟发送 → 历史回执 → StoreKit 2 订阅/页数包。

文档（`Docs/ARCHITECTURE.md`、`Docs/MODULES.md`、`Docs/STATUS.md`）把各模块标为 Completed，并将 Simulator 编译通过视为阶段完成。这对「脚手架阶段」成立，但对「可上架产品」不成立。

实际结构是：

```
SwiftUI View（大量业务写在 View 内）
        ↓
单例 Service（StoreManager / FaxTransmissionService / StorageManager）
        ↓
Application Support JSON + JPEG + UserDefaults
```

没有 ViewModel 层，没有网关客户端，没有测试，没有 StoreKit Configuration。

---

## 2. 问题总表（按严重度）

| 级别 | 数量 | 含义 |
| :--- | :--- | :--- |
| P0 | 8 | 上架/资金/法律/核心承诺不成立 |
| P1 | 14 | 功能残缺、数据丢失、架构债，上线前必须修 |
| P2 | 12 | 体验、可维护性、本地化细节 |

---

## 3. P0：必须先解决

### 3.1 没有真实传真发送，但产品以「发传真」售卖

**现状**

- `FaxTransmissionService.transmitFax` 只生成本地 PDF，然后用 `Task.sleep` 走 Queued → Dialing → Transmitting → Delivered。
- PDF 被赋值后立刻丢弃（`_ = pdfData`），注释写「生产环境再交给网关」。
- 永远返回 `true`，没有失败路径、取消路径、重试、后台续传。
- 积分在发送**开始前**扣除；订阅用户则完全不扣。

**风险**

- 用户付费后得到的是动画，不是投递。App Review 与消费者保护都过不去。
- 文档 `TRANSMISSION_ENGINE.md` 写了「Establish carrier line / Stream page chunks」，代码没有对应实现，后续 AI/人工会误判为已完成。

**方案**

1. 明确产品形态，二选一写进 `REQUIREMENTS.md`：
   - **A. 真实传真：** 接入合规网关（如 Phaxio / Sinch Fax / Twilio Fax / 自建 PSTN 网关），客户端只上传 PDF + 目的号码，服务端负责投递、回执、失败码。
   - **B. 文档工具：** 产品改名为扫描/PDF/电子签名工具，去掉「发送传真」付费点，否则属于虚假功能。
2. 若选 A：
   - 定义传输协议：创建任务 → 上传 → 轮询/Webhook → 终态。
   - 状态机必须以服务端状态为准，客户端动画只是展示。
   - 失败必须可映射到 `TransmissionStatus.failed`，并退还积分或标记「未消耗」。
   - 回执 PDF 必须来自网关确认（页数、时长、对方应答），不能本地随机 `FAX-XXXXXX`。
3. 在接入网关前，Paywall 与 Send 按钮应标为「演示」或直接关闭付费路径，避免审核账号买到空功能。

---

### 3.2 积分在发送前扣除，且无回滚

**现状**

`deductCredits` 成功后才开始模拟；进程被杀、睡眠失败、PDF 生成失败都不会退款。历史记录会停在 `queued/dialing/transmitting`，Outbox 永远卡住。

**方案**

- 采用「预留 → 确认消耗 → 失败释放」三阶段：
  1. 创建本地任务，状态 `queued`，积分记为 `reserved`，不减可用余额展示或单独记账。
  2. 网关确认 Accepted 后再 `commit`。
  3. 失败 / 用户取消 / 超时 → `release`。
- 启动时扫描未终态任务：向服务端对账；无网关时至少把超过 N 分钟的任务标 `failed` 并退积分。
- 订阅用户的「无限」也要有服务端配额或公平使用策略，不能仅靠本地 Bool。

---

### 3.3 内购可被免费领取（资金漏洞）

**现状（`PaywallView`）**

- 商品列表加载失败或为空时：
  - 订阅 CTA 直接 `setSubscriptionActive(true)` 并关闭付费墙。
  - 积分包按钮直接 `addCredits(10/50/100)`。
- 注释写的是「截图 / sandbox fallback」，但判断条件是「`store.products` 里找不到对应 ID」，**生产环境无网、ASC 商品未就绪、地区不可用都会走这条路**。

**方案**

- 生产构建禁止任何本地授予权益。
- 商品未加载：展示错误 + 重试，禁止购买按钮生效。
- 截图模式用独立编译条件 + 独立 UI 数据层，且不得写入真实 `UserDefaults` 权益键。
- 购买结果要驱动 UI：`purchaseError` 目前已写入却从未展示。

---

### 3.4 `SCREENSHOT_MODE` 被写进所有编译配置

**现状**

`project.yml`：

```text
SWIFT_ACTIVE_COMPILATION_CONDITIONS: "$(inherited) SCREENSHOT_MODE"
```

这会进入 Debug **和** Release。后果：

- 空库自动写入英文假联系人、假历史，并 **persist 到磁盘**。
- 与 3.3 的 fallback 叠加后，审核员/真实用户会看到伪造「已成功发送」记录。

**方案**

- 默认配置去掉该宏。
- 仅在 `Debug` + 独立 Scheme（如 `FaxFlow-Screenshots`）开启。
- Mock 数据放内存或单独文件，退出截图 Scheme 不污染用户库。
- `STATUS.md` 中「Screenshot Mock Mode PASS」应注明「仅截图 Scheme」。

---

### 3.5 订阅与积分存在可篡改的 UserDefaults

**现状**

- `HasActiveSubscription`、`UserFaxCredits` 明文 UserDefaults。
- 越狱/调试/备份修改即可无限发。
- `StoreManager.updatePurchasedProducts` 启动时会按收据纠正订阅，但：
  - 消耗型积分 **不会** 从 Apple 对账（Apple 也不存消耗型余额）。
  - 在 `listenForTransactions` 里对消耗型只 `finish()`，不补发；主购买路径 `handleSuccessTransaction` 才加积分。若 `purchase()` 成功加了分，同时 `updates` 再走一遍，当前代码不会双加（listener 不加分）。真正的洞是 **无网授予 + UserDefaults 篡改 + 无服务端账本**。

**方案**

- 订阅：以 `Transaction.currentEntitlements` 为唯一真相，UserDefaults 只做缓存，每次冷启动覆盖。
- 积分：必须服务端账本（用户 Apple ID / appAccountToken 绑定）。客户端展示缓存，发传真前服务端扣减。
- 过渡期若必须纯客户端：Keychain + 已处理 `transaction.id` 集合，防止重复入账；仍无法防篡改，只能降低误 finish / 重复购买风险。
- 记录每个消耗型 `transaction.id`，入账成功后再 `finish()`。

---

### 3.6 订阅付费墙不满足 App Store 订阅披露

**现状**

- 价格写死 `$3.99` / `$9.99` / `$50.99`，不用 `Product.displayPrice`（地区/税务/汇率全错）。
- PRD 写 weekly 含 3 天试用，代码与元数据模板没有 StoreKit 试用展示。
- 无自动续订法律文案：时长、价格、续订时机、取消路径。
- Settings「管理」只是再打开 Paywall，不跳转 `showManageSubscriptions`。
- 隐私/条款链到 `https://bpmob.com/fax/...`（竞品域名），不是本产品独立政策。

**方案**

- UI 价格全部来自 StoreKit `displayPrice` / `subscriptionPeriod`。
- 付费墙底部固定：产品名、周期、试用、续订说明、隐私、条款（自己的 URL）。
- 「管理」调用 `AppStore.showManageSubscriptions(in:)`。
- 自建隐私仓库 + GitHub Pages（规则第 5 条），App 内只放链接。`PrivacyDocs/` 留在本仓不能代替独立站点。
- Info.plist 的相机/相册/Face ID 用途说明要进 String Catalog，覆盖 5 语。

---

### 3.7 隐私协议与产品归属错误

**现状**

- 独立公开仓库：[aSynch1889/faxflow-privacy](https://github.com/aSynch1889/faxflow-privacy)
- GitHub Pages：https://asynch1889.github.io/faxflow-privacy/ （privacy.html / terms.html）
- App 设置与付费墙已改为上述链接，不再指向 `bpmob.com`。
- 政策已说明：本地存储、发送时传给网关、IAP 由 Apple 处理、Face ID 留在设备。
- 若内容上传生产网关，仍须更新 App Privacy 问卷（照片、敏感文档）。

---

### 3.8 文档与代码严重不符，会误导后续开发

**现状**

| 文档声称 | 代码实际 |
| :--- | :--- |
| MVVM + SOA | View 内直接调单例，无 VM |
| 真实/完整 StoreKit | 无商品则白送权益；无 `.storekit` |
| REQ-SCAN-03 导入 PDF | 未实现 |
| REQ-EDIT-01 页重排 | 未实现 |
| REQ-SIGN-03 签名可拖拽缩放 | 固定画在 `(200, 350)` |
| Face ID 锁 App | 开关只写 UserDefaults，`AppState.isUnlocked` 恒为 `true` |
| 专属传真号 | 写死 `+1 (800) 555-FAX1` |
| 加密校验徽章 | 随机确认码 + 本地绿章 |
| 5 语 100% | 国家名、默认标题 `Untitled Fax`、假数据仍是英文 |
| SCREENSHOT_MODE 便于截图 | 全配置常开并落盘 |

**方案**

- 以本文为基准改 `STATUS.md`：P0/P1 打开，模块状态改为 Partial / Stub。
- `ARCHITECTURE.md` 改成「当前：单例 + View；目标：VM + 网关」。
- 后续评审以代码为准，文档 Completed 必须对应可验证验收项。

---

## 4. P1：上线前必须补齐

### 4.1 发送页文档是一次性内存对象，图片会成孤儿

`SendFaxView.currentDocument` 不写入 `StorageManager.documents`。扫描/相册图会存 JPEG，发送后表单不清空，用户删页也不一定走文档库删除。Documents Tab 与 Send Tab 是两套文档世界。

**方案**

- 统一「草稿文档」模型：进入发送页即创建/恢复 draft，所有页写入同一 `FaxDocument` 并 persist。
- 发送成功：归档或删除草稿并清理未引用 JPEG。
- 启动时 GC：扫描 `PageImages/`，删除不被任何文档引用的文件。

---

### 4.2 回执 PDF 写在 tmp，文件名却记进历史

`transmitFax` 把回执写到 `temporaryDirectory`，只存 `receiptPDFFileName`。系统清 tmp 后文件消失。详情页则是 **重新生成** 回执，不读当时文件——「官方回执」没有不可篡改性。

**方案**

- 回执落到 Application Support（或网关 URL）。
- 终态后回执内容冻结（网关原始 JSON + 渲染 PDF）。
- QuickLook 只打开已落盘文件。

---

### 4.3 需求缺口（扫描 / 编辑 / 签名）

1. **PDF 导入（REQ-SCAN-03）**  
   用 `fileImporter` / `UIDocumentPicker` 选 PDF，PDFKit 栅格化每页再入库。注意大文件分页与内存。

2. **页重排（REQ-EDIT-01）**  
   缩略图条支持 `onMove` 或拖拽。

3. **签名交互（REQ-SIGN-03）**  
   `PageDetailCard` 里签名 `position` 写死，和 `SignaturePlacement` 的相对坐标无关。应按 `relativeX/Y/Width` 布局，并支持拖移、捏合。深色模式下签名画布是白底（合理），但预览坐标必须与 PDF 导出同一套坐标系（PDFGenerator 已用相对坐标，UI 没用）。

4. **号码校验**  
   `canSend` 只判断非空。应使用 `PhoneFormatter` + 国家 mask，非法号码禁止发送。

5. **封面页字段**  
   `recipientCompany` 建模了，PDF 封面未绘制。发送页改号码不会回写封面收件人。

---

### 4.4 Face ID 是死开关

`SettingsView` 引入了 `LocalAuthentication` 却未调用。`AppState.isUnlocked` 无读取处。Info.plist 已有 Face ID 用途说明——审核可能问「你申请了但没用」。

**方案**

- 实现：冷启动 / 回前台若开启则盖锁界面，`LAContext.evaluatePolicy` 成功后解锁。
- 失败有密码回退；无生物识别设备隐藏开关。
- 未实现前不要申请 Face ID 权限文案。

---

### 4.5 架构：单例泛滥 + 双重 `@StateObject`

- `FaxApp` 与 `MainTabView` 各自 `@StateObject` 包一层 `StorageManager.shared` / `StoreManager.shared`。
- 子页面又 `@ObservedObject var storage = StorageManager.shared`。
- SwiftUI 生命周期与单例混用，预览、测试、多窗口（iPad 以后开多 Scene）会出双源。

**方案**

- App 入口注入一次，全程 `environmentObject`。
- Service 改为协议 + 可替换实现（Live / Mock），去掉 View 内 `shared`。
- 按功能拆 ViewModel：`SendFaxViewModel`、`PaywallViewModel`、`HistoryViewModel`。
- `NavigationView` 全部换 `NavigationStack`（iOS 17）。

---

### 4.6 持久化全部 `try?`，损坏即静默空数据

JSON 读失败直接 `return`，用户看到空列表，原文件还在但可能已在下次 save 被空数组覆盖（取决于调用顺序）。目前 load 失败不会写回，相对安全；但 `persist*` 编码失败也会静默丢本次修改。

**方案**

- 编解码错误打日志 + 用户可见告警。
- 写盘用临时文件 + replace；保留 `.bak`。
- 模型加 `schemaVersion`，禁止无版本 Codable。
- 默认标题 `"Untitled Fax"` 改为本地化 key。

---

### 4.7 敏感文档无加密

传真场景常是医疗/法律。JPEG、签名 PNG、联系人明文躺在 Application Support。iOS 备份可被导出。

**方案**

- 至少开启 Data Protection Complete。
- 签名与页图考虑 File Protection + 可选用户密码/生物识别解锁后再解密。
- 政策中写明本地存储与备份行为。

---

### 4.8 StoreKit 工程不完整

- 无 `Products.storekit`，模拟器无法完整测购买。
- 无 `appAccountToken`。
- `purchase()` 的 `.pending`（家长同意）当失败，用户扣款后可能不入账。
- 订阅购买成功只 `insert` 当前 ID，未立刻 `updatePurchasedProducts`（一般没问题，但降级/升级依赖 listener）。
- `deinit` 里 cancel task：单例几乎不释放，问题不大。
- Paywall 不用 `store.products` 渲染套餐，商品顺序/本地化全浪费。

**方案**

- 增加 StoreKit Configuration，挂到 Screenshot/Debug Scheme。
- Paywall 完全由 `Product` 驱动。
- 处理 `.pending`：提示等待，listener 入账。
- 元数据补 introductory offer，与 ASC 一致。

---

### 4.9 无测试、无 CI、无失败即停的质量门

规则要求 Simulator Debug 能编过。仓库无 Unit Test / UI Test target，`project.yml` 无 schemes、无 DEVELOPMENT_TEAM。

**方案**

- XcodeGen 增加 `FaxFlowTests`：积分预留/回滚、页数计算、电话格式、Store 入账幂等（用 mock）。
- UI 测试只跑截图 Scheme。
- CI：`xcodegen generate && xcodebuild test`。
- 工程文件只通过 XcodeGen 生成，避免再手改 `pbxproj`（当前 git status 已手改）。

---

### 4.10 iPad / 导航 / 无障碍

- 支持 iPhone+iPad，但全是 `NavigationView` 堆叠，iPad 浪费横向空间。
- 编辑器签名坐标按 iPhone 估的绝对点。
- 动态字体、VoiceOver、Reduce Motion 未考虑。
- 发送中不可取消，也无后台任务（杀进程即卡 Outbox）。

**方案**

- iPad 用 `NavigationSplitView`：列表 + 详情。
- 签名只使用相对坐标。
- 发送改为可取消的协作任务；真正发送必须后台 URLSession。

---

### 4.11 空的 Scanner 目录与死代码依赖

- `Sources/Features/Scanner/` 为空。
- `SendFaxView` import PDFKit 未用。
- Settings import LocalAuthentication 未用。
- `project.yml` 链了 WebKit、AVFoundation 等，代码未见使用。
- `PhoneFormatter`、`AppState.isUnlocked` 未接入主路径。

**方案**

- 删空目录或落地扫描功能入口。
- 按真实 import 收敛 frameworks，减少审核对敏感 API 的追问。

---

### 4.12 历史详情对进行中记录展示错误

`TransmissionDetailView` 非 `delivered` 一律红三角，Outbox 中的 queued 会被画成失败。

**方案**

- 三态 UI：进行中 / 成功 / 失败。
- 详情应观察 `storage.historyRecords` 中的最新 record，不要传值拷贝导致进度不刷新。

---

### 4.13 URL Identifiable 的 `@retroactive` 扩展

```swift
extension URL: @retroactive Identifiable
```

污染全局 URL，且 `absoluteString` 作 id 在 query 变化时不稳。

**方案**

- 包一层 `struct PreviewItem: Identifiable { let id: UUID; let url: URL }`。

---

### 4.14 专属号码与「无限发送」文案

设置里展示假号码，订阅文案像运营商产品。没有 DID 采购与入站传真。

**方案**

- 未采购号码前删除该行。
- 订阅文案改为「应用内功能无限」，不要暗示分配真实传真号。

---

## 5. P2：体验与工程卫生

1. **国家名仅英文**（已在 STATUS 记录）——用 `Locale.current.localizedString(forRegionCode:)`。
2. **签名空白仍可保存**——`renderSignature` 空图也会 `onSave`。
3. **相册多选后不清预览状态以外的失败**——单张 decode 失败静默跳过。
4. **过滤器默认 `enhancedDoc`**，用户可能以为原图被改，应默认 original 或首次提示。
5. **封面模板四种差异很小**，Urgent 以外几乎只是标题不同。
6. **硬编码版本号** `1.0.0 (Build 1)`，应读 `Bundle.main`。
7. **Info.plist `armv7`** 过时，iOS 17 应为 `arm64`。
8. **`presentationMode` 过时**，改用 `dismiss`。
9. **颜色** `AppTheme.accent` 写死 RGB，深色下仍是亮蓝，建议 Asset Catalog 双色。
10. **`ENABLE_USER_SCRIPT_SANDBOXING: NO`** 无脚本却关闭沙箱，改回 YES。
11. **无障碍与动态字体** 未验收。
12. **假数据英文** 在截图模式也会进中文截图。

---

## 6. 合规与审核清单（上架视角）

| 条款/点 | 当前 | 动作 |
| :--- | :--- | :--- |
| 功能与描述一致 | 描述发传真，实际 sleep | 接网关或改定位 |
| 3.1.1 / 3.1.2 订阅披露 | 硬编码价格、无续订说明 | StoreKit 驱动 + 法律文案 |
| 隐私政策可访问且匹配开发者 | 链到 bpmob.com | 自有 Pages |
| 权限用途 | 仅英文 plist；Face ID 未用 | 本地化；实现或删除 |
| 截图真实性 | SCREENSHOT_MODE 常开 + 假历史 | 独立 Scheme；截图勿伪装运营商回执 |
| 恢复购买 | 有入口 | 保留；失败要 toast |
| 账户删除 | 无账号体系 | 若以后做登录需 5.1.1(v) |

---

## 7. 推荐落地顺序（仍不写代码）

### 阶段 0 — 诚实化（1 天）

- 关掉 Release 的 `SCREENSHOT_MODE`。
- 去掉 Paywall 免费授予。
- 修正 STATUS / MODULES：Transmission / IAP / Face ID / PDF Import 标为 Stub 或 Partial。
- 法律链接改占位「待部署的自有 URL」，去掉竞品域名。

### 阶段 1 — 产品决策（必须先拍板）

- 是否接真实传真网关？预算、地区（中/日/韩/美号码合规差异很大）、是否需要入站 DID。
- 若暂不接网关：App 定义为文档工具，发送改为「导出 PDF / 分享」，付费点改为去水印或高级扫描，而不是「每页传真费」。

### 阶段 2 — 内购与账本

- StoreKit Configuration + Product 驱动 Paywall。
- 订阅以 entitlements 为准。
- 积分服务端化；或明确「仅演示」不上架。

### 阶段 3 — 传输与数据

- 网关 API、对账、回执落盘、积分预留。
- 草稿文档统一、孤儿文件 GC、JSON 版本与错误可见。

### 阶段 4 — 需求补齐

- PDF 导入、页重排、签名拖拽、号码校验、Face ID、iPad 分栏。

### 阶段 5 — 工程化

- 测试 target、CI、仅 XcodeGen 出工程、权限字符串 5 语、隐私仓库上线。

---

## 8. 模块健康度（相对 MODULES.md 的修正）

| 模块 | 文档状态 | 建议状态 | 一句话 |
| :--- | :--- | :--- | :--- |
| App.Lifecycle / Navigation | Completed | Partial | 双 StateObject；无锁机 |
| Core.Storage | Completed | Partial | 静默 IO；权益在 UserDefaults；截图污染 |
| Core.PDF | Completed | Partial | 能出 PDF；回执非官方 |
| Service.StoreKit | Completed | High risk | 可白送；价格写死 |
| Service.Transmission | Completed | Stub | 纯动画 |
| Service.Scanner | Completed | Partial | 仅 VisionKit；无 PDF；模拟器失败无提示 |
| Feature.SendFax | Completed | Partial | 草稿不持久；无校验 |
| Feature.DocEditor | Completed | Partial | 无重排；签名坐标错误 |
| Feature.Paywall | Completed | High risk | 见 P0 |
| Feature.Settings | Completed | Partial | Face ID / 假号码 / 错链 |
| Feature.History | Completed | Partial | tmp 回执；进行中 UI 当失败 |
| Resources.Localization | Completed | Partial | 模型默认值与国家名未本地化 |

---

## 9. 不在本次范围

- 未跑 Simulator 实机点选（静态阅读代码与文档）。
- 未验证 ASC 后台是否已创建商品。
- 未评估具体网关供应商报价与号码合规细节（需产品拍板后再做技术选型文档）。

---

## 10. 总结

FaxFlow 作为 **SwiftUI 复刻脚手架** 是成功的：目录规范、XcodeGen、五语 Catalog、扫描/封面/历史 UI、StoreKit 骨架都在。

作为 **可上架传真 App** 还不成立。优先切断「假发送 + 假内购 + 假回执 + 竞品隐私链接」，再决定网关或改产品定义。在此之前不要把 `STATUS.md` 的 PASS 当作可提交 App Store 的依据。
