#!/bin/sh

BINDIR=/usr/local/oberon/bin

cmdname=`basename $0`
usage="Usage: $cmdname output lib {module}"
if [ $# -lt 3 ]
then
   echo >&2 "$usage"; exit 1
fi
outfile="$1"; shift
lib="$1"; shift

start=`mktemp /tmp/obstartXXXXXX`
trap "rm -f $start" 0
trap "rm -f $start; exit 1" 1 2 15

if $BINDIR/genobrts "$@" | as -32 -o $start
then
   ld -T $BINDIR/oberon-i386.ld -m elf_i386 -o $outfile $start $lib || exit 1
else
   exit 1
fi
