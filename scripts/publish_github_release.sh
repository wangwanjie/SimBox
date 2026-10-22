#!/usr/bin/env bash
#
# 上传 SimBox DMG 到 GitHub Releases，并同步 appcast。
# 默认上传 build/dmg/ 下当前版本（MARKETING_VERSION）的全部架构 DMG：SimBox_v<版本>_<arch>.dmg。
#

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
DEFAULT_DMG_DIR="$PROJECT_DIR/build/dmg"
PBXPROJ="$PROJECT_DIR/SimBox.xcodeproj/project.pbxproj"
INFO_PLIST="$PROJECT_DIR/SimBox/Info.plist"

DMG_PATHS=()
REPO=""
TAG=""
TITLE=""
NOTES=""
NOTES_FILE=""
GENERATE_NOTES=false
DRAFT=false
PRERELEASE=false

usage() {
    cat <<'EOF'
用法:
  ./scripts/publish_github_release.sh [--dmg PATH]... [--repo OWNER/REPO] [--tag TAG]
                                     [--title TITLE] [--notes TEXT | --notes-file FILE | --generate-notes]
                                     [--draft] [--prerelease]

前置:
  1. gh auth login 已完成，或 GITHUB_TOKEN 已配置
  2. build_dmg.sh 已生成 DMG
EOF
}

require_command() {
    command -v "$1" >/dev/null 2>&1 || { echo "错误: 未找到 $1" >&2; exit 1; }
}

