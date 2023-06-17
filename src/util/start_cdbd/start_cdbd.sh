#!/bin/sh

BASEDIR=/usr/local/oberon
BINDIR=$BASEDIR/bin
CDBDDIR=$BASEDIR/var/cdbd
PONSDIR=$BASEDIR/var/pons
CDBDIR=/pub/cdb/oberon
INTENSITY=$BASEDIR/etc/intensity/cdbd
ONS_ROOT=127.0.0.1:9880
CDBD_PORT=127.0.0.1:9882
export ONS_ROOT

cd $CDBDDIR || exit 1

$BINDIR/onsmkdir -a $PONSDIR/write -p $CDBDIR || exit 1

exec >>cdbd.LOG 2>&1

echo
echo start of cdbd at `date`
options=
if [ -f $INTENSITY ]
then
   options="$options -i `cat $INTENSITY`"
fi
bindto=`echo $CDBD_PORT | sed 's/:/ /'`
nohup $BINDIR/cdbd $options \
   -a $PONSDIR/write \
   -w write \
   -B $bindto \
   -b $CDBDIR oberon.db &
$BINDIR/onswait $CDBDIR/cdbd
