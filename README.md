# Fishbot iOS

独立安装到 iPhone / iPad 的个人助理。界面和文档解析器随 App 内置，不依赖 Windows 电脑在线，不会载入远程网页界面。

功能包括：自己的 Chat Completions API、默认 DeepSeek 预置、独立 Bot 的名称/头像/人格/职责/API、最多9位成员群聊、同时或轮流讨论、明确要求才总结、聊天/群聊删除与上下文清理、文件阅读、本机共享记忆与真实保存来源关系图、昼夜模式、备份导入导出。主管不能删除。

原生 SwiftUI + WKWebView 宿主用 URLSession 请求 API，Key 存在 iOS 钥匙串，聊天原子保存到 App 私有 Application Support。没有服务器代管 Key。浏览器模式仅用于开发验证。

## 没有 Mac 的构建和安装

1. 将本目录内容放在 GitHub 仓库根目录。仓库中的 `.github/workflows/build-ios.yml` 可在 Actions 手动运行，或通过 `codex/ios-mobile` / `main` 分支上的代码提交触发。
2. 构建会先运行核心测试，再用 macOS runner 编译、启动 iPhone 模拟器截图，最后构建真机 ARM64 App。
3. 在成功运行的 Artifacts 下载 `Fishbot-iOS-personal-signing`，解压取得 `Fishbot-unsigned.ipa`。
4. Windows 上使用官方 [Sideloadly](https://sideloadly.io/) 给自己的 iPhone 签名安装。Apple 账号只在你自己的安装工具中登录，不放入仓库、工作流或 Fishbot。
5. 免费 Apple 账号签名通常有效7天，需要定期续签。使用同一账号与相同 bundle ID 覆盖安装，先导出备份更稳妥。

**未签名 IPA 不能直接点击安装。** 构建成功不等于已经在你的 iPhone 真机验证；请以真实构建日志、模拟器截图和安装结果为准。

GitHub 公开仓库的标准 runner 可免费使用；私有仓库受账户免费额度与超额计费规则约束。本工作流使用标准 `macos-15`，不使用付费大型 runner，不上传 Apple 签名证书。构建超时20分钟，产物保留3天。聊天 API 按你选定服务商的规则计费，群聊每位成员/每轮分别调用。

## 用 Mac 本地构建（可选）

安装 Xcode 后，运行 `python3 scripts/prepare-ios.py`，打开 `ios/Fishbot.xcodeproj`，选择自己的 Team 和 iPhone，运行。也可执行 `bash scripts/build-ios.sh` 生成供个人签名的未签名 IPA。最低部署目标 iOS 16.4；旧版本 PDF 等解析兼容性需真机验证。

## 文件和记忆的边界

- 支持文本/Markdown/CSV/代码、带可复制文字的 PDF、DOCX、XLSX、PPTX。旧 DOC/XLS、加密文件、扫描 PDF 请转换格式。每条最多5个文件、单文件20MB；文字每文件最多32000字，总上下文预算60000字，超长会标记部分内容。
- PNG/JPG/WebP 等图片在手机缩小后交给当前配置的模型，需要模型支持图片。没有调用 Windows OCR，也不声称已识别图片文字。
- 本机共享记忆需要你明确保存，或发送 `记住：…`。关系图仅连到实际保存来源，不猜测语义关系。
- Windows 桌面观察、鼠标键盘控制、MCP 插件部署和内置 Hindsight 的 Python/PostgreSQL 服务不在 iOS 内运行。本版本手机记忆独立于 Windows 数据。
- Key 不随聊天备份导出。更换 API 服务地址时需填写对应 Key；同一部手机更新通常保留本机记录，卸载重装前请备份。

## 验证与依赖

`node --test tests/*.test.cjs` 验证核心逻辑；WebKit 测试脚本是 `tests/webkit-check.cjs`（需自行安装 Playwright 和 WebKit；本地验证工具不在交付包）。`scripts/prepare-ios.py` 会同步 `dist` 到 Xcode 资源并重新生成稳定工程。CI 首次构建按固定完整性摘要获取 PDF.js 文件并随 App 打包，App 运行时不访问 CDN。

开源依赖和许可见 `THIRD_PARTY_NOTICES.md`、`DEPENDENCIES.json` 与 `VENDOR.json`。验证状态见 `VALIDATION.md`。

官方说明：[Apple 免费个人开发账号](https://developer.apple.com/help/account/basics/about-your-developer-account/)、[Sideloadly FAQ](https://sideloadly.io/faq)、[GitHub Actions 计费](https://docs.github.com/en/actions/concepts/billing-and-usage)。
