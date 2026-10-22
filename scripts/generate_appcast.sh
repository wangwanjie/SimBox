#!/usr/bin/env bash
#
# 根据归档 DMG 生成 Sparkle appcast，并把 enclosure 改写为 GitHub Releases 下载地址。
#
# 自 2.2.0 起按架构分别发布，产出三份 feed：
#   appcast-arm64.xml   Apple Silicon 版本读取（UpdateManager 按编译架构选择）
#   appcast-x86_64.xml  Intel 版本读取
#   appcast.xml         兼容 2.1.0 及更早的通用包：最新 arm64 项（带 hardwareRequirements=arm64）在前、
#                       x86_64 项在后。Sparkle 在版本相同时选第一个满足条件的项，Intel 机器会跳过 arm64 项。
#
# 用法:
#   ./scripts/generate_appcast.sh [--archive PATH]... [--archives-dir DIR] [--output-dir DIR]
#                                 [--repo OWNER/REPO] [--account ACCOUNT]
#                                 [--notes TEXT | --notes-file FILE]
#

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
DEFAULT_ARCHIVES_DIR="$PROJECT_DIR/build/appcast-archives"
DEFAULT_OUTPUT_DIR="$PROJECT_DIR"
INFO_PLIST="$PROJECT_DIR/SimBox/Info.plist"
DEFAULT_ACCOUNT="cn.vanjay.SimBox.sparkle"
SUPPORTED_ARCHES=(arm64 x86_64)

ARCHIVE_PATHS=()
ARCHIVES_DIR="$DEFAULT_ARCHIVES_DIR"
OUTPUT_DIR="$DEFAULT_OUTPUT_DIR"
REPO=""
ACCOUNT="$DEFAULT_ACCOUNT"
NOTES=""
NOTES_FILE=""

usage() {
    cat <<'USAGE'
用法:
  ./scripts/generate_appcast.sh [--archive PATH]... [--archives-dir DIR] [--output-dir DIR]
                                [--repo OWNER/REPO] [--account ACCOUNT]
                                [--notes TEXT | --notes-file FILE]

选项:
  --archive PATH       将 DMG（文件名形如 SimBox_v2.2.0_arm64.dmg）复制到对应架构的归档目录，可重复
  --archives-dir DIR   历史 DMG 根目录，按架构分子目录保存，默认 build/appcast-archives
  --output-dir DIR     appcast 输出目录，默认仓库根目录
  --repo OWNER/REPO    GitHub 仓库
  --account ACCOUNT    Sparkle EdDSA Keychain account，默认 cn.vanjay.SimBox.sparkle
  --notes TEXT         为本次 archive 生成同名 .md 发布说明
  --notes-file FILE    为本次 archive 复制同名发布说明文件
USAGE
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
    local stripped="${url%/}"
    stripped="${stripped%.git}"
    if [[ "$stripped" =~ ^https://github\.com/([^/]+)/([^/]+)$ ]]; then
        printf '%s/%s\n' "${BASH_REMATCH[1]}" "${BASH_REMATCH[2]}"
        return 0
    fi
    if [[ "$stripped" =~ ^git@github\.com:([^/]+)/([^/]+)$ ]]; then
        printf '%s/%s\n' "${BASH_REMATCH[1]}" "${BASH_REMATCH[2]}"
        return 0
    fi
    return 1
}

detect_repo() {
    local repo_url
    repo_url="$(read_plist_string "SimBoxGitHubURL")"
    [[ -n "$repo_url" ]] && extract_github_repo_from_url "$repo_url" && return 0
    while IFS=$'\t' read -r _name candidate; do
        extract_github_repo_from_url "$candidate" && return 0
    done < <(git remote -v | awk '$3=="(push)" {print $1 "\t" $2}' | awk '!seen[$1]++')
    return 1
}

find_sparkle_bin_dir() {
    if [[ -n "${SPARKLE_BIN_DIR:-}" && -x "${SPARKLE_BIN_DIR}/generate_appcast" ]]; then
        printf '%s\n' "$SPARKLE_BIN_DIR"; return 0
    fi
    while IFS= read -r candidate; do
        if [[ -x "$candidate/generate_appcast" && -x "$candidate/generate_keys" ]]; then
            printf '%s\n' "$candidate"; return 0
        fi
    done < <(find "$PROJECT_DIR/build" "$HOME/Library/Developer/Xcode/DerivedData" -path '*/SourcePackages/artifacts/sparkle/Sparkle/bin' -type d 2>/dev/null | sort -r)
    return 1
}

# 从 SimBox_v2.2.0_arm64.dmg 中取出架构名。
arch_from_archive_name() {
    local name
    name="$(basename "$1")"
    if [[ "$name" =~ ^SimBox_v?[0-9][^_]*_(arm64|x86_64)\.dmg$ ]]; then
        printf '%s\n' "${BASH_REMATCH[1]}"
        return 0
    fi
    return 1
}

copy_release_notes() {
    local archive_dest="$1"
    local base_path="${archive_dest%.*}"
    if [[ -n "$NOTES_FILE" ]]; then
        cp "$NOTES_FILE" "${base_path}.${NOTES_FILE##*.}"
    elif [[ -n "$NOTES" ]]; then
        printf '%s\n' "$NOTES" > "${base_path}.md"
    fi
}

while [[ $# -gt 0 ]]; do
    case "$1" in
        --archive) ARCHIVE_PATHS+=("${2:?}"); shift 2 ;;
        --archives-dir) ARCHIVES_DIR="${2:?}"; shift 2 ;;
        --output-dir) OUTPUT_DIR="${2:?}"; shift 2 ;;
        --repo) REPO="${2:?}"; shift 2 ;;
        --account) ACCOUNT="${2:?}"; shift 2 ;;
        --notes) NOTES="${2:-}"; shift 2 ;;
        --notes-file) NOTES_FILE="${2:?}"; shift 2 ;;
        -h|--help) usage; exit 0 ;;
        *) echo "未知参数: $1" >&2; usage >&2; exit 1 ;;
    esac
