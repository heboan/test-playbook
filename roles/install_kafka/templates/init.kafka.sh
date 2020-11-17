#!/bin/sh
# kafka init script
#
# heboan@qq.com 2020-11-10

PATH=/usr/local/sbin:/usr/local/bin:/sbin:/bin:/usr/sbin:/usr/bin
NAME=kafka
DAEMON={{ deployment_dir }}/kafka/bin/start.sh
PIDFILE={{ kafka_data_dir }}/kafka.pid

test -x $DAEMON || exit 0

SROOT={{ deployment_dir }}/kafka
cd $SROOT


[ -f $PIDFILE ] || echo "66666" > $PIDFILE
chown {{ run_user }} $PIDFILE
ulimit -n 100000

get_daemon_pid() {
  _pid=`ps aux | grep java | grep -v grep | grep '{{ kafka_log_dir }}' | awk '{ print $2 }'`
  echo $_pid
}

is_running() {
  [ `ps aux | grep java | grep '{{ kafka_log_dir }}' | wc -l` -gt 0 ] || return 1
  return 0
}

wait_pid_exit() {
  pid=$1
  count=0
  MAX_WAIT=180
  until [ `ps aux | grep java | grep -v grep | grep '{{ kafka_log_dir }}' | wc -l` = "0" ] || [ $count -gt $MAX_WAIT ]
  do
    echo -n "."
    sleep 1
    count=`expr $count + 1`
#    kill $pid 2>/dev/null
  done

  if [ $count -gt $MAX_WAIT ]; then
    echo "timeout then kill"
    kill -9 $pid  2>/dev/null
    sleep 2
    [ `ps aux | grep java | grep '{{ kafka_log_dir }}' | wc -l` -gt 0 ] && killall -9 kafka
  fi
}

do_start() {
    su {{ run_user }} -s /bin/sh -c "exec $DAEMON >/dev/null 2>&1 &"
    is_running || sleep 1 && is_running || sleep 1 && is_running || return 1
    echo `get_daemon_pid` > $PIDFILE
    return 0
}
 
do_stop() {
    pid=`cat $PIDFILE`
    kill $pid
    sleep 1
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
        echo -n "Starting $NAME ..."
        do_start || { echo "failed to start."; exit 2; }
        echo "started"
        ;;
    stop)
        is_running || { echo "$NAME isn't running."; exit 0; }
        echo -n "Stopping $NAME ..."
        do_stop 
        echo "stopped"
        ;;
    restart)
        echo -n "Restarting $NAME..."
        do_restart || { echo "failed to restart."; exit 2; }
        echo "restarted"
        ;;
    status)
        if is_running; then
            echo "$NAME is runing (pid=`cat $PIDFILE`)"
        else
            echo "$NAME isn't running"
        fi
        ;;
    checkconfig)
        check_config 1
        ;;
    *)
        echo "Usage: $(basename $0) {start|stop|status|restart|reload|checkconfig}"
        exit 2
esac
