#!/usr/bin/env bash
set -Eeuo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"
ARTIFACTS="$ROOT/artifacts"
TOOLCHAINS="$ROOT/toolchains"
MODE="${1:-all}"
JOBS="$(sysctl -n hw.ncpu)"
LLVM_COMMIT="8dfdcc7b7bf66834a761bd8de445840ef68e4d1a"
MINGW_VERSION="20260421"
MINGW_SHA256="bd85a3975723815cef28dbbd2ca2cb0c926f6b348a12a0453f39f7af273cb3f7"

mkdir -p "$ARTIFACTS" "$TOOLCHAINS"
stage() { printf '\n\n===== %s =====\n' "$1"; }
if [[ "$MODE" != all && "$MODE" != toolchains && "$MODE" != runtime && "$MODE" != package ]]; then
    echo "usage: $0 [all|toolchains|runtime|package]" >&2
    exit 2
fi

if [[ "$MODE" != package ]]; then
stage "Host tools and pinned llvm-mingw"
brew install autoconf automake bison ccache cmake libtool meson ninja pkg-config xz
export PATH="$(brew --prefix bison)/bin:$(brew --prefix llvm 2>/dev/null || true)/bin:$PATH"
xcodebuild -downloadComponent MetalToolchain
fi

MINGW_ARCHIVE="$TOOLCHAINS/llvm-mingw-$MINGW_VERSION-ucrt-macos-universal.tar.xz"
MINGW_DIR="$TOOLCHAINS/llvm-mingw-$MINGW_VERSION-ucrt-macos-universal"
if [[ "$MODE" == all || "$MODE" == toolchains ]]; then
stage "Fetch pinned llvm-mingw"
if [[ ! -d "$MINGW_DIR" ]]; then
    curl --fail --location --retry 3 \
      "https://github.com/mstorsjo/llvm-mingw/releases/download/$MINGW_VERSION/llvm-mingw-$MINGW_VERSION-ucrt-macos-universal.tar.xz" \
      --output "$MINGW_ARCHIVE"
    echo "$MINGW_SHA256  $MINGW_ARCHIVE" | shasum -a 256 --check
    tar -xJf "$MINGW_ARCHIVE" -C "$TOOLCHAINS"
    rm -f "$MINGW_ARCHIVE"
fi
export PATH="$MINGW_DIR/bin:$PATH"

stage "Pinned LLVM headers and static libraries for DXMT"
LLVM_SOURCE="$TOOLCHAINS/llvm-project"
LLVM_HOST="$TOOLCHAINS/llvm-host-build"
LLVM_IOS="$TOOLCHAINS/llvm-ios-build"
if [[ ! -d "$LLVM_SOURCE/.git" ]]; then
    git clone --filter=blob:none --no-checkout https://github.com/llvm/llvm-project.git "$LLVM_SOURCE"
fi
git -C "$LLVM_SOURCE" fetch --depth=1 origin "$LLVM_COMMIT"
git -C "$LLVM_SOURCE" checkout --detach FETCH_HEAD

# The Apple iOS SDK branch in AddLLVM must select ld's -dead_strip option.
python3 - "$LLVM_SOURCE/llvm/cmake/modules/AddLLVM.cmake" <<'PY'
from pathlib import Path
import sys
p = Path(sys.argv[1])
s = p.read_text()
old = 'MATCHES "Darwin"'
new = 'MATCHES "Darwin|iOS"'
count = s.count(old)
if count != 2:
    raise SystemExit(f"expected two LLVM AddLLVM.cmake Darwin matches, found {count}")
p.write_text(s.replace(old, new))
PY

cmake -S "$LLVM_SOURCE/llvm" -B "$LLVM_HOST" -G Ninja \
  -DCMAKE_BUILD_TYPE=Release -DCMAKE_MACOSX_BUNDLE=OFF \
  -DLLVM_TARGETS_TO_BUILD=Native \
  -DLLVM_BUILD_TOOLS=ON -DLLVM_INCLUDE_TESTS=OFF -DLLVM_ENABLE_ZLIB=OFF
