<p align="center">
  <img src="assets/icon-256.png" width="128" height="128" alt="SimBox 图标">
</p>

<h1 align="center">SimBox</h1>

<p align="center">
  macOS 菜单栏工具：一键打开 iOS / iPadOS / watchOS / tvOS 模拟器里已安装 App 的沙盒目录、App Group 和 App Extension 容器。
</p>

<p align="center">
  <a href="https://wangwanjie.github.io/SimBox/">主页</a> ·
  <a href="https://github.com/wangwanjie/SimBox/releases/latest">下载</a> ·
  <a href="https://github.com/wangwanjie/SimBox/issues">反馈</a>
</p>

![SimBox 主界面](assets/screenshots/zh-Hans.png)

<details>
<summary>English / 繁體中文界面</summary>

![SimBox English](assets/screenshots/en.png)

![SimBox 繁體中文](assets/screenshots/zh-Hant.png)

</details>

点击菜单栏里的 SimBox 图标，按模拟器分组列出你自己安装的 App（系统 App 自动隐藏），已启动的模拟器排在最前；每个 App 的子菜单提供各种打开方式和常用操作。

## 下载

SimBox 为 Apple 芯片和 Intel 芯片分别提供安装包，需要 **macOS 13.0 或更高版本**。到 [最新 Release](https://github.com/wangwanjie/SimBox/releases/latest) 下载与你的 Mac 匹配的 DMG：

| 芯片 | 文件 |
| --- | --- |
| Apple 芯片（M 系列） | `SimBox_v<版本>_arm64.dmg` |
| Intel 芯片 | `SimBox_v<版本>_x86_64.dmg` |

不确定是哪种芯片时，打开「苹果菜单 › 关于本机」，「芯片」一栏写着 Apple M… 的选 arm64，写着 Intel 的选 x86_64。历史版本见 [Releases](https://github.com/wangwanjie/SimBox/releases)。

安装包已经过 Apple 公证。打开 DMG，把 SimBox 拖进「应用程序」文件夹即可。SimBox 内置 Sparkle 自动更新，只会下载与本机芯片匹配的版本；也可以在菜单中点「检查更新…」手动检查。

## 功能

- 按模拟器分组列出用户安装的 App、App Group、App Extension，显示 App 图标、名称和版本号
- 已启动的模拟器排最前，其余按最近使用时间排序；超过 5 台的收进「More Simulators」子菜单
- 每个 App / 容器的子菜单：
  - 用 Finder / Terminal / iTerm / Commander One 打开沙盒目录（⌘1…⌘9 快捷键）
  - 在 Finder 中定位 `.app` 安装包
  - 打开 `UserDefaults` 对应的 plist
  - 复制沙盒路径、复制 Bundle Identifier
  - 重置 App 数据：清空 Documents / Library / tmp 内容，保留容器结构，App 下次启动即可正常读写
- 检测到 `.realm` 文件时提供 Realm Studio 快捷入口
- 模拟器标题的子菜单：在 Finder 中打开设备目录、复制 UDID
- 开机自启，需要授权时自动跳转到「系统设置 › 登录项」
- 自动更新，Apple 芯片与 Intel 分别推送各自的安装包
- 界面支持 English / 简体中文 / 繁體中文，跟随系统语言

## 快捷键

点击 App 条目本身时，按住不同修饰键打开到不同位置：

| 修饰键 | 打开位置 |
| --- | --- |
| 无 | Finder |
| ⌥ Option | Terminal |
| ⌃ Control | Commander One（若已安装） |

## 系统要求

- macOS 13.0 或更高版本
- Apple 芯片或 Intel 芯片
- 已安装 Xcode 及模拟器运行时

## 反馈

遇到问题或有功能建议，欢迎在 [Issues](https://github.com/wangwanjie/SimBox/issues) 中反馈。本仓库只用于发布安装包与更新信息，不包含源代码。

Copyright © 2026 VanJay. All rights reserved.
