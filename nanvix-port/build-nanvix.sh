#!/bin/bash
# Cross-compile Pillow libImaging for Nanvix (i686)
set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PILLOW_ROOT="$(dirname "$SCRIPT_DIR")"
PYINC="$PILLOW_ROOT/nanvix-port/cpython-headers"
OBJDIR="$PILLOW_ROOT/dist/obj"
DISTDIR="$PILLOW_ROOT/dist"

CC="${CC:-i686-nanvix-gcc}"
AR="${AR:-i686-nanvix-ar}"

CFLAGS="-O2 -fPIC -DNDEBUG -DPILLOW_VERSION=\"11.2.1\" \
  -Wno-unused-function -Wno-unused-variable -Wno-sign-compare \
  -Wno-missing-field-initializers -Wno-unused-parameter \
  -DHAVE_PROTOTYPES -DSTDC_HEADERS \
  -I$PYINC \
  -I$PILLOW_ROOT/src/libImaging"

mkdir -p "$OBJDIR"

echo "[Pillow] Compiling libImaging sources..."

# Compile all libImaging .c files
for src in "$PILLOW_ROOT"/src/libImaging/*.c; do
    base=$(basename "$src" .c)
    obj="$OBJDIR/$base.o"
    echo "  CC $src"
    $CC $CFLAGS -c "$src" -o "$obj"
done

# Compile the Python extension modules
for src in "$PILLOW_ROOT"/src/_imaging.c "$PILLOW_ROOT"/src/_imagingmath.c "$PILLOW_ROOT"/src/_imagingmorph.c; do
    if [ -f "$src" ]; then
        base=$(basename "$src" .c)
        obj="$OBJDIR/$base.o"
        echo "  CC $src"
        $CC $CFLAGS -I"$PILLOW_ROOT/src/libImaging" -c "$src" -o "$obj"
    fi
done

# Also compile codec/display/path helpers if present
for src in "$PILLOW_ROOT"/src/display.c "$PILLOW_ROOT"/src/outline.c \
           "$PILLOW_ROOT"/src/path.c "$PILLOW_ROOT"/src/map.c \
           "$PILLOW_ROOT"/src/decode.c "$PILLOW_ROOT"/src/encode.c \
           "$PILLOW_ROOT"/src/codec_fd.c; do
    if [ -f "$src" ]; then
        base=$(basename "$src" .c)
        obj="$OBJDIR/$base.o"
        echo "  CC $src"
        $CC $CFLAGS -I"$PILLOW_ROOT/src/libImaging" -c "$src" -o "$obj"
    fi
done

echo "[Pillow] Creating static archive..."
mkdir -p "$DISTDIR"
$AR rcs "$DISTDIR/lib_imaging.a" "$OBJDIR"/*.o

echo "[Pillow] Build complete: $DISTDIR/lib_imaging.a ($(du -h "$DISTDIR/lib_imaging.a" | cut -f1))"
