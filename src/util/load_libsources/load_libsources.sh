#!/bin/sh

BASEDIR=/usr/local/oberon
BINDIR=$BASEDIR/bin
SRCDIR=$BASEDIR/src/oberon
CDBDDIR=$BASEDIR/var/cdbd
CDBDIR=/pub/cdb/oberon
DBAUTH=$CDBDDIR/write
ONS_ROOT=127.0.0.1:9880
export ONS_ROOT

cd $SRCDIR &&
$BINDIR/obci -a $DBAUTH -b $CDBDIR \
   -sys sys -sys unixsys -sys ulmsys -sys i386sys \
   *.o[dm]
