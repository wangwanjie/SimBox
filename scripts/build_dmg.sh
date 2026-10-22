#!/usr/bin/env bash
#
# 归档 SimBox（Release，通用二进制），再用 lipo 按架构瘦身成 arm64 / x86_64 两个 .app，
# 分别签名、用全局 create_pretty_dmg.sh 生成 DMG，并可选公证。
#
# 用法:
#   ./scripts/build_dmg.sh [--arch arm64|x86_64]... [--keychain-profile PROFILE] [--no-notarize] [--skip-archive]
#
# 默认同时产出两种架构，使用 --keychain-profile "vanjay_mac_stapler" 公证；传入 --no-notarize 跳过公证（ad-hoc 签名）。
# 产物: build/dmg/SimBox_v<版本>_arm64.dmg、build/dmg/SimBox_v<版本>_x86_64.dmg
#

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
SCHEME="SimBox"
PROJECT="SimBox.xcodeproj"
CONFIGURATION="Release"
BUILD_DIR="$PROJECT_DIR/build"
DERIVED_DATA="$BUILD_DIR/DerivedData"
ARCHIVE_PATH="$BUILD_DIR/SimBox.xcarchive"
STAGE_DIR="$BUILD_DIR/stage"
DMG_OUTPUT_DIR="$BUILD_DIR/dmg"
APP_ENTITLEMENTS="$PROJECT_DIR/SimBox/SimBox.entitlements"
PBXPROJ="$PROJECT_DIR/SimBox.xcodeproj/project.pbxproj"
KEYCHAIN_PROFILE="vanjay_mac_stapler"
DO_NOTARIZE=true
DO_ARCHIVE=true
ARCHES=()
SUPPORTED_ARCHES=(arm64 x86_64)

require_command() {
    local cmd="$1"
    command -v "$cmd" >/dev/null 2>&1 || { echo "错误: 未找到 $cmd" >&2; exit 1; }
}

# 从 keychain 里挑一个 Developer ID Application 身份。指定 team ID 优先匹配。
find_developer_id_identity() {
    local team_id="${1:-}"
    local matches
    matches="$(security find-identity -v -p codesigning 2>/dev/null | grep 'Developer ID Application' || true)"
    if [[ -z "$matches" ]]; then
        return 1
    fi
    if [[ -n "$team_id" ]]; then
        local hit
        hit="$(printf '%s\n' "$matches" | grep "($team_id)" | head -1 || true)"
        if [[ -n "$hit" ]]; then
            printf '%s\n' "$hit" | sed -E 's/^[[:space:]]*[0-9]+\)[[:space:]]+[A-F0-9]+[[:space:]]+"(.*)"[[:space:]]*$/\1/'
            return 0
        fi
    fi
    printf '%s\n' "$matches" | head -1 | sed -E 's/^[[:space:]]*[0-9]+\)[[:space:]]+[A-F0-9]+[[:space:]]+"(.*)"[[:space:]]*$/\1/'
}

verify_signature() {
    local target_path="$1" target_name="$2" sign_info
    if ! /usr/bin/codesign --verify --deep --strict --verbose=2 "$target_path"; then
        echo "错误: $target_name 签名校验失败" >&2
        exit 1
    fi
    if [[ "$DO_NOTARIZE" != true ]]; then
        return 0
    fi
    sign_info="$(codesign -dv --verbose=4 "$target_path" 2>&1)"
    if ! grep -q "Authority=Developer ID Application" <<<"$sign_info"; then
        echo "错误: $target_name 未使用 Developer ID Application 签名" >&2
        echo "$sign_info" >&2
        exit 1
    fi
    if ! grep -q "Timestamp=" <<<"$sign_info"; then
        echo "错误: $target_name 签名缺少 secure timestamp" >&2
        exit 1
    fi
}