resolve_path() {
    local candidate="$1"
    [[ -z "$candidate" ]] && { echo ""; return 0; }
    if [[ ! "$candidate" = /* ]]; then
        if [[ -e "$candidate" ]]; then :
        elif [[ -e "$PROJECT_DIR/$candidate" ]]; then candidate="$PROJECT_DIR/$candidate"
        fi
    fi
    [[ ! -e "$candidate" ]] && { echo ""; return 0; }
    ( cd "$(dirname "$candidate")"; printf '%s/%s\n' "$(pwd)" "$(basename "$candidate")" )
}

read_plist_string() {
    /usr/libexec/PlistBuddy -c "Print :$1" "$INFO_PLIST" 2>/dev/null || true
}

extract_github_repo_from_url() {
    local url="$1"
    # 剥掉尾部 /, .git，剥掉 https:// 或 git@ 前缀，再切 owner/repo。
    local stripped="${url%/}"
    stripped="${stripped%.git}"
    if [[ "$stripped" =~ ^https://github\.com/([^/]+)/([^/]+)$ ]]; then
        printf '%s/%s\n' "${BASH_REMATCH[1]}" "${BASH_REMATCH[2]}"; return 0
    fi
    if [[ "$stripped" =~ ^git@github\.com:([^/]+)/([^/]+)$ ]]; then
        printf '%s/%s\n' "${BASH_REMATCH[1]}" "${BASH_REMATCH[2]}"; return 0
    fi
    return 1
}

detect_repo() {
    local remote_url
    remote_url="$(read_plist_string "SimBoxGitHubURL")"
    [[ -n "$remote_url" ]] && extract_github_repo_from_url "$remote_url" && return 0
    while IFS=$'\t' read -r _name candidate; do
        extract_github_repo_from_url "$candidate" && return 0
    done < <(git remote -v | awk '$3=="(push)" {print $1 "\t" $2}' | awk '!seen[$1]++')
    return 1
}

# 文件名形如 SimBox_v2.2.0_arm64.dmg，取出版本号。
infer_version_from_dmg() {
    local n
    n="$(basename "$1")"
    if [[ "$n" =~ ^SimBox_v?([0-9][^_]*)_(arm64|x86_64)\.dmg$ ]]; then
        printf '%s\n' "${BASH_REMATCH[1]}"
        return 0
    fi
    return 1
}

read_marketing_version() {
    grep -m1 "MARKETING_VERSION" "$PBXPROJ" | sed 's/.*MARKETING_VERSION = \([^;]*\);/\1/' | tr -d ' '
}

while [[ $# -gt 0 ]]; do
    case "$1" in
        --dmg) DMG_PATHS+=("${2:?}"); shift 2 ;;
        --repo) REPO="${2:?}"; shift 2 ;;
        --tag) TAG="${2:?}"; shift 2 ;;
        --title) TITLE="${2:?}"; shift 2 ;;
        --notes) NOTES="${2:?}"; shift 2 ;;
        --notes-file) NOTES_FILE="${2:?}"; shift 2 ;;
        --generate-notes) GENERATE_NOTES=true; shift ;;
        --draft) DRAFT=true; shift ;;
        --prerelease) PRERELEASE=true; shift ;;
        -h|--help) usage; exit 0 ;;
        *) echo "未知参数: $1" >&2; usage >&2; exit 1 ;;
    esac
done

if [[ -n "$NOTES" && -n "$NOTES_FILE" ]]; then
    echo "错误: --notes 和 --notes-file 二选一" >&2; exit 1
fi
if [[ "$GENERATE_NOTES" == true && ( -n "$NOTES" || -n "$NOTES_FILE" ) ]]; then
    echo "错误: --generate-notes 不能与 --notes/--notes-file 同时使用" >&2; exit 1
fi

require_command git
require_command gh

if ! gh auth status >/dev/null 2>&1; then
    echo "错误: gh 未登录，请先运行 gh auth login" >&2; exit 1
fi

if [[ ${#DMG_PATHS[@]} -gt 0 ]]; then
    for i in "${!DMG_PATHS[@]}"; do
        DMG_PATHS[$i]="$(resolve_path "${DMG_PATHS[$i]}")"
    done
else
    CURRENT_VERSION="$(read_marketing_version)"
    shopt -s nullglob
    DMG_PATHS=( "$DEFAULT_DMG_DIR"/SimBox_v"$CURRENT_VERSION"_*.dmg )
    shopt -u nullglob
fi
if [[ ${#DMG_PATHS[@]} -eq 0 ]]; then
    echo "错误: 找不到 DMG。先跑 ./scripts/build_dmg.sh" >&2; exit 1
fi
for dmg in "${DMG_PATHS[@]}"; do
    if [[ -z "$dmg" || ! -f "$dmg" ]]; then
        echo "错误: DMG 不存在: $dmg" >&2; exit 1
    fi
    if ! infer_version_from_dmg "$dmg" >/dev/null; then
        echo "错误: DMG 文件名需形如 SimBox_v2.2.0_arm64.dmg: $(basename "$dmg")" >&2; exit 1
    fi
done

if [[ -n "$NOTES_FILE" ]]; then
    NOTES_FILE="$(resolve_path "$NOTES_FILE")"
    [[ -z "$NOTES_FILE" || ! -f "$NOTES_FILE" ]] && { echo "错误: 找不到 notes 文件" >&2; exit 1; }
fi

[[ -z "$REPO" ]] && { REPO="$(detect_repo)" || { echo "错误: 无法推断 GitHub 仓库" >&2; exit 1; }; }

VERSION="$(infer_version_from_dmg "${DMG_PATHS[0]}")"
for dmg in "${DMG_PATHS[@]}"; do
    if [[ "$(infer_version_from_dmg "$dmg")" != "$VERSION" ]]; then
        echo "错误: 待上传的 DMG 版本不一致" >&2; exit 1
    fi
done
[[ -z "$VERSION" ]] && { echo "错误: 无法推断版本号" >&2; exit 1; }

[[ -z "$TAG" ]] && TAG="v$VERSION"
[[ -z "$TITLE" ]] && TITLE="SimBox v$VERSION"

echo "仓库: $REPO"
echo "Tag:  $TAG"
echo "标题: $TITLE"
printf "DMG:  %s\n" "${DMG_PATHS[@]}"

if gh release view "$TAG" -R "$REPO" >/dev/null 2>&1; then
    echo "Release 已存在，上传并覆盖同名资源..."
    gh release upload "$TAG" "${DMG_PATHS[@]}" -R "$REPO" --clobber
else
    echo "创建 Release..."
    create_args=(release create "$TAG" "${DMG_PATHS[@]}" -R "$REPO" --title "$TITLE")
    if [[ "$GENERATE_NOTES" == true ]]; then
        create_args+=(--generate-notes)
    elif [[ -n "$NOTES_FILE" ]]; then
        create_args+=(--notes-file "$NOTES_FILE")
    else
        create_args+=(--notes "${NOTES:-Release $TAG}")
    fi
    [[ "$DRAFT" == true ]] && create_args+=(--draft)
    [[ "$PRERELEASE" == true ]] && create_args+=(--prerelease)
    gh "${create_args[@]}"
fi

echo "完成: https://github.com/$REPO/releases/tag/$TAG"

APPCAST_NOTES="$(gh release view "$TAG" -R "$REPO" --json body --jq '.body // ""' 2>/dev/null || true)"

APPCAST_ARGS=(--repo "$REPO")
for dmg in "${DMG_PATHS[@]}"; do
    APPCAST_ARGS+=(--archive "$dmg")
done
[[ -n "$APPCAST_NOTES" ]] && APPCAST_ARGS+=(--notes "$APPCAST_NOTES")

"$PROJECT_DIR/scripts/generate_appcast.sh" "${APPCAST_ARGS[@]}"

echo "appcast.xml / appcast-arm64.xml / appcast-x86_64.xml 已更新，请提交并推送到默认分支。"
