#!/bin/sh

BASEDIR=/usr/local/oberon
BINDIR=$BASEDIR/bin
DBAUTH=$BASEDIR/var/cdbd/write
CDBDIR=/pub/cdb/oberon
INTENSITY=$BASEDIR/etc/intensity/obload

cmdname=`basename $0`
usage="Usage: $cmdname [-a auth] {-b basedir} [-i intensity] [-l loglevel] [-o output] {module}"
if [ $# -eq 0 ]
then
   echo >&2 "$usage"; exit 1
fi

basedirs=
output=
auth="$DBAUTH"
options="-A I386"

intensity=
if [ -f $INTENSITY ]
then
   intensity=`cat $INTENSITY`
fi

set -- `getopt a:b:i:l:o: $*`
while [ $# -gt 0 ]
do
   case $1
   in -a)
      auth="$2"; shift 2
   ;; -b)
      basedirs="$basedirs -b $2"; shift 2
   ;; -i)
      intensity="$2"; shift 2
   ;; -l)
      options="$options -l $2"; shift 2
   ;; -o)
      output="$2"; shift 2
   ;; --)
      shift; break
   esac
done
if [ $# -eq 0 ]
then
   echo >&2 "$usage"; exit 1
fi
if [ "$basedirs" = "" ]
then
   if [ "$OBBASEDIRS" != "" ]
   then
      basedirs=`echo "$OBBASEDIRS" | sed 's/^/-b /; s/:/ -b /g'`
   elif [ "$CDBDIR" != "" ]
   then
      basedirs="-b $CDBDIR"
   fi
fi
options="$options $basedirs"
if [ "$intensity" != "" ]
then
   options="$options -i $intensity"
fi
if [ "$output" = "" ]
then
   output="$1"
fi

tmpdir=`mktemp -d "/tmp/${cmdname}.XXXXXX"`
trap "rm -fr $tmpdir" 0
trap "rm -fr $tmpdir; exit 1" 1 2 15

rtmodules=`$BINDIR/genobrts -r`

umask 077
options="$options -a $auth"
if $BINDIR/obload $options -O $tmpdir/%m.obj -M $* $rtmodules
then
   for f in $tmpdir/*.obj
   do
      b=$tmpdir/`basename $f .obj`
      if $BINDIR/obtofgen -o $b.tof $f &&
	    $BINDIR/tof2elf -o $b.o1 $b.tof &&
	    ld -m elf_i386 -r -o $b.o $b.o1
      then
	 rm -f $b.tof $b.o1
      else
	 exit 1
      fi
   done
   if $BINDIR/genobrts -o $tmpdir/_start.s $* &&
	 as -32 -o $tmpdir/_start.o $tmpdir/_start.s &&
	 ld -m elf_i386 -e _entry -o "$output" $tmpdir/*.o
   then
      exit 0
   else
      exit 1
   fi
else
   exit 1
fi