# 按 Sparkle 官方文档的顺序由内向外签名：先 XPC / Autoupdate / Updater.app，再 framework，最后主 app。
# 不能用 --deep 一把梭，也不能先签外层再签内层，否则外层的封印会失效。
sign_app() {
    local identity="$1" app_path="$2"
    local sparkle="$app_path/Contents/Frameworks/Sparkle.framework"
    local sparkle_version="$sparkle/Versions/B"
    local sign_args=(--force --sign "$identity" --options runtime)
    if [[ "$identity" != "-" ]]; then
        sign_args+=(--timestamp)
    fi

    if [[ -d "$sparkle" ]]; then
        echo "签名 Sparkle 组件..."
        /usr/bin/codesign "${sign_args[@]}" "$sparkle_version/XPCServices/Installer.xpc"
        /usr/bin/codesign "${sign_args[@]}" --preserve-metadata=entitlements "$sparkle_version/XPCServices/Downloader.xpc"
        /usr/bin/codesign "${sign_args[@]}" "$sparkle_version/Autoupdate"
        /usr/bin/codesign "${sign_args[@]}" "$sparkle_version/Updater.app"
        /usr/bin/codesign "${sign_args[@]}" "$sparkle"
    fi

    echo "签名主 app..."
    /usr/bin/codesign "${sign_args[@]}" --entitlements "$APP_ENTITLEMENTS" "$app_path"
}

# 把 .app 内所有通用 Mach-O 瘦身成单一架构。`ditto --arch` 在新系统上不再可靠，这里直接用 lipo。
thin_app() {
    local app_path="$1" arch="$2" file archs
    while IFS= read -r -d '' file; do
        if ! archs="$(lipo -archs "$file" 2>/dev/null)"; then
            continue
        fi
        if [[ "$archs" == "$arch" ]]; then
            continue
        fi
        if [[ " $archs " != *" $arch "* ]]; then
            echo "错误: $file 不包含 $arch 架构（现有: $archs）" >&2
            exit 1
        fi
        lipo -thin "$arch" "$file" -output "$file.thin"
        # 保留原文件权限
        chmod "$(stat -f '%Lp' "$file")" "$file.thin"
        mv -f "$file.thin" "$file"
    done < <(find "$app_path" -type f -print0)
}

# 检查 .app 内所有 Mach-O 都只包含目标架构。
verify_architecture() {
    local app_path="$1" arch="$2" file archs
    while IFS= read -r -d '' file; do
        if ! archs="$(lipo -archs "$file" 2>/dev/null)"; then
            continue
        fi
        if [[ "$archs" != "$arch" ]]; then
            echo "错误: $file 的架构是 [$archs]，期望 [$arch]" >&2
            exit 1
        fi
    done < <(find "$app_path" -type f -print0)
}

notarize_dmg() {
    local dmg_path="$1" output notary_id
    echo "提交公证 $(basename "$dmg_path") (keychain-profile: $KEYCHAIN_PROFILE)..."
    output=$(xcrun notarytool submit "$dmg_path" --keychain-profile "$KEYCHAIN_PROFILE" --wait 2>&1) || true
    echo "$output"
    if grep -q "status: Accepted" <<<"$output"; then
        xcrun stapler staple "$dmg_path"
        xcrun stapler validate "$dmg_path"
        echo "公证并钉合完成。"
    else
        echo "公证未通过 (status 非 Accepted)。" >&2
        notary_id=$(sed -n 's/.*id:[[:space:]]*\([^[:space:]]*\).*/\1/p' <<<"$output" | head -1)
        if [[ -n "$notary_id" ]]; then
            echo "查看失败原因: xcrun notarytool log $notary_id --keychain-profile \"$KEYCHAIN_PROFILE\"" >&2
        fi
        exit 1
    fi
}

# 参数解析
while [[ $# -gt 0 ]]; do
    case $1 in
        --arch)
            ARCHES+=("${2:?}"); shift 2 ;;
        --keychain-profile)
            KEYCHAIN_PROFILE="${2:?}"; shift 2 ;;
        --no-notarize)
            DO_NOTARIZE=false; shift ;;
        --skip-archive)
            DO_ARCHIVE=false; shift ;;
        -h|--help)
            grep '^#' "$0" | head -12
            exit 0 ;;
        *)
            echo "未知参数: $1" >&2; exit 1 ;;
    esac
done