cmake --build "$LLVM_HOST" --target llvm-tblgen --parallel "$JOBS"
cmake -S "$LLVM_SOURCE/llvm" -B "$LLVM_IOS" -G Ninja \
  -DCMAKE_SYSTEM_NAME=iOS -DCMAKE_OSX_ARCHITECTURES=arm64 \
  -DCMAKE_MACOSX_BUNDLE=OFF \
  -DCMAKE_OSX_SYSROOT=iphoneos -DCMAKE_OSX_DEPLOYMENT_TARGET=17.0 \
  -DCMAKE_BUILD_TYPE=Release -DLLVM_HOST_TRIPLE=arm64-apple-ios17.0 \
  -DLLVM_DEFAULT_TARGET_TRIPLE=arm64-apple-ios17.0 -DLLVM_TARGET_ARCH=host \
  -DLLVM_TABLEGEN="$LLVM_HOST/bin/llvm-tblgen" -DLLVM_TARGETS_TO_BUILD= \
  -DLLVM_ENABLE_PROJECTS= -DLLVM_BUILD_TOOLS=Off -DLLVM_INCLUDE_TESTS=Off \
  -DLLVM_ENABLE_ZLIB=Off
cmake --build "$LLVM_IOS" --parallel "$JOBS"

stage "Export compiler toolchains for runtime job"
tar -czf "$ARTIFACTS/toolchains-stage.tar.gz" \
  "toolchains/llvm-mingw-$MINGW_VERSION-ucrt-macos-universal" \
  toolchains/llvm-ios-build toolchains/llvm-project/llvm/include
if [[ "$MODE" == toolchains ]]; then
    echo "Toolchain payload created: $ARTIFACTS/toolchains-stage.tar.gz"
    exit 0
fi
fi

if [[ "$MODE" == all || "$MODE" == runtime ]]; then
export PATH="$MINGW_DIR/bin:$PATH"
test -x "$MINGW_DIR/bin/arm64ec-w64-mingw32-clang"
test -f toolchains/llvm-ios-build/include/llvm/Config/llvm-config.h
stage "Native dependency libraries"
bash build/gnutls-ios/build.sh
bash build/ffmpeg/build.sh

stage "iOS Wine host configuration"
WINE_MACOS="$ROOT/wine/build-macos"
if [[ ! -f "$WINE_MACOS/config.status" ]]; then
    mkdir -p "$WINE_MACOS"
    (cd "$WINE_MACOS" && ../configure --without-x --disable-tests --enable-winegstreamer)
fi

stage "FEX x86-64 and ARM64EC"
bash build/fex-ios/build.sh
bash build/fex-arm64ec/build.sh

stage "Wine unix side, wineserver thread, and ARM64EC PE modules"
bash build/ntdll-unix/build.sh
bash build/wineserver/build.sh
bash build/win32u-unix/build.sh
bash build/wine-pe/build-ntdll.sh
bash build/wine-pe/build-modules.sh