done

if [[ -n "$NOTES" && -n "$NOTES_FILE" ]]; then
    echo "错误: --notes 和 --notes-file 只能二选一" >&2; exit 1
fi

require_command /usr/bin/python3
require_command /usr/libexec/PlistBuddy

ARCHIVES_DIR="${ARCHIVES_DIR/#\~/$HOME}"
OUTPUT_DIR="${OUTPUT_DIR/#\~/$HOME}"

if [[ -n "$NOTES_FILE" ]]; then
    NOTES_FILE="$(resolve_path "$NOTES_FILE")"
    if [[ -z "$NOTES_FILE" || ! -f "$NOTES_FILE" ]]; then
        echo "错误: 未找到 notes 文件" >&2; exit 1
    fi
fi

if [[ -z "$REPO" ]]; then
    if ! REPO="$(detect_repo)"; then
        echo "错误: 无法推断 GitHub 仓库，请通过 --repo OWNER/REPO 指定" >&2; exit 1
    fi
fi
if ! [[ "$REPO" =~ ^[^/]+/[^/]+$ ]]; then
    echo "错误: --repo 必须是 OWNER/REPO 格式" >&2; exit 1
fi

if ! SPARKLE_BIN_DIR="$(find_sparkle_bin_dir)"; then
    echo "错误: 未找到 Sparkle 工具，请先在 Xcode 里解析一次包依赖 (Product > Resolve Package Dependencies)" >&2
    exit 1
fi

if ! "$SPARKLE_BIN_DIR/generate_keys" --account "$ACCOUNT" -p >/dev/null 2>&1; then
    echo "错误: 未找到 Sparkle EdDSA 私钥。先运行以下命令生成一次:" >&2
    echo "  $SPARKLE_BIN_DIR/generate_keys --account $ACCOUNT" >&2
    exit 1
fi

for archive in ${ARCHIVE_PATHS[@]+"${ARCHIVE_PATHS[@]}"}; do
    resolved="$(resolve_path "$archive")"
    if [[ -z "$resolved" || ! -f "$resolved" ]]; then
        echo "错误: 未找到 archive 文件 $archive" >&2; exit 1
    fi
    if ! arch="$(arch_from_archive_name "$resolved")"; then
        echo "错误: 无法从文件名识别架构: $(basename "$resolved")（应形如 SimBox_v2.2.0_arm64.dmg）" >&2; exit 1
    fi
    mkdir -p "$ARCHIVES_DIR/$arch"
    dest="$ARCHIVES_DIR/$arch/$(basename "$resolved")"
    cp "$resolved" "$dest"
    copy_release_notes "$dest"
done

TMP_DIR="$(mktemp -d "${TMPDIR:-/tmp}/simbox-appcast.XXXXXX")"
trap 'rm -rf "$TMP_DIR"' EXIT
mkdir -p "$OUTPUT_DIR"

