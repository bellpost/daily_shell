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


function start(){
    for cmd in ${arr[@]} ;do
    if [ -d ${cmd} ]
    then
        cd ${cmd}
        if [ -f ./startup.sh ]
        then
            if [ -x  ./startup.sh ]
            then
                ./startup.sh
                echo "${cmd} 已启动 "
            else
                echo "[ERROR] : startup.sh 无可执行权限"

            fi
        elif  [ -f ./start.sh ]
        then
            if [ -x  ./start.sh ]
            then
                ./start.sh
                echo "${cmd} 已启动 "
            else
                echo "[ERROR] : start.sh 无可执行权限"
            fi
        else
            echo "[ERROR] : 不存在启动脚本 start.sh或startup.sh"
        fi
    else
        echo "[ERROR] : ${cmd} 不存在这个路径"
    fi
    done
}


function stop(){
    for cmd in ${arr[@]} ;do
    if [ -d ${cmd} ]
    then
        cd ${cmd}
        if [ -f ./shutdown.sh ]
        then
            if [ -x  ./shutdown.sh ]
            then
                ./shutdown.sh
                echo "${cmd} 已停止 "
            else
                echo "[ERROR] : shutdown.sh 无可执行权限"

            fi
        elif  [ -f ./stop.sh ]
        then
            if [ -x  ./stop.sh ]
            then
                ./stop.sh
                echo "${cmd} 已停止 "
            else
                echo "[ERROR] : stop.sh 无可执行权限"
            fi
        else
            echo "[ERROR] : 不存在启动脚本 stop.sh或shutdown.sh"
        fi
    else
        echo "[ERROR] : ${cmd} 不存在这个路径"
    fi
    done
}


option="${1}"
case ${option} in
    -start|start) echo "starting...."
    start
    ;;
    -stop|stop) echo "shutdown...."
    stop
    ;;
    -restart|restart) echo "shutdown...."
    stop
    echo "starting...."
    start
    ;;
   *)
      echo "`basename ${0}`:usage: [-start|start] | [-stop|stop] | [-restart|restart]"
      exit 1
      ;;
esac



