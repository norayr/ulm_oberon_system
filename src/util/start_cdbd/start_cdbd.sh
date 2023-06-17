#!/bin/sh

BASEDIR=/usr/local/oberon
BINDIR=$BASEDIR/bin
CDBDDIR=$BASEDIR/var/cdbd
CDBDIR=/pub/cdb/oberon
INTENSITY=$BASEDIR/etc/intensity/cdbd
ONS_ROOT=127.0.0.1:9880
export ONS_ROOT

cd $CDBDDIR || exit 1

$BINDIR/onsmkdir -p $CDBDIR || exit 1

exec >>cdbd.LOG 2>&1

echo
echo start of cdbd at `date`
options=
if [ -f $INTENSITY ]
then
   options="$options -i `cat $INTENSITY`"
fi
nohup $BINDIR/cdbd $options -w write -b $CDBDIR oberon.db &
$BINDIR/onswait $CDBDIR/cdbd
