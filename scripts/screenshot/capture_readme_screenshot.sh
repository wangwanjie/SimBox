#!/usr/bin/env bash
#
# 用演示数据启动 Debug 版 SimBox，弹出菜单并展开第一个 app 的子菜单，截图保存为 docs/screenshot.png。
# 需要终端具有“屏幕录制”和“辅助功能”权限（用于截图和移动鼠标）。
#
# 用法: ./scripts/screenshot/capture_readme_screenshot.sh [输出路径]
#

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
OUTPUT="${1:-$PROJECT_DIR/docs/screenshot.png}"
DERIVED_DATA="$PROJECT_DIR/build/ScreenshotDerivedData"
DEMO_ROOT="$(mktemp -d "${TMPDIR:-/tmp}/simbox-demo.XXXXXX")"
APP_BINARY="$DERIVED_DATA/Build/Products/Debug/SimBox.app/Contents/MacOS/SimBox"
APP_PID=""

cleanup() {
    [[ -n "$APP_PID" ]] && kill "$APP_PID" 2>/dev/null || true
    rm -rf "$DEMO_ROOT"
}
trap cleanup EXIT

echo "构建 Debug 版..."
xcodebuild -project "$PROJECT_DIR/SimBox.xcodeproj" -scheme SimBox -configuration Debug \
    -derivedDataPath "$DERIVED_DATA" build >/dev/null

echo "生成演示数据..."
swift "$SCRIPT_DIR/make_demo_devices.swift" "$DEMO_ROOT/Devices" >/dev/null

# 已有实例会占用菜单栏位置，先退出。
pkill -x SimBox 2>/dev/null || true
sleep 1

SIMBOX_DEVICES_ROOT="$DEMO_ROOT/Devices" "$APP_BINARY" -SimBoxScreenshotMode YES >/dev/null 2>&1 &
APP_PID=$!
sleep 2.5

MAIN_RECT="$(swift "$SCRIPT_DIR/menu_windows.swift" --first)" || { echo "错误: 菜单没有弹出" >&2; exit 1; }
IFS=',' read -r MX MY _ _ <<<"$MAIN_RECT"
# 菜单窗口四周带约 75pt 的阴影留白，第一个 app 行在窗口顶部下方约 116pt 处。
swift "$SCRIPT_DIR/hover.swift" "$((MX + 110))" "$((MY + 116))"
sleep 1.2

REGION="$(swift "$SCRIPT_DIR/menu_windows.swift")"
mkdir -p "$(dirname "$OUTPUT")"
screencapture -x -R "$REGION" "$OUTPUT"
echo "截图已保存: $OUTPUT ($REGION)"
