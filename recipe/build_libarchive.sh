#!/bin/bash
set -euxo pipefail

if [[ $target_platform =~ linux.* ]]; then
    USE_ICONV=-DENABLE_ICONV=FALSE
else
    USE_ICONV=-DENABLE_ICONV=TRUE
fi

mkdir build-${HOST} && pushd build-${HOST}
cmake .. ${CMAKE_ARGS}                 \
    -DCMAKE_PREFIX_PATH=${PREFIX}      \
    -DCMAKE_INSTALL_PREFIX=${PREFIX}   \
    -DCMAKE_BUILD_TYPE=Release         \
    -DCMAKE_C_FLAGS_RELEASE="$CFLAGS"  \
    -DENABLE_TEST=FALSE                \
    -DENABLE_ZLIB=TRUE                 \
    -DENABLE_BZIP2=TRUE                \
    ${USE_ICONV}                       \
    -DENABLE_LZ4=TRUE                  \
    -DENABLE_LZMA=TRUE                 \
    -DENABLE_LZO=TRUE                  \
    -DENABLE_ZSTD=TRUE                 \
    -DENABLE_CNG=FALSE                 \
    -DENABLE_NETTLE=FALSE              \
    -DENABLE_XML2=TRUE                 \
    -DENABLE_EXPAT=FALSE

make -j${CPU_COUNT}
make install

# see https://github.com/conda-forge/libarchive-feedstock/issues/69
MAJOR_VERSION=$(echo $PKG_VERSION | cut -d. -f1)
MINOR_VERSION=$(echo $PKG_VERSION | cut -d. -f2)
PATCH_VERSION=$(echo $PKG_VERSION | cut -d. -f3)
# Check upstream CMakeLists.txt for details
if [[ $MAJOR_VERSION == 3 ]]; then
    SONAME_BASE=13
else
    echo "MAJOR_VERSION $MAJOR_VERSION not recognized. Update build.sh to specify its SONAME_BASE"
    exit 1
fi
SONAME_VERSION=$(( $SONAME_BASE + $MINOR_VERSION ))

if [[ $target_platform =~ linux.* ]]; then
    ln -s "$PREFIX/lib/libarchive.so.$SONAME_VERSION" "$PREFIX/lib/libarchive.so.$SONAME_BASE.$MINOR_VERSION"
    ln -s "$PREFIX/lib/libarchive.so.$SONAME_VERSION" "$PREFIX/lib/libarchive.so.$SONAME_BASE.$MINOR_VERSION.$PATCH_VERSION"
else
    ln -s "$PREFIX/lib/libarchive.$SONAME_VERSION.dylib" "$PREFIX/lib/libarchive.$SONAME_BASE.dylib"
fi
