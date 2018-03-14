#!/usr/bin/env bash
#
#简易启动关闭脚本 支持startup.sh，start.sh，stop.sh，shutdown.sh
# @Time    : 2017/12/29 09:11
# @Author  : bellpost
# @Email   : bellpost@qq.com
# @File    : autostart.sh
# @Software: PyCharm

#填写服务地址
declare -a arr=('/home/XXX/package1' '/home/XXX/package2')



STARTCMD="startup.sh"
STARTCMD1="start.sh"
STOPCMD="shutdown.sh"
STOPCMD1="stop.sh"

function run(){
    source /etc/profile
    export BASH=`which bash`
    if [ `whoami` = "XX" ]
    then
        echo "[INFO]: 用户为XX用户"
        sleep 1
    else
        echo "[ERROR] :用户不为XX，请用XX用户!程序退出！"
        return 1
    fi
    for dir in ${arr[@]} ;do
        if [ -d ${dir} ]
        then
            cd ${dir}
            if [ -f ${1} ]
            then
                if [ -x ${1} ]
                then
                    ${BASH} ${1}
                    echo "${dir} 下脚本已执行 "
                    sleep 1
                else
                    echo "[ERROR] : ${1} 无可执行权限"
                    return 1
                fi
            elif  [ -f ${2} ]
            then
                if [ -x  ${2} ]
                then
                    ${BASH} ${2}
                    echo "${dir} 下脚本已执行 "
                    sleep 1
                else
                    echo "[ERROR] : ${2} 无可执行权限"
                    return 1
                fi
            else
                echo "[ERROR] : 不存在脚本 ${2}或${1}"
                return 1
            fi
        else
            echo "[ERROR] : ${dir} 不存在这个路径"
            return 1
        fi
    done
}

option="${1}"
case ${option} in
    -start|start) echo "starting...."
    run ${STARTCMD} ${STARTCMD1}
    if [[ $? -ne 0 ]] ;
    then
        echo "[ERROR]: =======执行失败，脚本退出！======="
        exit 1
    fi
    ;;
    -stop|stop) echo "shutdown...."
    run ${STOPCMD} ${STOPCMD1}
    if [[ $? -ne 0 ]] ;
    then
        echo "[ERROR]: =======执行失败，脚本退出！======="
        exit 1
    fi
    ;;
    -restart|restart) echo "shutdown...."
    run ${STOPCMD} ${STOPCMD1}
    if [[ $? -ne 0 ]] ;
    then
        echo "[ERROR]: =======执行失败，脚本退出！======="
        exit 1
    fi
    echo "starting...."
    run ${STARTCMD} ${STARTCMD1}
        if [[ $? -ne 0 ]] ;
    then
        echo "[ERROR]: =======执行失败，脚本退出！======="
        exit 1
    fi
    ;;
   *)
      echo "`basename ${0}`:usage: [-start|start] | [-stop|stop] | [-restart|restart]"
      exit 1
      ;;
esac
