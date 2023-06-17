#!/bin/sh

BASEDIR=/usr/local/oberon
BINDIR=$BASEDIR/bin
PONSDIR=$BASEDIR/var/pons
CDBDIR=/pub/cdb/oberon
ONS_ROOT=127.0.0.1:9880
export ONS_ROOT

cd $PONSDIR || exit 1

bindto=`echo $ONS_ROOT | sed 's/:/ /'`
nohup $BINDIR/pons -b $bindto pdb >pons.LOG 2>&1 &

# wait for pons to start and attempt to create pub/cdb in case
# it does not exist yet
sleep 2

(
   path=$CDBDIR
   while [ "$path" != "." ] && [ "$path" != "/" ]
   do
      echo $path
      path=`dirname $path`
   done | sed '/^\/*pub$/d' | sort | sed 's/^/mkdir /'
) | $BINDIR/nsh >/dev/null 2>&1
