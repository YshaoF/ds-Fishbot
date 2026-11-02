# Windows 安装 Fishbot 到 iPhone

本说明适用于你自己的 App 和 iPhone。Mac 只在 GitHub 云端用于编译，平时使用 Fishbot 不需要 Windows 电脑在线。

## 1. 取得 IPA

打开 https://github.com/YshaoF/ds-Fishbot/actions ，选择成功的 `Build Fishbot iOS (unsigned)` 运行。在 Artifacts 下载 `Fishbot-iOS-personal-signing` 并解压，找到 `Fishbot-unsigned.ipa`。如果收到本地提供的同名 IPA，也可直接使用。

IPA 当前未签名，不能直接在 iPhone 点开安装。请继续下面的个人签名步骤。

## 2. 准备 Windows 安装工具

从官方 https://sideloadly.io/ 下载 Windows 版 Sideloadly，按其当前官方说明准备 Apple 设备驱动及 iTunes/iCloud 组件。不要从不明下载站获取安装器；本工程没有附带或自动安装第三方签名工具。

## 3. 个人签名安装

1. 用数据线连接并解锁 iPhone，在设备上完成「信任这台电脑」。
2. 打开 Sideloadly，选择自己的 iPhone，把 `Fishbot-unsigned.ipa` 拖进去。
3. 在 Sideloadly 中登录你自己的 Apple 账号，并按工具提示完成验证。账号、密码、验证码不要发给其他人，也不要填到 Fishbot API 设置中。
4. 开始签名安装。若 iPhone 提示信任开发者，在「设置 → 通用 → VPN 与设备管理」中按实际提示处理。
5. iOS 16 及以上若提示开发者模式，请在「设置 → 隐私与安全性 → 开发者模式」中按系统步骤开启并重启确认。
6. 打开 Fishbot，为助理命名，在「设置」填入自己的模型 API Key。默认 DeepSeek 地址和模型已预置；先测试连接再保存。

## 4. 免费续签和数据保留

免费 Apple 账号签名通常有效7天，Sideloadly 支持续签/自动刷新，续签本身不要求付费开发者会员。自动续签需要 Windows 电脑及设备连接条件满足，不能保证电脑永久关机后仍能刷新。

更新或续签时保持同一 Apple 账号和相同 bundle ID，使用覆盖安装。不要为了续签先卸载 App；卸载可能移除本机聊天。Fishbot 设置中的「导出备份」不包含 Key，建议更新或重装前先保存备份。

## 费用和验证范围

- Fishbot 没有内置订阅或应用内购买。本安装方案使用个人签名。
- 公开仓库的标准 GitHub runner 可免费构建；私有仓库有额度限制。工作流设20分钟超时、产物保留3天。
- 你配置的 API 仍按服务商规则收费，文件分析和群聊会增加输入/调用量。
- 云端编译和模拟器启动不代替你的 iPhone 真机测试。出现安装失败时先保留错误信息，不要随意更改 Apple 账号或删除已有聊天。

官方参考：

- https://sideloadly.io/faq
- https://faq.altstore.io/altstore-classic/how-to-install-altstore-windows
- https://developer.apple.com/help/account/basics/about-your-developer-account/
- https://docs.github.com/en/actions/concepts/billing-and-usage


### 0.2.0 小鲸陪伴更新

安装时保留 App Extensions（不要选择 Remove App Extensions），否则主屏幕小组件与锁屏／灵动岛陪伴会被移除。安装后打开一次 Fishbot，可在主屏幕的小组件列表搜索 Fishbot。App 内底部「陪伴」可轻触、拖动、调整大小，或开始限时专注活动。签名有效期和账号规则沿用原流程，更新前建议导出本机备份。
