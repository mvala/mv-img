#!/bin/bash

MY_EXT_RAW=".ARW"
MY_EXT_JPEG=".JPG"

MY_REMOVE_WK_SPACE=0
MY_CREATE_WK_SPACE=0
MY_SYNC_RAW_FROM_JPEG=1

MY_SRC_DIR=
MY_BASE_DIR=
MY_WK_DIR=
MY_WK_JPEG_DIR=
MY_WK_RAW_DIR=



function Help() {
    echo "$0 <src dir>"
}

function CreateWorkspace() {
    [ $MY_REMOVE_WK_SPACE -eq 1 ] && rm -rf $MY_WK_DIR
    if [ -d $MY_WK_DIR ];then
        echo "W: Direcotry '$MY_WK_DIR' already exists. Please remove it first !!!"
        echo "  rm -rf $MY_WK_DIR"
        exit 21
    fi
    mkdir -p $MY_WK_DIR/jpg
    for f in $(find $MY_SRC_DIR -type f -name '*'$MY_EXT_JPEG'');do
        ln -s $f $MY_WK_DIR/jpg/$(basename $f)
    done    
}

function SyncRawFromJpeg() {
    echo "Removing RAW from JPEG ..."
    rm -rf $MY_WK_RAW_DIR
    mkdir -p $MY_WK_RAW_DIR
    for f in $(find $MY_WK_JPEG_DIR -type l -name '*'$MY_EXT_JPEG'');do
        ftmp=$(readlink -f $f)
        ftmp=${ftmp/$MY_EXT_JPEG/$MY_EXT_RAW}
        [ -f $(readlink -f $ftmp) ] && ln -s $(readlink -f $ftmp) $MY_WK_RAW_DIR/$(basename $ftmp)
    done
}

function PrintSummary() {
    NUM_RAW=$(find $MY_SRC_DIR -type f -name '*'$MY_EXT_RAW'' | wc -l)
    NUM_JPEG=$(find $MY_SRC_DIR -type f -name '*'$MY_EXT_JPEG'' | wc -l)
    echo "SRC : RAW=$NUM_RAW JPEG=$NUM_JPEG"
    NUM_RAW=$(find $MY_WK_RAW_DIR -type l -name '*'$MY_EXT_RAW'' | wc -l)
    NUM_JPEG=$(find $MY_WK_JPEG_DIR -type l -name '*'$MY_EXT_JPEG'' | wc -l)
    echo "WK : RAW=$NUM_RAW JPEG=$NUM_JPEG"
}

if [ ! $# -eq 1 ];then
    Help
    exit 10
fi

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

[ $MY_CREATE_WK_SPACE -eq 1 ] && CreateWorkspace

if [ -d $MY_WK_DIR ];then
    [ $MY_SYNC_RAW_FROM_JPEG -eq 1 ] && SyncRawFromJpeg
else
    echo "W: Working direcotry '' doesn't exist"
fi

PrintSummary
