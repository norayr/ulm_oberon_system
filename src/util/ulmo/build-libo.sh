#!/bin/sh
# build-libo.sh -- compile all library modules from source and archive into libo.a
#
# Usage: build-libo.sh BINDIR SRCDIR LIBDIR
#
# Compiles every .om file in SRCDIR using BINDIR/ulmoc, converts each
# mod-I386.obj to a .o via BINDIR/obtofgen + BINDIR/tof2elf, and archives
# all .o files into LIBDIR/libo.a.
#
# Runs in a temporary directory; all output goes to LIBDIR/libo.a.
# Module compilation failures are reported but do not abort the build
# (some architecture-specific or optional modules may not compile).

set -e
set -x
BINDIR="$1"
SRCDIR="$2"
LIBDIR="$3"

if [ -z "$BINDIR" ] || [ -z "$SRCDIR" ] || [ -z "$LIBDIR" ]; then
    echo "Usage: $0 BINDIR SRCDIR LIBDIR" >&2
    exit 1
fi

ULMO_OB="$BINDIR/ulmoc"
OBTOFGEN="$BINDIR/obtofgen"
TOF2ELF="$BINDIR/tof2elf"

for tool in "$ULMO_OB" "$OBTOFGEN" "$TOF2ELF"; do
    if [ ! -x "$tool" ]; then
        echo "build-libo: required tool not found: $tool" >&2
        exit 1
    fi
done

TMPDIR=$(mktemp -d /tmp/ulmo-lib-XXXXXX)
trap "rm -rf $TMPDIR" 0 1 2 15

echo "build-libo: compiling library modules from $SRCDIR ..."
echo "build-libo: output: $LIBDIR/libo.a"
echo "build-libo: build dir: $TMPDIR"

cd "$TMPDIR"

# Compile each .om file.  ulmoc caches .obj files so transitive deps that
# were already compiled by a previous invocation are reused.
failed=0
total=0
for om in "$SRCDIR"/*.om; do
    modname=$(basename "$om" .om)
    total=$((total + 1))
    if ! "$ULMO_OB" -I "$SRCDIR" "$om" >/dev/null 2>&1; then
        echo "  WARNING: $modname: compile failed (skipping)" >&2
        failed=$((failed + 1))
    fi
done
echo "build-libo: compiled $total modules ($failed failed)"

# Convert all mod-I386.obj files to ELF .o via obtofgen + tof2elf.
obj_count=0
for obj in ./*-mod-I386.obj; do
    [ -f "$obj" ] || continue
    modname=$(basename "$obj" -mod-I386.obj)
    toffile="$modname.tof"
    ofile="$modname.o"
    "$OBTOFGEN" -o "$toffile" "$obj" || { echo "build-libo: obtofgen failed for $modname" >&2; exit 1; }
    "$TOF2ELF" -o "$ofile" "$toffile" || { rm -f "$toffile"; echo "build-libo: tof2elf failed for $modname" >&2; exit 1; }
    rm -f "$toffile"
    obj_count=$((obj_count + 1))
done
echo "build-libo: converted $obj_count modules to .o"

# Archive
mkdir -p "$LIBDIR"
rm -f "$LIBDIR/libo.a"
ar q "$LIBDIR/libo.a" ./*.o
echo "build-libo: $LIBDIR/libo.a created ($obj_count modules)"
