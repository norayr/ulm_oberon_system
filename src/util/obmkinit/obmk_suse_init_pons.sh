#!/bin/sh

BASEDIR=/usr/local/oberon
BINDIR=$BASEDIR/bin
PONSDIR=$BASEDIR/var/pons
ONS_ROOT=127.0.0.1:9880

cmdname=`basename $0`
usage="Usage $cmdname {-b bindto} [-d ponsdir] [-g gid] [-u uid]"

bindto=
root="$ONS_ROOT"
ponsdir="$PONSDIR"
uidgidflags=""
set -- `getopt b:d:g:u: $*`
while [ $# -gt 0 ]
do
   case $1
   in -b)
      bindto="$bindto -b `echo $2 | sed 's/:/ /'`"
      root="$2"
      shift 2
   ;; -d)
      ponsdir="$2"; shift 2
   ;; -g)
      uidgidflags="$uidgidflags -g $2"
      shift 2
   ;; -u)
      uidgidflags="$uidgidflags -u $2"
      shift 2
   ;; --)
      shift; break
   ;; *)
      echo >&2 "$usage"; exit 1
   esac
done

if [ "" = "$bindto" ]
then
   bindto="-b `echo $ONS_ROOT | sed 's/:/ /'`"
fi

echo "#!/bin/sh
#------------------------------------------------------------------------------
# generated by $cmdname at `date`
# PONS (Persistent Oberon Name System)
#------------------------------------------------------------------------------
### BEGIN INIT INFO
# Provides: pons
# Required-Start: \$network \$remote_fs \$named
# Short-Description: Persistent Oberon Name System
# Default-Start: 3 5
# Default-Stop: 0 1 2 6
# Description: PONS (Persistent Oberon Name System) provides the
#    distributed name space that is required by Ulm's Oberon System
### END INIT INFO

start_service() {
   echo -n \"Starting PONS \"
   startproc $uidgidflags -l pons.LOG $BINDIR/pons $bindto pdb
   rc_status -v
}

stop_service() {
   echo -n \"Shutting down PONS \"
   killproc -TERM $BINDIR/pons
   rc_status -v
}

. /etc/rc.status
rc_reset

cd \"$ponsdir\" || exit 1

case \"\$1\"
in start)
   start_service
;; stop)
   stop_service
;; restart)
   stop_service
   start_service
;; status)
   echo -n \"Checking for service PONS \"
   checkproc $BINDIR/pons
   rc_status -v
;; *)
   echo >&2 \"Usage: \$0 start|stop|restart|status\"
esac"