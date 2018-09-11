#!/bin/bash
source /etc/profile

APP_NAME=$2
COMMAND="$1"
BASE_PATH=$(cd `dirname $0`; pwd)

JAVA_OPTS="-Dname=$APP_NAME \
    -Xms512m -Xmx512m -Xmn128m -Xss256k \
    -XX:MetaspaceSize=128m -XX:MaxMetaspaceSize=256m \
    -XX:+HeapDumpOnOutOfMemoryError -XX:HeapDumpPath=dump \
    -XX:+CMSParallelRemarkEnabled \
    -XX:+UseCMSInitiatingOccupancyOnly \
    -XX:CMSInitiatingOccupancyFraction=70 \
    -XX:+UseFastAccessorMethods "

is_exist(){
  NAME=${APP_NAME/.jar/}
  PID=`ps -ef|grep ${NAME}|grep -v grep|grep -v "spring.sh"|awk '{print $2}'`
  if [ -z "${PID}" ]; then
    return 1
  else
    return 0
  fi
}
 
start(){
  is_exist
  if [ $? -eq "0" ]; then
    echo "${APP_NAME} is already running. Pid is ${PID}"
  else
    chmod 777 $APP_NAME
    echo "${APP_NAME} start..."	
    nohup java ${JAVA_OPTS} -jar $APP_NAME >> nohup.out 2>&1 &
    echo "${APP_NAME} start ok"
  fi
}
 
stop(){
  is_exist
  if [ $? -eq "0" ]; then
    echo "${APP_NAME} stop..."
    kill -9 $PID
    if [ $? -eq "0" ]; then
      echo "${APP_NAME} stop ok"
    else
      echo "${APP_NAME} stop fail"
      exit 1
    fi
  else
    echo "${APP_NAME} is not running"
  fi
}
 
status(){
  is_exist
  if [ $? -eq "0" ]; then
    echo "${APP_NAME} is running. Pid is ${PID}"
  else
    echo "${APP_NAME} is NOT running."
  fi
}

move_old(){
    if [ -f "${APP_NAME}" ]; then
      DATE=`date -d today +"%Y%m%d%H%M%S"`
      JAR=`ls ${APP_NAME}`
      echo "${APP_NAME} backup..."
      mv ${JAR} ${BASE_PATH}/backup/${DATE}"-"${JAR}
      if [ $? -eq "0" ]; then
        echo "${APP_NAME} backup ok"
      else
        echo "${APP_NAME} backup fail"
        exit 1
      fi
    else
      echo "${APP_NAME} file is not exit"
    fi
}

move_new(){
    echo "${APP_NAME} move jar..."
    mv ${BASE_PATH}/temp/target/${APP_NAME} ${APP_NAME}
    if [ $? -eq "0" ]; then
      echo "${APP_NAME} move jar ok"
    else
      echo "${APP_NAME} move jar fail"
      exit 1
    fi
}
 
restart(){
  stop
  sleep 2s
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