if [[ ${#ARCHES[@]} -eq 0 ]]; then
    ARCHES=("${SUPPORTED_ARCHES[@]}")
fi
for arch in "${ARCHES[@]}"; do
    if [[ ! " ${SUPPORTED_ARCHES[*]} " =~ " $arch " ]]; then
        echo "错误: 不支持的架构 $arch（可选: ${SUPPORTED_ARCHES[*]}）" >&2
        exit 1
    fi
done

require_command xcodebuild
require_command codesign
require_command ditto
require_command lipo
require_command create_pretty_dmg.sh

cd "$PROJECT_DIR"

VERSION=$(grep -m1 "MARKETING_VERSION" "$PBXPROJ" | sed 's/.*MARKETING_VERSION = \([^;]*\);/\1/' | tr -d ' ')
if [[ -z "$VERSION" ]]; then
    echo "错误: 无法读取 MARKETING_VERSION" >&2
    exit 1
fi
echo "版本: $VERSION，架构: ${ARCHES[*]}"

ARCHIVED_APP="$ARCHIVE_PATH/Products/Applications/SimBox.app"

if [[ "$DO_ARCHIVE" == true ]]; then
    echo "归档 $SCHEME (Release, arm64 + x86_64)..."
    rm -rf "$ARCHIVE_PATH"
    xcodebuild -project "$PROJECT" \
        -scheme "$SCHEME" \
        -configuration "$CONFIGURATION" \
        -derivedDataPath "$DERIVED_DATA" \
        -archivePath "$ARCHIVE_PATH" \
        -destination "generic/platform=macOS" \
        ARCHS="arm64 x86_64" \
        ONLY_ACTIVE_ARCH=NO \
        clean archive
fi

if [[ ! -d "$ARCHIVED_APP" ]]; then
    echo "错误: 未找到构建产物 $ARCHIVED_APP" >&2
    exit 1
fi

# 瘦身会破坏原签名，所以无论是否公证都要重新签名；不公证时使用 ad-hoc 签名。
SIGNING_IDENTITY="-"
if [[ "$DO_NOTARIZE" == true ]]; then
    TEAM_ID="$(grep -m1 'DEVELOPMENT_TEAM' "$PBXPROJ" | sed 's/.*DEVELOPMENT_TEAM = \([^;]*\);/\1/' | tr -d ' "')"
    if ! SIGNING_IDENTITY="$(find_developer_id_identity "$TEAM_ID")"; then
        echo "错误: keychain 里找不到 Developer ID Application 身份，无法公证。" >&2
        echo "运行 security find-identity -v -p codesigning 检查。" >&2
        exit 1
    fi
fi
echo "签名身份: $SIGNING_IDENTITY"

mkdir -p "$DMG_OUTPUT_DIR"
PRODUCED=()
for arch in "${ARCHES[@]}"; do
    echo "===== $arch ====="
    arch_stage="$STAGE_DIR/$arch"
    app_path="$arch_stage/SimBox.app"
    rm -rf "$arch_stage"
    mkdir -p "$arch_stage"

    echo "瘦身为 $arch..."
    ditto "$ARCHIVED_APP" "$app_path"
    thin_app "$app_path" "$arch"
    verify_architecture "$app_path" "$arch"

    sign_app "$SIGNING_IDENTITY" "$app_path"
    verify_signature "$app_path" "SimBox.app ($arch)"

    dmg_name="SimBox_v${VERSION}_${arch}"
    dmg_path="$DMG_OUTPUT_DIR/$dmg_name.dmg"
    rm -f "$dmg_path"
    echo "生成 DMG..."
    create_pretty_dmg.sh \
        --app-path "$app_path" \
        --dmg-name "$dmg_name" \
        --output-dir "$DMG_OUTPUT_DIR"
    if [[ ! -f "$dmg_path" ]]; then
        echo "错误: 未找到生成的 DMG $dmg_path" >&2
        exit 1
    fi

    if [[ "$DO_NOTARIZE" == true ]]; then
        notarize_dmg "$dmg_path"
    else
        echo "已跳过公证。"
    fi
    PRODUCED+=("$dmg_path")
done

echo "完成。产物:"
for dmg in "${PRODUCED[@]}"; do
    printf '  %s (%s)\n' "$dmg" "$(du -h "$dmg" | cut -f1)"
done
