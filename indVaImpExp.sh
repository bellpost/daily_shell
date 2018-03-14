#!/usr/bin/env bash
# hbase表的导入导出脚本
# @Time    : 2017/12/10 12:53
# @Author  : bellpost
# @Email   : bellpost@qq.com
# @File    : indVaImpExp.sh
# @Software: PyCharm

#
#默认配置项-------------------
export HBASETABLE='INDICATOR_VALUE'
export SAVEHDFSDIR='/db/'
export COPYTOHDFSDIR='/db/'
#取今天的日期
todayStr=`date -d "now" +%Y%m%d`
#取昨天的日期
#yesterdayStr=`date -d "yesterday" +%Y%m%d`
#-------------------------

declare -a arr=('hadoop' 'hbase' 'tar' 'mv')
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

#检查本地文件存储路径，不存在则创建
function checkDir() {
    if [[  -d  ${1}  ]];
    then
        echo "[info]: ==========${1} Exist! ======="
        return 0
    else
       if [[ !${2} ]] && [[ ${2} == "-pv" ]] ;
       then
            echo "[info]: =======创建Files --> ${2} =========="
            mkdir -pv $1
        fi
        echo "[ERROR] :========== ${1} not Exist! EXIT ======="
        exit 1
    fi
}

#检查本地文件存储路径
function checkDirReturn() {
    if [[  -d  ${1}  ]];
    then
        echo "[info]: ==========${1} Exist! ======="
        return 1
    else
        echo "[info] :========== ${1} not Exist! EXIT ======="
        return 0
    fi
}

#检查本地文件存储路径，不存在则创建
function checkFile() {
    if [[  -f  ${1}  ]];
    then
        echo "[info]: ==========${1} Exist! ======="
        return 0
    else
       if [[ !${2} ]] && [[ ${2} == "-pv" ]] ;
       then
            echo "[info]: =======创建File --> ${2} =========="
            touch $1
        fi
        echo "[ERROR] :========== ${1} not Exist! EXIT ======="
        exit 1
    fi
}

#检查本地文件存储路径
function checkFileReturn() {
    if [[  -f  ${1}  ]];
    then
        echo "[info]: ==========${1} Exist! ======="
        return 1
    else
        echo "[info] :========== ${1} not Exist! EXIT ======="
        return 0
    fi
}

#压缩文件
function tarFiles(){
    # $1-->路径  $2-->文件夹名  $3==-rmrf-->是否删除源文件
    checkDir ${1}
    checkDir ${1}${2}
    echo "[info]: ==========开始压缩文件 --> ${2} ======="
    cd ${1}
    if [[  -d ${2} ]] ;
    then
        ${TAR} -czf ${2}".tar.gz" ${2}
        if [[ $? -ne 0 ]] ;
        then
            echo "[ERROR] :=======压缩失败,脚本退出！======="
            exit 1
        else
            echo "[info]: ==========压缩完成File --> ${2}.tar.gz =========="
        fi
        if [[ !${3} ]] && [[ ${3} == "-rmrf" ]] ;then
            rm -rf ${1}${2}
            echo "[info]: =======删除Files --> ${2} =========="
        fi
    fi
}

#检查HDFS存储路径，不存在则创建
function checkHDFSDir() {
    ${HADOOP} fs -test -e $1
    if [[ ${?} -eq 0 ]] ;
    then
        echo "[info]: HDFS File Directory $1 Exist!"
    else
        if [[  !${2} ]] && [[ ${2} == "-pv" ]] ;then
            echo '[info]: ==========HDFS Directory is not exist，Create HDFS Directory --> ${1} =========='
            ${HADOOP} fs -mkdir -p ${1}
        fi
        echo "[ERROR] :==========HDFS Directory is not exist,EXIT ======="
        exit 1
    fi
}

#检查HDFS存储路径
function checkHDFSDirReturn() {
    ${HADOOP} fs -test -e $1
    if [[ ${?} -eq 0 ]] ;
    then
        echo "[info]: HDFS File Directory $1 Exist!"
        return  1
    else
        echo "[info] :==========HDFS Directory is not exist ======="
        return 0
    fi
}


#导出hbase表及生成的HDFS文件
function Exp(){
    checkHDFSDir ${SAVEHDFSDIR} -pv
    echo "[info]: ==========开始导出到HDFS --> indval$todayStr 指标文件======="
    ${HBASE} org.apache.hadoop.hbase.mapreduce.Driver export ${HBASETABLE} ${SAVEHDFSDIR}"indval"${todayStr} >>  indvalBak${todayStr}.log 2>&1
    if [[  ${?} -eq 0 ]] ;then
        echo "[info]: ==========导出到HDFS成功！==========="
    else
        echo "[ERROR]: ==========导出到HDFS失败！查看日志 indvalBak${todayStr}.log==========="
        exit 1
    fi
    checkDir ${SAVEDIR} -pv
    echo "[info]: ==========开始导出到本地文件系统 --> indval$todayStr 指标文件======="
    cd ${SAVEDIR}
    ${HADOOP} fs -copyToLocal ${SAVEHDFSDIR}"indval"${todayStr} ${SAVEDIR}"indval"${todayStr}  >> indvalBak${todayStr}.log 2>&1
    if [[  ${?} -eq 0 ]] ;then
        echo "[info]: ==========导出到本地文件系统成功！==========="
        return 0
    else
        echo "[ERROR]: ==========导出到本地文件系统失败！查看日志 indvalBak${todayStr}.log ==========="
        exit 1
    fi
}

