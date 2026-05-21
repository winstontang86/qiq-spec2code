#!/usr/bin/env bash
# qiq-spec2code skill 打包脚本
# 用法：
#   bash scripts/build.sh                # 自动生成版本号
#   VERSION=v0.1.0 bash scripts/build.sh # 显式指定版本号
#   bash scripts/build.sh --no-zip       # 仅校验产物清单，不实际打包

set -euo pipefail

# ---------- 路径解析 ----------
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"
DIST_DIR="${ROOT_DIR}/dist"
STAGING_DIR="${DIST_DIR}/.staging"

# ---------- 参数解析 ----------
DO_ZIP=1
for arg in "$@"; do
    case "$arg" in
        --no-zip) DO_ZIP=0 ;;
        -h|--help)
            sed -n '2,7p' "${BASH_SOURCE[0]}"
            exit 0
            ;;
        *) echo "[WARN] 未知参数: $arg (忽略)" ;;
    esac
done

cd "${ROOT_DIR}"

# ---------- skill 名称（从 SKILL.md frontmatter 抽取） ----------
SKILL_NAME="$(awk -F': *' '/^name:/{print $2; exit}' SKILL.md | tr -d '\r' | tr -d ' ')"
if [[ -z "${SKILL_NAME}" ]]; then
    echo "[ERROR] 无法从 SKILL.md frontmatter 抽取 name 字段" >&2
    exit 1
fi

# ---------- frontmatter 中声明的语义版本（可选） ----------
SKILL_VERSION_DECL="$(awk -F': *' '/^version:/{print $2; exit}' SKILL.md | tr -d '\r' | tr -d ' ')"

# ---------- 版本号：优先 $VERSION，其次 git describe，再次日期戳 ----------
if [[ -n "${VERSION:-}" ]]; then
    PKG_VERSION="${VERSION}"
elif git -C "${ROOT_DIR}" rev-parse --git-dir >/dev/null 2>&1; then
    if PKG_VERSION="$(git -C "${ROOT_DIR}" describe --tags --always --dirty 2>/dev/null)"; then
        :
    else
        PKG_VERSION="0.0.0-$(date +%Y%m%d%H%M%S)"
    fi
else
    PKG_VERSION="0.0.0-$(date +%Y%m%d%H%M%S)"
fi

# ---------- 语义版本与 $VERSION 一致性校验（仅二者同时存在时） ----------
if [[ -n "${SKILL_VERSION_DECL}" && -n "${VERSION:-}" ]]; then
    norm_decl="${SKILL_VERSION_DECL#v}"
    norm_env="${VERSION#v}"
    if [[ "${norm_decl}" != "${norm_env}" ]]; then
        echo "[ERROR] SKILL.md frontmatter version=${SKILL_VERSION_DECL} 与 \$VERSION=${VERSION} 不一致" >&2
        echo "        请调整任一边使之同步后重试（去除 v 前缀后比较）" >&2
        exit 5
    fi
fi

PKG_BASENAME="${SKILL_NAME}-${PKG_VERSION}"
ZIP_PATH="${DIST_DIR}/${PKG_BASENAME}.zip"

echo "================================================================"
echo " skill 名称  : ${SKILL_NAME}"
echo " 版本        : ${PKG_VERSION}"
echo " 输出 zip    : ${ZIP_PATH}"
echo "================================================================"

# ---------- 清理 & 准备打包目录 ----------
rm -rf "${DIST_DIR}"
mkdir -p "${STAGING_DIR}/${SKILL_NAME}"

# ---------- 必备文件清单（缺一即失败） ----------
REQUIRED_PATHS=(
    "SKILL.md"
    "references"
    "templates"
)

# ---------- 可选文件（缺失仅警告） ----------
OPTIONAL_PATHS=(
    "README.md"
    "LICENSE"
)

# ---------- 校验必备文件 ----------
MISSING=0
for p in "${REQUIRED_PATHS[@]}"; do
    if [[ ! -e "${ROOT_DIR}/${p}" ]]; then
        echo "[ERROR] 缺少必备文件/目录: ${p}" >&2
        MISSING=1
    fi
done
if [[ "${MISSING}" -ne 0 ]]; then
    echo "[ERROR] 校验未通过，终止打包" >&2
    exit 2
fi

# ---------- 复制文件到 staging（保留目录结构） ----------
for p in "${REQUIRED_PATHS[@]}" "${OPTIONAL_PATHS[@]}"; do
    if [[ -e "${ROOT_DIR}/${p}" ]]; then
        cp -R "${ROOT_DIR}/${p}" "${STAGING_DIR}/${SKILL_NAME}/"
    else
        echo "[WARN] 可选文件缺失（跳过）: ${p}"
    fi
