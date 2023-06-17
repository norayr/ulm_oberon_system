#!/bin/sh

BASEDIR=/usr/local/oberon
BINDIR=$BASEDIR/bin
PONSDIR=$BASEDIR/var/pons
ONS_ROOT=127.0.0.1:9880
export ONS_ROOT

cd $PONSDIR || exit 1

bindto=`echo $ONS_ROOT | sed 's/:/ /'`
nohup $BINDIR/pons -b $bindto pdb >pons.LOG 2>&1 &
sleep 2
