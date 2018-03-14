#!/usr/bin/env bash
# ssh 互信脚本
# @Time    : 2017/12/10 17:33
# @Author  : bellpost
# @Email   : bellpost@qq.com
# @File    : sshTrust.sh
# @Software: PyCharm
#HOSTNAMEARR=([0]=用户名#IP或主机名#端口 )
#配置多台互信如下
HOSTNAMEARR=([0]=XX#IP#PORT [1]=XX#IP#PORT2 )

declare -a arr=('date' 'echo' 'hostname' 'ping' 'ssh-copy-id' 'ssh-keygen')
function init(){
    source ~/.bash_profile;
    for cmd in ${arr[@]} ;do
        TMPSTR=`echo ${cmd} | tr '[a-z]' '[A-Z]'`
        UPCMD=${TMPSTR//"-"/"_"}
        LOWCMD=`echo ${cmd} | tr '[A-Z]' '[a-z]'`
        command -v ${cmd}
        if [[ $? -ne 0 ]] ;
        then
            echo "[ERROR]: =======${cmd}命令不在当前环境中，脚本退出！======="
            exit 1
        fi

        export ${UPCMD}=`which ${LOWCMD}`
    done
    return 0
}




function sshTrust(){
    # $1 --> hostname $2 --> name $3  -->port
    export ALIVEHOST=""
    export DEADHOST=""
    export EXITCODE=""
    #-w 5
    $PING -c 2 ${1}
    EXITCODE=`$ECHO $?`
    if [ $EXITCODE = 0 ]
    then
      ALIVEHOST="$ALIVEHOST ${1}"
    else
      DEADHOST="$DEADHOST ${1}"
    fi

    if test -z "$DEADHOST"
    then
      $ECHO Remote host reachability check succeeded.
      $ECHO The following host is reachable: $ALIVEHOST.
      $ECHO -e "Proceeding further...\n"
    else
      $ECHO Remote host reachability check failed.
      $ECHO The following host is not reachable: $DEADHOST.
      $ECHO -e "Exiting now...\n"
      exit 1
    fi

    $ECHO -e "\nThe Local Host is: "$LOCAL_HOST
    $ECHO -e "The Remote Host is: "${1}"\n"
    $SSH_KEYGEN -t rsa
    #ssh -o 'StrictHostKeyChecking=no' -p ${3} ${2}@${1}
    $SSH_COPY_ID -i ~/.ssh/id_rsa.pub -p ${3} ${2}@${1}
}

function main(){
    TMP=0
    for data in ${HOSTNAMEARR[@]}
    do
        NAME=`echo ${data} | awk  -F '#'  '{print $1}'`
        HOSTNAME=`echo ${data} | awk  -F '#'  '{print $2}'`
        PORT=`echo ${data} | awk  -F '#'  '{print $3}'`
        if test -z "${NAME}"  ||  test -z "${HOSTNAME}" ||  test -z "${PORT}"
        then
            TMP=`expr $TMP + 1`
            echo "[ERROR] : 第${TMP}台机器配置有误！ "
        else
            TMP=`expr $TMP + 1`
            echo "[info] : 第${TMP}台机器：登陆名 -->${NAME}  主机名 -->${HOSTNAME} 端口 --> ${PORT}"
        fi
        sshTrust ${HOSTNAME} ${NAME} ${PORT}
    done
}

init
main
