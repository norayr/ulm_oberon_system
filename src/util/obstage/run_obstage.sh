#!/bin/sh
#------------------------------------------------------------------------------
# to be called for a finished stage to run it to prepare for the next stage
# parameters:
# - stagedir (as left by mk_obstage)
# - ibindir (directory with shipped binaries)
# - onsroot (to be used for the _new_ name system)
#------------------------------------------------------------------------------
cmdname=`basename $0`
usage="Usage: $cmdname stagedir ibindir onsroot"
if [ $# -ne 3 ]
then
   echo >&2 "$usage"; exit 1
fi

stagedir="$1"; shift
ibindir="$1"; shift;
onsroot="$1"; shift;

ONS_ROOT="$onsroot"
export ONS_ROOT

BINDIR="$stagedir"
export BINDIR

CDBDIR=/pub/cdb/oberon
export CDBDIR

mkdir -p "$stagedir"/var/pons
PONSDIR="$stagedir"/var/pons $ibindir/start_pons

mkdir -p "$stagedir"/var/cdbd
CDBDDIR="$stagedir"/var/cdbd
export CDBDDIR
$ibindir/start_cdbd

DBAUTH="$CDBDDIR/write" $ibindir/load_libsources
