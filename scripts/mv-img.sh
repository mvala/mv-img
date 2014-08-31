#!/bin/bash

MY_EXT_RAW=".ARW"
MY_EXT_JPEG=".JPG"

MY_REMOVE_WK_SPACE=0
MY_CREATE_WK_SPACE=0
MY_SYNC_RAW_FROM_JPEG=0

MY_SRC_DIR=
MY_BASE_DIR=
MY_WK_DIR=
MY_WK_JPEG_DIR=
MY_WK_RAW_DIR=



function Help() {
cat <<EOF    

usage: $0 <options> <path to src dir>

OPTIONS:
    -r   Sync Raw files with Jpeg direcotry

EOF
}

function CheckSrcDirectory() {
    if [ ! -d $MY_SRC_DIR ];then
        echo "W: Direcotry '$MY_SRC_DIR' doesn't exist. Please create it first !!!"
        exit 20
    fi
}

function CheckWkDirectory() {
    if [ ! -d $MY_WK_DIR ];then
        echo "W: Direcotry '$MY_WK_DIR' doesn't exist. Creating one ..."
        CreateWorkspace
    fi
}

function CreateWorkspace() {
    [ $MY_REMOVE_WK_SPACE -eq 1 ] && rm -rf $MY_WK_DIR
    if [ ! -d $MY_WK_DIR ];then
        mkdir -p $MY_WK_DIR/jpg
        for f in $(find $MY_SRC_DIR -type f -name '*'$MY_EXT_JPEG'');do
            ln -s $f $MY_WK_DIR/jpg/$(basename $f)
        done
    fi
}

function SyncRawFromJpeg() {
    if [ -d $MY_WK_RAW_DIR ];then
        rm $MY_WK_RAW_DIR/*$MY_EXT_RAW
    else
        mkdir -p $MY_WK_RAW_DIR
    fi

    for f in $(find $MY_WK_JPEG_DIR -type l -name '*'$MY_EXT_JPEG'');do
        ftmp=$(readlink -f $f)
        ftmp=${ftmp/$MY_EXT_JPEG/$MY_EXT_RAW}
        [ -f $(readlink -f $ftmp) ] && ln -s $(readlink -f $ftmp) $MY_WK_RAW_DIR/$(basename $ftmp)
    done
}

function PrintSummary() {
    NUM_JPEG=$(find $MY_SRC_DIR -type f -name '*'$MY_EXT_JPEG'' | wc -l)
    NUM_RAW=$(find $MY_SRC_DIR -type f -name '*'$MY_EXT_RAW'' | wc -l)
    echo "SRC : JPEG=$NUM_JPEG RAW=$NUM_RAW"
    NUM_JPEG=$(find $MY_WK_JPEG_DIR -type l -name '*'$MY_EXT_JPEG'' | wc -l)
    [ -d $MY_WK_RAW_DIR ] && NUM_RAW=$(find $MY_WK_RAW_DIR -type l -name '*'$MY_EXT_RAW'' | wc -l) || NUM_RAW=0
    echo "WK : JPEG=$NUM_JPEG RAW=$NUM_RAW"
}

if [ $# -lt 1 ];then
    Help
    exit 10
fi

while getopts ":r:" optname
do
    case "$optname" in
        "r")
            echo "Option $optname is specified"
            MY_SYNC_RAW_FROM_JPEG=1
            shift
            ;;
        "?")
            echo "Unknown option $OPTARG"
            ;;
        ":")
            echo "No argument value for option $OPTARG"
            ;;
        *)
            # Should not occur
            echo "Unknown error while processing options"
            ;;
    esac
    echo "OPTIND is now $OPTIND"
done

if [  "$(basename $1)" != "src" ];then
    echo "E:You have to point to 'src' direcotry !!!"
    exit 11
fi

MY_SRC_DIR=$(readlink -f $1)
MY_BASE_DIR=$(dirname $MY_SRC_DIR)
MY_WK_DIR=$MY_BASE_DIR/wk
MY_WK_JPEG_DIR=$MY_WK_DIR/jpg
MY_WK_RAW_DIR=$MY_WK_DIR/raw

echo "Processing : '$MY_BASE_DIR'"

CheckSrcDirectory
CreateWorkspace

if [ -d $MY_WK_DIR ];then
    [ $MY_SYNC_RAW_FROM_JPEG -eq 1 ] && SyncRawFromJpeg
fi

PrintSummary
