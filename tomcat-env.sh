#!/bin/bash
SERVICE_NAME="APP_NAME"
SERVICE_PORT="APP_PORT"
JVM_ID="tomcat-$SERVICE_NAME"
CATALINA_HOME="/usr/local/services/tomcat-$SERVICE_NAME"
JAVA_HOME="/usr/local/services/java1.8"

SERVICE_HOST=`ip route get 8.8.8.8 | awk '{print $NF; exit}'`
JAVA_OPTS="-Djava.security.egd=file:/dev/./urandom"
CATALINA_OPTS="-Djvm=$JVM_ID \
    -server -Xms512m -Xmx512m -Xmn256m -Xss256k \
    -XX:MetaspaceSize=128m -XX:MaxMetaspaceSize=256m \
    -XX:+HeapDumpOnOutOfMemoryError -XX:HeapDumpPath=$CATALINA_HOME/dump \
    -XX:ErrorFile=$CATALINA_HOME/logs/hs_err_%p.log \
    -XX:+DisableExplicitGC \
    -XX:+UseConcMarkSweepGC \
    -XX:+CMSParallelRemarkEnabled \
    -XX:+UseCMSInitiatingOccupancyOnly \
    -XX:CMSInitiatingOccupancyFraction=70 \
    -XX:+UseFastAccessorMethods \
    -Djava.awt.headless=true -Djava.net.preferIPv4Stack=true \
    -Dcontainer.server.region=finance \
    -Dcontainer.app.runMode=server \
    -Dcontainer.app.env=prod \
    -Dcontainer.server.host=$SERVICE_HOST \
    -Dcontainer.server.port=$SERVICE_PORT"

JMX_OPTS="-Dcom.sun.management.jmxremote=true \
    -Dcom.sun.management.jmxremote.ssl=false \
    -Dcom.sun.management.jmxremote.authenticate=false"
CATALINA_OPTS="$CATALINA_OPTS $JMX_OPTS $JAVA_AGENT_OPTS"