stage "DXMT D3D9/10/11 iOS and Windows sides (D3D12 excluded)"
MADEIRA_ALLOW_NO_D3D12=1 bash build/dxmt-ios/build.sh
xcrun -sdk iphoneos libtool -static -o build/dxmt-ios/libdxmt_combined.a \
  build/dxmt-ios/obj/*.o toolchains/llvm-ios-build/lib/*.a
cp build/dxmt-ios/libdxmt_combined.a app/Madeira/libdxmt_combined.a

if [[ ! -e dxmt/toolchains ]]; then ln -s ../toolchains dxmt/toolchains; fi
(
  cd dxmt
  export SDKROOT="$(xcrun --sdk macosx --show-sdk-path)"
  export PATH="$(pwd)/toolchains/llvm-mingw-$MINGW_VERSION-ucrt-macos-universal/bin:$PATH"
  meson setup build-aarch64-win --cross-file build-aarch64-win.txt \
    --native-file build-osx.txt -Dwine_build_path=../../wine/build-macos
  meson compile -C build-aarch64-win
)
cp dxmt/build-aarch64-win/src/d3d11/d3d11.dll \
   dxmt/build-aarch64-win/src/dxgi/dxgi.dll \
   dxmt/build-aarch64-win/src/winemetal/winemetal.dll \
   dxmt/build-aarch64-win/src/d3d10/d3d10core.dll app/Madeira/aarch64-windows/
meson setup dxmt/build-arm64ec dxmt -Dbuildtype=release \
  -Dwine_build_path=../../wine/build-arm64ec --cross-file=dxmt/build-arm64ec-win.txt
ninja -C dxmt/build-arm64ec src/winemetal/winemetal.dll src/d3d11/d3d11.dll
cp dxmt/build-arm64ec/src/winemetal/winemetal.dll \
   dxmt/build-arm64ec/src/d3d11/d3d11.dll app/Madeira/arm64ec-windows/

stage "32-bit x86 Windows compatibility"
bash build/wine-i386/build.sh
bash build/fex-wow64/build.sh

stage "Madeira Dock and iOS 27 pairing"
bash build/madeira-dock/build.sh
rustup target add aarch64-apple-ios
bash build/rppairing-ios/build.sh
bash build/stage-licenses.sh
fi

if [[ "$MODE" == runtime ]]; then
    stage "Export generated app runtime for the packaging job"
    tar -czf "$ARTIFACTS/runtime-stage.tar.gz" app/Madeira
    echo "Runtime payload created: $ARTIFACTS/runtime-stage.tar.gz"
    exit 0
fi

stage "Unsigned iOS app and IPA"
xcodebuild -resolvePackageDependencies \
  -project app/Madeira.xcodeproj -scheme Madeira
xcodebuild build -project app/Madeira.xcodeproj -scheme Madeira \
  -configuration Debug -sdk iphoneos -destination 'generic/platform=iOS' \
  -derivedDataPath build/DerivedData CODE_SIGNING_ALLOWED=NO \
  CODE_SIGNING_REQUIRED=NO CODE_SIGNING_IDENTITY='' | tee "$ARTIFACTS/xcodebuild.log"

APP="$ROOT/build/DerivedData/Build/Products/Debug-iphoneos/Madeira.app"
test -d "$APP"
if find "$APP" -iname '*metalirconverter*' -o -iname 'd3d12.dll' -o -iname 'madeira_d3d12.dll' | grep -q .; then
    echo "proprietary converter or excluded D3D12 runtime reached the app bundle" >&2
    exit 1
fi
if find "$APP" -iname 'GPTK*' -o -iname '*D3DMetal*' | grep -q .; then
    echo "GPTK/D3DMetal payload reached the app bundle" >&2
    exit 1
fi

PACKAGE="$ROOT/build/package"
rm -rf "$PACKAGE"
mkdir -p "$PACKAGE/Payload"
ditto "$APP" "$PACKAGE/Payload/Madeira.app"
ditto -c -k --keepParent "$PACKAGE/Payload" "$ARTIFACTS/Madeira-unsigned.ipa"
shasum -a 256 "$ARTIFACTS/Madeira-unsigned.ipa" > "$ARTIFACTS/Madeira-unsigned.ipa.sha256"
{
    echo "source=$(git rev-parse HEAD)"
    echo "llvm=$LLVM_COMMIT"
    echo "submodules=$(git submodule status --recursive)"
    echo "xcode=$(xcodebuild -version | tr '\n' ' ')"
    echo "brew=$(brew list --versions | tr '\n' ';')"
    echo "ipa_sha256=$(shasum -a 256 "$ARTIFACTS/Madeira-unsigned.ipa" | cut -d ' ' -f 1)"
} > "$ARTIFACTS/build-manifest.txt"
echo "Unsigned IPA created: $ARTIFACTS/Madeira-unsigned.ipa"
