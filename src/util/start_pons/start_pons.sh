#!/bin/sh

BASEDIR=/usr/local/oberon
BINDIR=$BASEDIR/bin
PONSDIR=$BASEDIR/var/pons
ONS_ROOT=127.0.0.1:9880
export ONS_ROOT
ONS_PORT=127.0.0.1:9881

cd $PONSDIR || exit 1

bindto1=`echo $ONS_ROOT | sed 's/:/ /'`
bindto2=`echo $ONS_PORT | sed 's/:/ /'`
nohup $BINDIR/pons \
   -b $bindto1 -B $bindto2 \
   -w write -s shutdown \
   pdb >pons.LOG 2>&1 &
sleep 2
