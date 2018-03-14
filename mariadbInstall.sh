#!/usr/bin/env bash
# 适用于centos7 x86_64
# mariadb安装脚本 版本为10.1.20
# 暂为半成品
# @Time    : 2017/12/10 19:08
# @Author  : bellpost
# @Email   : bellpost@qq.com
# @File    : mariadbInstall.sh
# @Software: PyCharm

DATADIR="/data/mysql_data/mariadb"
SOCKETDIR="/var/lib/mysql/"
PIDDIR="/var/run/mariadb/"
LOGDIR="/var/log/mariadb/"
RPMDIR="./RPM/"
ROOTPASSWD="XX"
USERS="tongtu"
SOURCEDATA="/var/lib/mysql/data"

function checkRoot(){
    if [ `id -u` -ne 0 ]; then
    echo "[WARN]: Please re-run `basename ${0}` as root."
    exit 1
    fi
}

function rpmInstall(){
    export RPM=`which rpm`
    for rpmfile in `ls ${RPMDIR} |grep ".rpm"`; do
        ${RPM} -ivh -force --nodes ${rpmfile}
    done
    export MYSQL_INS=`which mysql_install_db`
    ${MYSQL_INS}  --user=mysql --datadir=${DATADIR}
}

function netYumInstall(){
    export YUM=`which yum`
    if [ -d /etc/yum.repos.d  ] && [ ! -f /etc/yum.repos.d/MariaDB.repo ]; then
    cat > /etc/yum.repos.d/MariaDB.repo << EOF
[mariadb]
name = MariaDB
baseurl = http://yum.mariadb.org/10.1/centos7-amd64
gpgkey=https://yum.mariadb.org/RPM-GPG-KEY-MariaDB
gpgcheck=1
EOF
    else
        echo "[WARN]: 不存在MariaDB网络安装条件"
        exit 1
    fi
    ${YUM} install -y MariaDB-server MariaDB-client
    if [[  ${?} -eq 0 ]] ;then
        echo "[info]: MariaDB install success!"
    fi
    export MYSQL_INS=`which mysql_install_db`
    ${MYSQL_INS}  --user=mysql --datadir=${DATADIR}

}

function mysql_secure(){
    export SYSTEMCTL=`which systemctl`
    export MYSQL_SEC=`which mysql_secure_installation`
    ${SYSTEMCTL} start mysqld.service
    if [[  ${?} -eq 0 ]] ;then
        echo "[info]: MariaDB  安全加固!"
        ${MYSQL_SEC}
    fi

}



function modifyConfig(){
cat > my.cnf << EOF
[mysqld]
datadir=${DATADIR}
socket=${SOCKETDIR}mysql.sock
symbolic-links=0
character_set_server=utf8
lower_case_table_names=1
[mysqld_safe]
log-error=${LOGDIR}mariadb.log
pid-file=${PIDDIR}mariadb.pid
!includedir /etc/my.cnf.d
EOF
}

function rsyncDBData(){
     export RSYNC=`which rsync`
     ${RSYNC} -avz ${SOURCEDATA} ${DATADIR}

}

function startMariaDB(){
     export MYSQLD_SAFE=`which mysqld_safe`
     export PS=`which ps`
     export GREP=`which grep`
     export WC=`which wc`
     ${MYSQLD_SAFE} --defaults-file=/etc/my.cnf  --datadir=${DATADIR} --user=mysql &
     CHECKALIVE=`${ps} -ef |${GREP} mysqld_safe |${GREP} -v grep |${WC} -l`
     if [ CHECKALIVE -eq 1 ]; then
        echo "[info]: mysqld_safe is slive"
     fi

}

function addUser(){
    ${MYSQL} -uroot -p${ROOTPASSWD} <  "grant all privileges on *.* to ${USER}@' Identified by "${PASSWD}";"

}

function modifiyRemote(){
    ${MYSQL} -uroot -p${ROOTPASSWD} < "use mysql;update user set host='%' where host='::1' and user='root';flush privileges;"
    ${MYSQL} -uroot -p${ROOTPASSWD} < "SET GLOBAL table_open_cache=16384; SET GLOBAL table_definition_cache=16384;commit;"
}

function dbIsAlive(){
    result=${MYSQLADMIN} -uroot -p${ROOTPASSWD} ping |awk -F ' ' '{print $3}'
    if [[ ${result} == "alive" ]] ;then
        echo "[info] : mysql is alive"
        return 0
    else
        echo "[WARN]: mysql is dead "
        return 1
    fi
}

function initMaraiDB(){
    if [ -f ./mysql_init.sql ] ; then
        ${MYSQL} -uroot -p${ROOTPASSWD} < ./mysql_init.sql
    fi

}



#checkRoot
#rpmInstall
modifyConfig
addUser
modifiyRemote
dbIsAlive
initMariaDB
