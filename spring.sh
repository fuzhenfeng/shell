#!/bin/bash
source /etc/profile

COMMAND="$1"
APP_NAME=$2
APP_PORT=$3
FILE=$4
JAR_NAME=""

BASE_PATH=$(cd `dirname $0`; pwd)
LOCAL_IP=`ifconfig eth0 |grep "inet addr"| cut -f 2 -d ":"|cut -f 1 -d " "`

init_jms_port(){
    JMX_PORT=11000
    for (( ; JMX_PORT <= 65535; JMX_PORT++ ))
		do
			PORT=`lsof -i:${JMX_PORT}`
			if [ -z "${PORT}" ]; then
				break
			fi
		done
}

is_exist(){
  JAR_NAME=${APP_NAME}".jar"
  PID=`ps -ef|grep ${JAR_NAME}|grep -v grep|grep -v "spring.sh"|awk '{print $2}'`
  if [ -z "${PID}" ]; then
    return 1
  else
    return 0
  fi
}
 
start(){
  is_exist
  if [ $? -eq "0" ]; then
    echo "${JAR_NAME} is already running. Pid is ${PID}"
  else
    chmod 777 ${BASE_PATH}/${JAR_NAME}
    echo "${JAR_NAME} start..."
    init_jms_port
    JAVA_OPTS="-Dname=${APP_NAME} \
    -Xms512m -Xmx512m -Xmn128m -Xss256k \
    -XX:MetaspaceSize=256m -XX:MaxMetaspaceSize=256m \
    -XX:+HeapDumpOnOutOfMemoryError -XX:HeapDumpPath=dump \
    -Duser.dir=${BASE_PATH}
    -Djava.rmi.server.hostname=${LOCAL_IP} \
    -Dcom.sun.management.jmxremote \
    -Dcom.sun.management.jmxremote.authenticate=false \
    -Dcom.sun.management.jmxremote.ssl=false \
    -Dcom.sun.management.jmxremote.port=${JMX_PORT} \
    -Dcom.sun.management.jmxremote.rmi.port=${JMX_PORT}"
    nohup java ${JAVA_OPTS} -jar ${BASE_PATH}/${JAR_NAME} --server.port=${APP_PORT} >> nohup.out 2>&1 &
  fi
}
 
stop(){
  is_exist
  if [ $? -eq "0" ]; then
    	echo "${JAR_NAME} stop..."
	STOP_MSG=`curl -X POST http://${LOCAL_IP}:${APP_PORT}/${APP_NAME}/actuator/shutdown -s`
	echo ${STOP_MSG}
	while true; do
		is_exist
		if [ $? -eq "0" ]; then
			echo "${APP_NAME} stop..."
			sleep 1s
		else
			break
		fi
	done
  else
    	echo "${JAR_NAME} is not running"
  fi
}
 
status(){
  is_exist
  if [ $? -eq "0" ]; then
    echo "${JAR_NAME} is running. Pid is ${PID}"
  else
    echo "${JAR_NAME} is NOT running."
  fi
}

move_old(){
    echo "${JAR_NAME} backup jar..."
    DATE=`date -d today +"%Y%m%d%H%M%S"`
    mv ${BASE_PATH}/${JAR_NAME} ${BASE_PATH}/backup/${DATE}"-"${JAR_NAME}
    if [ $? -eq "0" ]; then
      echo "${JAR_NAME} backup ok"
    else
      echo "${JAR_NAME} backup fail"
    fi
}

move_new(){
    echo "${JAR_NAME} move jar..."
    mv ${FILE} ${BASE_PATH}/${JAR_NAME}
    if [ $? -eq "0" ]; then
      echo "${JAR_NAME} move jar ok"
    else
      echo "${JAR_NAME} move jar fail"
      exit 1
    fi
}
 
restart(){
  stop
  move_old
  move_new
  start
  status
}
 
other() {
    echo "请输入以下命令 [start|stop|restart|status]"
    exit 1
}

case ${COMMAND} in
  "start")
    start
    ;;
  "stop")
    stop
    ;;
  "status")
    status
    ;;
  "restart")
    restart
    ;;
  *)
    other
    ;;
esac