done

# ---------- 清理 staging 中不应入包的内容 ----------
find "${STAGING_DIR}/${SKILL_NAME}" \
    \( -name '.DS_Store' -o -name '*.swp' -o -name '*.swo' -o -name '*~' \) \
    -type f -delete

# ---------- 校验 SKILL.md 关键字段 ----------
SKILL_MD="${STAGING_DIR}/${SKILL_NAME}/SKILL.md"
for field in "name:" "description:"; do
    if ! grep -q "^${field}" "${SKILL_MD}"; then
        echo "[ERROR] SKILL.md 缺少 frontmatter 字段: ${field}" >&2
        exit 3
    fi
done

# ---------- 校验内部链接（@references / @templates）目标文件存在 ----------
# 抽取所有 markdown 链接形如 [text](relative.md|relative.json)，
# 以链接所在文件为基准，解析相对路径后判断目标是否存在。
LINK_FAIL_FILE="$(mktemp)"
echo 0 > "${LINK_FAIL_FILE}"
while IFS= read -r src_file; do
    [[ -z "${src_file}" ]] && continue
    src_dir="$(dirname "${src_file}")"
    # grep 找不到匹配返回 1，set -e + pipefail 下需要兜底
    targets="$(grep -oE '\]\([^)]+\.(md|json)[^)]*\)' "${src_file}" 2>/dev/null \
                | sed -E 's/^\]\(//; s/\)$//; s/#.*$//' || true)"
    [[ -z "${targets}" ]] && continue
    while IFS= read -r target; do
        [[ -z "${target}" ]] && continue
        case "${target}" in
            http*|mailto:*) continue ;;
            /*) abs_target="${target}" ;;
            *)  abs_target="${src_dir}/${target}" ;;
        esac
        if command -v python3 >/dev/null 2>&1; then
            abs_target="$(python3 -c 'import os,sys;print(os.path.normpath(sys.argv[1]))' "${abs_target}")"
        fi
        if [[ ! -e "${abs_target}" ]]; then
            echo "[WARN] 内部链接目标缺失: ${src_file} -> ${target}"
            cur="$(cat "${LINK_FAIL_FILE}")"
            echo $((cur + 1)) > "${LINK_FAIL_FILE}"
        fi
    done <<< "${targets}"
done < <(find "${STAGING_DIR}/${SKILL_NAME}" -type f -name '*.md')
LINK_FAIL="$(cat "${LINK_FAIL_FILE}")"
rm -f "${LINK_FAIL_FILE}"
if [[ "${LINK_FAIL}" -gt 0 ]]; then
    echo "[WARN] 共发现 ${LINK_FAIL} 处内部链接目标缺失（仅警告，不阻塞打包）"
fi

# ---------- 统计 ----------
FILE_COUNT="$(find "${STAGING_DIR}/${SKILL_NAME}" -type f | wc -l | tr -d ' ')"
TOTAL_BYTES="$(find "${STAGING_DIR}/${SKILL_NAME}" -type f -exec wc -c {} + | tail -n1 | awk '{print $1}')"

echo "----------------------------------------------------------------"
echo " 打包文件数  : ${FILE_COUNT}"
echo " 打包总字节  : ${TOTAL_BYTES}"
echo "----------------------------------------------------------------"

# ---------- 实际打包 ----------
if [[ "${DO_ZIP}" -eq 1 ]]; then
    if ! command -v zip >/dev/null 2>&1; then
        echo "[ERROR] 系统未安装 zip，无法生成 zip 包" >&2
        echo "        Debian/Ubuntu: sudo apt-get install -y zip" >&2
        echo "        macOS        : 系统自带；CentOS: sudo yum install -y zip" >&2
        exit 4
    fi
    (cd "${STAGING_DIR}" && zip -qr "${ZIP_PATH}" "${SKILL_NAME}")
    rm -rf "${STAGING_DIR}"

    ZIP_SIZE="$(wc -c <"${ZIP_PATH}" | tr -d ' ')"
    ZIP_SHA="$(command -v sha256sum >/dev/null 2>&1 && sha256sum "${ZIP_PATH}" | awk '{print $1}' || shasum -a 256 "${ZIP_PATH}" | awk '{print $1}')"

    echo "✅ 打包成功"
    echo "  路径   : ${ZIP_PATH}"
    echo "  大小   : ${ZIP_SIZE} bytes"
    echo "  SHA256 : ${ZIP_SHA}"
    echo ""
    echo "包内目录结构（前 50 项）："
    unzip -l "${ZIP_PATH}" | sed -n '1,55p'
else
    echo "✅ 仅校验模式（--no-zip）通过；staging 目录: ${STAGING_DIR}"
fi