function Imp(){
    # $1-->导入表名  $2-->文件夹名
    checkHDFSDir ${COPYTOHDFSDIR} -pv
    echo "[info]: ==========开始导入到HDFS ${2}======="
    ${HADOOP} fs -copyFromLocal ${LOCALFSDIR}${2} ${COPYTOHDFSDIR}${2}   >> indvalImp${todayStr}.log 2>&1
    if [[  ${?} -eq 0 ]] ;then
        echo "[info]: ==========HDFS文件导入成功！ ==========="
    else
        echo "[ERROR]: ==========HDFS文件导入失败！查看日志indvalImp${todayStr}.log==========="
        exit 1
    fi
    echo "[info]: ==========开始导入到hbase表 --> ${1} ======="
    ${HBASE} org.apache.hadoop.hbase.mapreduce.Driver import ${1} ${COPYTOHDFSDIR}${2}    >> indvalImp${todayStr}.log 2>&1
    if [[  ${?} -eq 0 ]] ;then
        echo "[info]: ==========指标表导入成功！==========="
        return 0
    else
        echo "[ERROR]: ==========指标表导入失败！查看日志indvalImp${todayStr}.log==========="
        exit 1
    fi
}


option="${1}"
case ${option} in
    -exp)
        echo "[info]: EXP Starting...."
        init
        if test -z ${2}
        then
            export SAVEDIR='./'
        else
            export SAVEDIR="${2}"
        fi
        Exp
        if [[  ${?} -eq 0 ]] ;then
            tarFiles ${SAVEDIR} "indval"${todayStr} -rmrf
        fi
        ;;
    -imp)
        echo "[info]: IMP Starting...."
        init
        if test -z ${4}
        then
            export LOCALFSDIR='./'
        else
            export LOCALFSDIR="${4}"
        fi
        echo "[info] 默认存储导出文件路径 --> ${LOCALFSDIR}"
        if [[  ! ${2} ]] && [[ ! ${3} ]] ;then
            echo "`basename ${0}`:usage: [[-exp]] | [[-imp HBASETABLENAME DIRECTORY]] "
            echo "`basename ${0}`-imp INDICATOR_VALUE_CQ_TOCC indval20171210"
        else
            checkDir ${LOCALFSDIR}
            checkFile ${LOCALFSDIR}${3}".tar.gz"
            if [[ ${?} -eq 0 ]] && [[ ! -d ${LOCALFSDIR}${3} ]] ; then
                echo "[info] :==== 解压文件 --> ${3}".tar.gz"====="
                tar xf ${LOCALFSDIR}${3}".tar.gz"
            fi
            checkDir ${LOCALFSDIR}${3}
        fi
        Imp ${2} ${3}
        ;;
    -expclear)
        echo "[info]: Clear Starting...."
        export range=`date -d "now" +%M%S`
        init
        if test -z ${2}
        then
            export LOCALFSDIR='./'
        else
            export LOCALFSDIR="${2}"
        fi
        checkFileReturn ${LOCALFSDIR}"indval"${todayStr}".tar.gz"
        if [[  ${?} -eq 1 ]] ;then
            echo "[info]: Clear ${LOCALFSDIR}indval${todayStr}.tar.gz --> ${LOCALFSDIR}indval${todayStr}.tar.gz_${range}_tmp"
            ${MV} ${LOCALFSDIR}"indval"${todayStr}".tar.gz" ${LOCALFSDIR}"indval"${todayStr}".tar.gz"${range}"_tmp"
        fi
        checkDirReturn ${LOCALFSDIR}"indval"${todayStr}
        if [[  ${?} -eq 1 ]] ;then
            echo "[info]: Clear ${LOCALFSDIR}indval${todayStr} --> ${LOCALFSDIR}indval${todayStr}${range}_tmp"
            ${MV} ${LOCALFSDIR}"indval"${todayStr} ${LOCALFSDIR}"indval"${todayStr}${range}"_tmp"
        fi
        checkHDFSDirReturn ${SAVEHDFSDIR}"indval"${todayStr}
        if [[  ${?} -eq 1 ]] ;then
            echo "[info]: Clear HDFS ${LOCALFSDIR}indval${todayStr} --> ${LOCALFSDIR}indval${todayStr}${range}_tmp"
            ${HADOOP} fs -mv ${SAVEHDFSDIR}"indval"${todayStr} ${SAVEHDFSDIR}"indval"${todayStr}${range}"_tmp"
        fi
        echo "[info]: Clear Over...."
    ;;
    *)
      todayStr=`date -d "now" +%Y%m%d`
      echo "`basename ${0}`:usage: [-exp DIRECTORY ] | [-imp HBASETABLENAME DIRECTORY] "
      echo "例1： `basename ${0}` -exp"
      echo "例2： `basename ${0}` -exp /home/XX/"
      echo "[info]: 导入的基础路径默认为/home/tongtu/，如需修改，修改脚本LOCALFSDIR变量"
      echo "例2：`basename ${0}` -imp INDICATOR_VALUE_XX indval20171210"
      echo "[info]: hadoop hbase log文件为当前目录下indvalImp${todayStr}.log,indvalBak${todayStr}.log "
      exit 1
      ;;
esac
