#!/bin/bash
set -euo pipefail

# ============================================================
# install-deps.sh — OpenResty + APISIX Lua deps portable build
# Runs inside manylinux2014 container.
#
# Env vars:
#   RELEASE_VERSION  — OpenResty version (default: 1.25.3.2)
#   ARCH             — x86_64 or aarch64
#   OUTPUT_DIR       — where to write the tar.xz (default: /workspace/output)
# ============================================================

RELEASE_VERSION="${RELEASE_VERSION:-1.25.3.2}"
ARCH="${ARCH:-x86_64}"
OUTPUT_DIR="${OUTPUT_DIR:-/workspace}"
RPM_VERSION="${RELEASE_VERSION}-1"
RPM_DIST="el7"
LUAROCKS_VERSION="3.12.1"
OPENRESTY_PREFIX="/usr/local/openresty"
LUAROCKS_BIN="${OPENRESTY_PREFIX}/luajit/bin/luarocks"
WORKSPACE="/workspace"
ROCKSPEC_DIR="${WORKSPACE}/rocksspec"

echo "=== Building OpenResty ${RELEASE_VERSION} for ${ARCH} ==="
echo "RPM version: ${RPM_VERSION}"

# ---- Step 1: System dependencies & OpenResty ----
yum install -y yum-utils epel-release
yum-config-manager --add-repo https://openresty.org/package/centos/openresty.repo

yum install -y \
    "openresty-${RPM_VERSION}.${RPM_DIST}.${ARCH}" \
    "openresty-opm-${RPM_VERSION}.${RPM_DIST}" \
    "openresty-resty-${RPM_VERSION}.${RPM_DIST}" \
    && yum clean all

# ---- Step 2: Build & install LuaRocks from source ----
# Auto-detect LuaJIT suffix from the installed OpenResty
LUAJIT_SUFFIX=$(find "${OPENRESTY_PREFIX}/luajit/share/" -maxdepth 1 -type d -name 'luajit-*' 2>/dev/null | head -1 | sed 's|.*/luajit-||')
if [ -z "$LUAJIT_SUFFIX" ]; then
    echo "ERROR: Could not detect LuaJIT suffix. Check OpenResty installation."
    exit 1
fi
echo "Detected LuaJIT suffix: ${LUAJIT_SUFFIX}"

cd /tmp
curl -fSL "https://luarocks.github.io/luarocks/releases/luarocks-${LUAROCKS_VERSION}.tar.gz" \
    -o "luarocks-${LUAROCKS_VERSION}.tar.gz"
tar xzf "luarocks-${LUAROCKS_VERSION}.tar.gz"
cd "luarocks-${LUAROCKS_VERSION}"

./configure \
    --prefix="${OPENRESTY_PREFIX}/luajit" \
    --with-lua="${OPENRESTY_PREFIX}/luajit" \
    --lua-suffix="${LUAJIT_SUFFIX}" \
    --with-lua-include="${OPENRESTY_PREFIX}/luajit/include/luajit-2.1"

make build
make install

cd /tmp
rm -rf "luarocks-${LUAROCKS_VERSION}" "luarocks-${LUAROCKS_VERSION}.tar.gz"

# ---- Step 3: Set environment ----
export PATH="${OPENRESTY_PREFIX}/luajit/bin:${OPENRESTY_PREFIX}/nginx/sbin:${OPENRESTY_PREFIX}/bin:${PATH}"
export LUA_PATH="${OPENRESTY_PREFIX}/deps/?.ljbc;${OPENRESTY_PREFIX}/deps/?/init.ljbc;${OPENRESTY_PREFIX}/deps/?.lua;${OPENRESTY_PREFIX}/deps/?/init.lua;./?.lua;${OPENRESTY_PREFIX}/luajit/share/luajit-${LUAJIT_SUFFIX}/?.lua;/usr/local/share/lua/5.1/?.lua;/usr/local/share/lua/5.1/?/init.lua;${OPENRESTY_PREFIX}/luajit/share/lua/5.1/?.lua;${OPENRESTY_PREFIX}/luajit/share/lua/5.1/?/init.lua"
export LUA_CPATH="${OPENRESTY_PREFIX}/deps/?.so;./?.so;/usr/local/lib/lua/5.1/?.so;${OPENRESTY_PREFIX}/luajit/lib/lua/5.1/?.so;/usr/local/lib/lua/5.1/loadall.so;${OPENRESTY_PREFIX}/luajit/lib/lua/5.1/?.so"

# ---- Step 4: Install Lua dependencies from rockspecs ----
DEPS_PATH="${OPENRESTY_PREFIX}/deps"

echo "=== Installing apisix deps ==="
"${LUAROCKS_BIN}" install "${ROCKSPEC_DIR}/apisix-1.4.1-0.rockspec" \
    --tree="${DEPS_PATH}" --only-deps --local

echo "=== Installing yhgw deps ==="
"${LUAROCKS_BIN}" install "${ROCKSPEC_DIR}/yhgw-master-0.rockspec" \
    --tree="${DEPS_PATH}" --only-deps --local \
    --server=https://luarocks.org/manifests/moorefu

# ---- Step 5: Verify ----
echo "=== Installed packages ==="
"${LUAROCKS_BIN}" list --tree="${DEPS_PATH}"

# ---- Step 6: Package ----
mkdir -p "${OUTPUT_DIR}"
ARTIFACT_NAME="openresty-${RELEASE_VERSION}-linux-glibc2.17-${ARCH}"
echo "=== Packaging ${OPENRESTY_PREFIX} → ${OUTPUT_DIR}/${ARTIFACT_NAME}.tar.xz ==="
tar -cJf "${OUTPUT_DIR}/${ARTIFACT_NAME}.tar.xz" \
    --exclude="${OPENRESTY_PREFIX}/nginx/logs" \
    "${OPENRESTY_PREFIX}"

echo "=== Build complete: $(du -h "${OUTPUT_DIR}/${ARTIFACT_NAME}.tar.xz" | cut -f1) ==="
