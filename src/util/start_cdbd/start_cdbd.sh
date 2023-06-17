#!/bin/sh

BASEDIR=/usr/local/oberon
BINDIR=$BASEDIR/bin
CDBDDIR=$BASEDIR/var/cdbd
CDBDIR=/pub/cdb/oberon
ONS_ROOT=127.0.0.1:9880
export ONS_ROOT

cd $CDBDDIR || exit 1

$BINDIR/onsmkdir -p $CDBDIR || exit 1

exec >>cdbd.LOG 2>&1

echo
echo start of cdbd at `date`
nohup $BINDIR/cdbd -w write -b $CDBDIR oberon.db &
$BINDIR/onswait $CDBDIR/cdbd
