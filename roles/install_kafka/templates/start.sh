#! /bin/sh

export JAVA_HOME={{ JAVA_HOME }}
export PATH=$JAVA_HOME/bin:$PATH
export LOG_DIR={{ kafka_log_dir }}
export JMX_PORT=9999
export KAFKA_HEAP_OPTS="-Xmx{{ Xmx }} -Xms{{ Xms }}"


SROOT=`cd $(dirname $0);pwd`
cd $SROOT

./kafka-server-start.sh -daemon ../config/server.properties
