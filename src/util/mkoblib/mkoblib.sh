#!/bin/sh

BINDIR=/usr/local/oberon/bin

cmdname=`basename $0`
usage="Usage: $cmdname builddir"
if [ $# -ne 1 ]
then
   echo >&2 "$usage"
   exit 1
fi

builddir="$1"
shift
cd "$builddir" || exit 1
rm -fr objs *.o
tar xfz tofs.tgz &&
for x in objs/*.tof
do
   out=`basename $x .tof`.o
   $BINDIR/tof2elf -o "$out" "$x" || exit 1
done &&
rm -f libo.a &&
ar q libo.a *.o &&
rm -fr objs *.o