GENERATED_ARCHES=()
for arch in "${SUPPORTED_ARCHES[@]}"; do
    arch_dir="$ARCHIVES_DIR/$arch"
    shopt -s nullglob
    archives=( "$arch_dir"/*.dmg )
    shopt -u nullglob
    if [[ ${#archives[@]} -eq 0 ]]; then
        echo "跳过 $arch：$arch_dir 中没有 DMG"
        continue
    fi

    work_dir="$TMP_DIR/$arch"
    mkdir -p "$work_dir"
    cp "${archives[@]}" "$work_dir/"
    for notes_path in "$arch_dir"/*.md "$arch_dir"/*.txt "$arch_dir"/*.html; do
        [[ -e "$notes_path" ]] || continue
        cp "$notes_path" "$work_dir/"
    done

    # 不生成 delta：delta 文件不会上传到 GitHub Release，生成了反而会让 appcast 指向不存在的地址。
    "$SPARKLE_BIN_DIR/generate_appcast" \
        --account "$ACCOUNT" \
        --link "https://github.com/$REPO" \
        --maximum-deltas 0 \
        -o "$work_dir/appcast.xml" \
        "$work_dir"

    /usr/bin/python3 - "$work_dir/appcast.xml" "$OUTPUT_DIR/appcast-$arch.xml" "$REPO" "$work_dir" "$arch" <<'PY'
import html
import pathlib
import re
import sys
import urllib.parse
import xml.etree.ElementTree as ET

input_path, output_path, repo, archives_dir, arch = sys.argv[1:6]
sparkle_ns = "http://www.andymatuschak.org/xml-namespaces/sparkle"
dc_ns = "http://purl.org/dc/elements/1.1/"
ET.register_namespace("sparkle", sparkle_ns)
ET.register_namespace("dc", dc_ns)

tree = ET.parse(input_path)
root = tree.getroot()
channel = root.find("channel")
if channel is None:
    raise SystemExit("appcast 中缺少 channel 节点")

def find_or_create(parent, tag):
    node = parent.find(tag)
    if node is None:
        node = ET.SubElement(parent, tag)
    return node

def replace_inline_markup(text):
    escaped = html.escape(text, quote=False)
    def replace_link(m):
        return f'<a href="{html.escape(m.group(2), quote=True)}">{m.group(1)}</a>'
    escaped = re.sub(r"\[([^\]]+)\]\((https?://[^)]+)\)", replace_link, escaped)
    escaped = re.sub(r"(?<!\*)\*\*([^*]+)\*\*", r"<strong>\1</strong>", escaped)
    escaped = re.sub(r"(?<!\*)\*([^*]+)\*", r"<em>\1</em>", escaped)
    escaped = re.sub(r"(?<![\"'>])(https?://[^\s<]+)",
                     lambda m: f'<a href="{html.escape(m.group(1), quote=True)}">{m.group(1)}</a>',
                     escaped)
    return escaped

def markdown_to_html(md):
    lines = md.replace("\r\n", "\n").split("\n")
    blocks, para, items, code = [], [], [], []
    in_code = False
    def flush_para():
        nonlocal para
        if para:
            body = "<br/>".join(replace_inline_markup(l.strip()) for l in para if l.strip())
            if body: blocks.append(f"<p>{body}</p>")
            para = []
    def flush_list():
        nonlocal items
        if items:
            body = "".join(f"<li>{replace_inline_markup(i)}</li>" for i in items)
            blocks.append(f"<ul>{body}</ul>")
            items = []
    def flush_code():
        nonlocal code
        if code:
            blocks.append(f"<pre><code>{html.escape(chr(10).join(code))}</code></pre>")
            code = []
    for raw in lines:
        line = raw.rstrip(); stripped = line.strip()
        if stripped.startswith("```"):
            flush_para(); flush_list()
            if in_code: flush_code()
            in_code = not in_code; continue
        if in_code:
            code.append(line); continue
        if not stripped:
            flush_para(); flush_list(); continue
        h = re.match(r"^(#{1,6})\s+(.*)$", stripped)
        if h:
            flush_para(); flush_list()
            blocks.append(f"<h{len(h.group(1))}>{replace_inline_markup(h.group(2).strip())}</h{len(h.group(1))}>")
            continue
        if re.fullmatch(r"[-*_]{3,}", stripped):
            flush_para(); flush_list(); blocks.append("<hr/>"); continue
        li = re.match(r"^[-*]\s+(.*)$", stripped)
        if li:
            flush_para(); items.append(li.group(1).strip()); continue
        flush_list(); para.append(line)
    flush_para(); flush_list()
    if in_code: flush_code()
    return "\n".join(blocks).strip()

def load_release_notes_html(filename):
    stem = pathlib.Path(filename).stem
    base = pathlib.Path(archives_dir) / stem
    for ext, fn in [(".html", None), (".md", markdown_to_html), (".txt", None)]:
        path = pathlib.Path(f"{base}{ext}")
        if path.exists():
            text = path.read_text(encoding="utf-8")
            if fn: return fn(text)
            if ext == ".html": return text.strip()
            return f"<div style=\"white-space: pre-wrap;\">{html.escape(text.strip())}</div>"
    return ""

title = find_or_create(channel, "title")
title.text = "SimBox"
link = find_or_create(channel, "link"); link.text = f"https://github.com/{repo}"
desc = find_or_create(channel, "description"); desc.text = f"SimBox release feed ({arch})."
lang = find_or_create(channel, "language")
if not (lang.text or "").strip(): lang.text = "en"

for item in channel.findall("item"):
    enclosure = item.find("enclosure")
    if enclosure is None: continue
    raw_url = enclosure.attrib.get("url", "")
    filename = pathlib.PurePosixPath(urllib.parse.urlparse(raw_url).path).name or pathlib.Path(raw_url).name
    if not filename: continue

    m = re.match(r"SimBox_v?(\d[^_]*)_(arm64|x86_64)\.dmg$", filename)
    if m is None:
        raise SystemExit(f"无法从 {filename} 推断版本号与架构")
    version = m.group(1)
    tag = f"v{version}"
    enclosure.set("url", f"https://github.com/{repo}/releases/download/{urllib.parse.quote(tag, safe='')}/{urllib.parse.quote(filename, safe='')}")
    item_link = find_or_create(item, "link")
    item_link.text = f"https://github.com/{repo}/releases/tag/{urllib.parse.quote(tag, safe='')}"
    notes_html = load_release_notes_html(filename)
    if notes_html:
        find_or_create(item, "description").text = notes_html
    for tag_name in [f"{{{sparkle_ns}}}releaseNotesLink", f"{{{sparkle_ns}}}fullReleaseNotesLink"]:
        node = item.find(tag_name)
        if node is not None: item.remove(node)
    # arm64 包在 Intel 机器上无法运行，声明硬件要求，旧版通用包读取合并 feed 时据此过滤。
    requirement = item.find(f"{{{sparkle_ns}}}hardwareRequirements")
    if arch == "arm64":
        if requirement is None:
            requirement = ET.SubElement(item, f"{{{sparkle_ns}}}hardwareRequirements")
        requirement.text = "arm64"
    elif requirement is not None:
        item.remove(requirement)

ET.indent(tree, space="    ")
tree.write(output_path, encoding="utf-8", xml_declaration=True)
PY
    GENERATED_ARCHES+=("$arch")
    echo "已生成 appcast: $OUTPUT_DIR/appcast-$arch.xml"
done

if [[ ${#GENERATED_ARCHES[@]} -eq 0 ]]; then
    echo "错误: $ARCHIVES_DIR 下没有任何架构的 DMG" >&2
    exit 1
fi

# 合并出兼容旧版通用包的 appcast.xml：每个架构只取最新一项，arm64 在前。
/usr/bin/python3 - "$OUTPUT_DIR" "$REPO" "${GENERATED_ARCHES[@]}" <<'PY'
import copy
import pathlib
import sys
import xml.etree.ElementTree as ET

output_dir, repo, *arches = sys.argv[1:]
sparkle_ns = "http://www.andymatuschak.org/xml-namespaces/sparkle"
ET.register_namespace("sparkle", sparkle_ns)
ET.register_namespace("dc", "http://purl.org/dc/elements/1.1/")

def version_key(item):
    node = item.find(f"{{{sparkle_ns}}}version")
    text = (node.text or "0").strip() if node is not None else "0"
    return tuple(int(p) if p.isdigit() else 0 for p in text.split("."))

rss = ET.Element("rss", {"version": "2.0"})
channel = ET.SubElement(rss, "channel")
ET.SubElement(channel, "title").text = "SimBox"
ET.SubElement(channel, "link").text = f"https://github.com/{repo}"
ET.SubElement(channel, "description").text = "SimBox release feed (legacy universal builds)."
ET.SubElement(channel, "language").text = "en"

for arch in sorted(arches, key=lambda a: 0 if a == "arm64" else 1):
    tree = ET.parse(pathlib.Path(output_dir) / f"appcast-{arch}.xml")
    items = tree.getroot().find("channel").findall("item")
    if items:
        channel.append(copy.deepcopy(max(items, key=version_key)))

tree = ET.ElementTree(rss)
ET.indent(tree, space="    ")
tree.write(pathlib.Path(output_dir) / "appcast.xml", encoding="utf-8", xml_declaration=True)
PY

echo "已生成兼容 feed: $OUTPUT_DIR/appcast.xml"
echo "归档目录: $ARCHIVES_DIR"
