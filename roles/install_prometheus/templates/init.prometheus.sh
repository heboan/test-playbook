#!/bin/sh
# prometheus init script
#
# heboan@qq.com 2020-11-10


PATH=/usr/local/sbin:/usr/local/bin:/sbin:/bin:/usr/sbin:/usr/bin
NAME=prometheus

RTDIR=`cd $(dirname $0);pwd`
DAEMON=$RTDIR/prometheus
PROMETHEUS_LOG_DIR={{ prometheus_log_dir }}
PROMETHEUS_DATA_DIR={{ prometheus_data_dir }}

PARMS="--storage.tsdb.retention=15d \
--config.file=$RTDIR/prometheus.yml \
--web.max-connections=512 \
--storage.tsdb.path=$PROMETHEUS_DATA_DIR \
--query.timeout=2m \
--query.max-concurrency=200 \
"

test -x $DAEMON || exit 0
ulimit -n 65535



get_daemon_pid() {
    pid=0
    [ `ps aux | grep $NAME | grep -v grep | grep $PROMETHEUS_DATA_DIR -c` -gt 0 ] && {
       pid=`ps aux | grep $NAME | grep -v grep | grep $PROMETHEUS_DATA_DIR | awk '{ print $2 }'`
    }
    echo $pid
}

is_running() {
    [ `ps aux | grep $NAME | grep -v grep | grep $PROMETHEUS_DATA_DIR -c` -gt 0 ] && return 0
    return 1
}


wait_pid_exit() {
  pid=$1
  count=0
  MAX_WAIT=180
  until [ `ps aux | grep $NAME | grep -v grep | grep $PROMETHEUS_DATA_DIR -c` = "0" ] || [ $count -gt $MAX_WAIT ]
  do
    echo -n "."
    sleep 1
    count=`expr $count + 1`
  done
  
  if [ $count -gt $MAX_WAIT ]; then
    echo "timeout then kill"
    kill -9 $pid  2>/dev/null
  fi
}



do_start() {
    su {{ user }} -s /bin/sh -c "$DAEMON $PARMS >$PROMETHEUS_LOG_DIR/$NAME.log 2>&1 &"
    sleep 1
    is_running && return 0
    return 1
}

do_stop() {
    is_running && { pid=$(get_daemon_pid); kill $pid; }
    sleep 1
    pid=$(get_daemon_pid)
    wait_pid_exit $pid
    return 0
}

do_restart() {
    is_running && do_stop
    do_start || return 2
    return 0
}

case "$1" in
    start)
        is_running && { echo "$NAME is already running."; exit 0; }
        echo "Starting $NAME ..."
        do_start || { echo "!!! failed to start."; exit 2; }
        echo "started."
        ;;
    stop)
        is_running || { echo "$NAME isn't running."; exit 0; }
        echo -n "Stopping $NAME ..."
        do_stop
        echo "done"
        ;;
    restart)
        echo "Restarting $NAME ..."
        do_restart || { echo "failed to restart."; exit 2; }
        echo "restarted"
        ;;
    status)
        if is_running; then
            echo "$NAME is runing (pid=$(get_daemon_pid))"
        else
            echo "$NAME isn't running"
        fi
        ;;
    *)
        echo "Usage: $0 {start|stop|status|restart}"
        exit 2
esac
