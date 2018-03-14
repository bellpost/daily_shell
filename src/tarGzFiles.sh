#!/usr/bin/env bash
# 多进程压缩文件脚本
# @Time    : 2017/12/11 18:03
# @Author  : bellpost
# @Email   : bellpost@qq.com
# @File    : tarGzFiles.sh
# @Software: PyCharm

PATH1="/XX/"
PATH1="/XX/"

#export yesDate=`date -d "yesterday" +%Y%m%d`
#&& [[ ${floder}!=${yesDate} ]]
export today=`date +%Y%m%d`
export LS=`which ls`
export GREP=`which grep`
export TAR=`which tar`
export DATE=`which date`
export RM=`which rm`

function tarDateFiles(){
    source /etc/profile
    SPATH="${1}"
    cd ${SPATH}
    for floder in `${LS} | ${GREP} -E "20[0-9]{6}$"`
    do
        #[ "${floder}"!="${today}"  ]  
        if [ -d ${floder} ]  && [ ${floder} != ${today} ] ;
        then
            echo "[info]: ==========`${DATE} "+%Y-%m-%d %H:%M:%S"` 开始压缩文件${SPATH}${floder}======="
            ${TAR} -zcf  ${floder}.tar.gz  ${floder}
                if [[  ${?} -eq 0 ]] ;then
                    echo "[info]: ==========文件压缩完成${SPATH}${floder}======="
                    ${RM} -rf ${floder}
                    echo "[info]: ==========文件删除完成${SPATH}${floder}======="
                fi
        fi
    done
}

tarDateFiles ${PATH1} &
tarDateFiles ${PATH1} &
wait
echo "压缩完成"
