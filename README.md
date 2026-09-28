# SimSim

macOS 菜单栏工具，快速定位 iOS/watchOS/tvOS 模拟器上已安装应用的沙盒目录。原项目：[dsmelov/simsim](https://github.com/dsmelov/simsim)，本 fork 面向 Xcode 27 / macOS 26+ 重写。

![macOS 13+](https://img.shields.io/badge/macOS-13.0%2B-blue) ![Xcode 27](https://img.shields.io/badge/Xcode-27-blue) ![Swift 5.10](https://img.shields.io/badge/Swift-5.10-orange)

## 功能

- 顶栏点击列出最近使用的模拟器与其应用、App Group、App Extension
- 每个 app 支持 Finder / Terminal / iTerm / Commander One 打开，或复制路径、重置沙盒
- 检测到 `.realm` 文件时提供 Realm Studio 快捷入口
- SMAppService 实现开机自启（macOS 13+）
- Sparkle 2 自动更新，从 GitHub Releases 分发 DMG

## 快捷键（点击应用条目时）

| 修饰键 | 打开位置 |
| --- | --- |
| 无 | Finder |
| ⌥ Option | Terminal |
| ⌃ Control | Commander One（若安装） |

## 开发

要求：macOS 13+，Xcode 27。

```bash
open SimSim.xcodeproj
```

首次会解析 Sparkle SPM 包。构建后就是 `SimSim.app`。

代码风格用 SwiftFormat 统一：

```bash
swiftformat SimSim scripts/generate_icons.swift
```

图标是脚本生成的：

```bash
swift scripts/generate_icons.swift
```

## 打包 & 发布

`scripts/` 下三个脚本组合完成 `打包 → 上传 → 生成 appcast`：

```bash
# 归档 Release + 签名 + 用 create_pretty_dmg.sh 出 DMG + 公证
./scripts/build_dmg.sh --keychain-profile vanjay_mac_stapler

# 上传到 GitHub Release + 更新 appcast.xml（要先 gh auth login）
./scripts/publish_github_release.sh --generate-notes
```

`publish_github_release.sh` 结尾会调 `scripts/generate_appcast.sh` 更新 `appcast.xml`，把 enclosure URL 改写成 GitHub Releases 下载地址。别忘了把 `appcast.xml` 一并 commit 并 push 到默认分支——`Info.plist` 里的 `SUFeedURL` 指向的就是它。

## Sparkle 密钥

一次性生成后放在 Keychain（account: `cn.vanjay.SimSim.sparkle`）：

```bash
SPARKLE_BIN="$(find ~/Library/Developer/Xcode/DerivedData -path '*/SourcePackages/artifacts/sparkle/Sparkle/bin' -type d | sort -r | head -1)"
"$SPARKLE_BIN/generate_keys" --account cn.vanjay.SimSim.sparkle
```

对应的 public key 已写入 `SimSim/Info.plist` 的 `SUPublicEDKey`。

## 版本号

在 `SimSim.xcodeproj/project.pbxproj` 里改 `MARKETING_VERSION` 与 `CURRENT_PROJECT_VERSION`。当前 2.0.0。

## License

MIT，见 [LICENSE](LICENSE)。
