function info_echo()
{
    echo "\033[32m $1 \033[0m"
}
function error_echo()
{
    echo "\033[31m $1 \033[0m"
}
function warn_echo()
{
    echo "\033[33m $1 \033[0m"
}
KERNEL_SRC=/Users/xzp/code/linux-3.4.104
TEST_FILE=test.c

header_files=`cat $TEST_FILE|grep "^#include"|cut -d '<' -f 2|cut -d '>' -f 1|cut -d '"' -f 2`
header_list=($header_files)
echo "head files included in $TEST_FILE:"
length=${#header_list[@]}
for((i=0;i<$length;i++))
do
    flag[$i]=0
    echo ${header_list[$i]}
done
echo ""
#构造一个递归函数，输入一个文件名，查询该文件中包含的头文件是否包含了header_list中的头文件
function CheckRepeatIncluded()
{

    checkfile=${1/./\\\.}
    checkfile=${checkfile/\//\\\/}
    #cputype=`uname -p`
    #暂时先不考虑asm开头的头文件
    filefound=`find $KERNEL_SRC -type f|grep \/$checkfile|grep -v "asm"|grep -v "tools"`
    if [ "$filefound" == "" ];then
        #warn_echo "warning:$1 not found"
        return
    fi
    matchfile=($filefound)
    if [ ${#matchfile[@]} -gt 1 ];then
        info_echo "[$0]info:$1 match more than one file:${matchfile[*]}"
        return 
    fi
    echo $filefound-------------------$2
    l_header_files=`cat $filefound|grep "^#include"|cut -d '<' -f 2|cut -d '>' -f 1`
    echo "head files found in $1"
    echo $l_header_files

    l_header_list=($l_header_files)
    for s in ${l_header_list[@]}
    do
        for((j=0;j<$length;j++))
        do
            t=${header_list[$j]}
            if [ "$t" == "$s"  -a  ${flag[$j]} -eq 0 ];then
                error_echo "[$0]error:$t is repeat included in $2->$1"
                flag[$j]=1
                return
            fi
        done
        echo "$2->$1"|grep -q "$s"&>/dev/null
        if [ $? -ne 0 ];then
            CheckRepeatIncluded "$s" "$2->$1" 
        else
            error_echo "[$0]error:loop dependence found $2->$1->$s"
        fi
    done

}
for s in ${header_list[@]}
do
    CheckRepeatIncluded "$s" "$TEST_FILE"
done

