#!/bin/bash
if [ ! $2 ]; then
    echo "Usage: deploy.sh SERVER_NAME"
else

    SERVICES_HOME=/usr/local/services
    TOMCAT_HOME=$SERVICES_HOME/tomcat-$1

    if [ ! -d "$TOMCAT_HOME" ];then
        echo "$TOMCAT_HOME is not exist"
        echo "prepare tomcat : $1"
        if [ ! -f "$SERVICES_HOME/apache-tomcat-8.5.32.zip" ];then
            echo "download tomcat : $1"
            wget -P $SERVICES_HOME https://dist.apache.org/repos/dist/release/tomcat/tomcat-8/v8.5.32/bin/apache-tomcat-8.5.32.zip > /dev/null
        fi
        echo "unzip tomcat"
        unzip -d $SERVICES_HOME $SERVICES_HOME/apache-tomcat-8.5.32.zip > /dev/null
        echo $SERVICES_HOME/apache-tomcat-8.5.32
        echo $SERVICES_HOME/tomcat-$1
        mv $SERVICES_HOME/apache-tomcat-8.5.32 $SERVICES_HOME/tomcat-$1
        chmod u+x $SERVICES_HOME/tomcat-$1/bin/*.sh
    fi

    if [ ! -d "$TOMCAT_HOME" ];then
        echo "$TOMCAT_HOME create fail"
    fi

    SERVICE_NAME=$1
    SERVICE_PORT=$2
    echo "create shell and env file"
    cat $SERVICES_HOME/tomcat-env.sh |sed -e "s/APP_NAME/$SERVICE_NAME/g" |sed -e "s/APP_PORT/$SERVICE_PORT/g" > $TOMCAT_HOME/conf/tomcat-env.sh
    cat $SERVICES_HOME/tomcat-server.sh | sed -e "s|TOMCAT_ENV|$TOMCAT_HOME|g" > $TOMCAT_HOME/bin/tomcat-server.sh
		chmod u+x $TOMCAT_HOME/bin/tomcat-server.sh
		
    shutdown_port=8005
    ajp_port=8009
    add=`expr $SERVICE_PORT \- 8080`    
    add=`expr $add \* 10`        
    
    echo "修改http端口为${SERVICE_PORT}"
		sed -i 's#<Connector port=".*" protocol="HTTP/1.1"#<Connector port="'${SERVICE_PORT}'" protocol="HTTP/1.1"#g' $TOMCAT_HOME/conf/server.xml
		
		echo "修改shutdown端口为$[shutdown_port + add]"
		sed -i 's#<Server port=".*" shutdown="SHUTDOWN">#<Server port="'$[shutdown_port + add]'" shutdown="SHUTDOWN">#g' $TOMCAT_HOME/conf/server.xml
		
		echo "修改ajp端口为$[ajp_port + add]"
		sed -i 's#<Connector port=".*" protocol="AJP/1.3"#<Connector port="'$[ajp_port + add]'" protocol="AJP/1.3"#g' $TOMCAT_HOME/conf/server.xml    

    warFile=$(ls $SERVICES_HOME/wars/$1 -t | grep "\.war$" |head -1)

    if [ ! $warFile ]; then
        echo "warFile is not exists"
    else
        echo "deploy war : $warFile"
        $TOMCAT_HOME/bin/tomcat-server.sh status
        $TOMCAT_HOME/bin/tomcat-server.sh stop
        rm -rf  $TOMCAT_HOME/webapps/*
        cp $SERVICES_HOME/wars/$1/`ls $SERVICES_HOME/wars/$1 -t | grep "\.war$" |head -1 | xargs` $TOMCAT_HOME/webapps/ROOT.war
        $TOMCAT_HOME/bin/tomcat-server.sh start
    fi
fi
