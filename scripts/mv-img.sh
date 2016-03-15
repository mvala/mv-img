#!/bin/bash

MY_EXT_RAW=".ARW"
MY_EXT_JPEG=".JPG"

MY_REMOVE_WK_SPACE=0
MY_CREATE_WK_SPACE=0
MY_SYNC_RAW_FROM_JPEG=0
MY_MOVE_UNUSED_TO_TRASH=0

MY_SRC_DIR=
MY_BASE_DIR=$(readlink -f $(pwd))
MY_WK_DIR=$MY_BASE_DIR/wk
MY_WK_SRC_DIR=$MY_WK_DIR/src
MY_WK_JPEG_DIR=$MY_WK_DIR/jpg
MY_WK_RAW_DIR=$MY_WK_DIR/raw
MY_TRASH_DIR=$MY_WK_DIR/trash

function Help() {
cat <<EOF

!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
Important: Make sure that you are in destination direcotry
!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!

usage: $0 <options> <path to src dir>

OPTIONS:
    -r   Sync Raw files with Jpeg direcotry
    -c   Clean unused files
EOF
}

function ImportDirectory() {
    CreateWorkspace           
}

function CreateWorkspace() {
    [ $MY_REMOVE_WK_SPACE -eq 1 ] && rm -rf $MY_WK_DIR 
    [ -d $MY_WK_SRC_DIR ] || mkdir -p $MY_WK_SRC_DIR
    [ -d $MY_TRASH_DIR ] || mkdir -p $MY_TRASH_DIR
    [ -d $MY_WK_JPEG_DIR ] || mkdir -p $MY_WK_JPEG_DIR
    [ -d $MY_WK_RAW_DIR ] || mkdir -p $MY_WK_RAW_DIR
    cd $MY_WK_SRC_DIR
    exiftool -o dummy -d %Y-%m-%d/%Y%m%d-%H%M%S%%-.2c.%%e "-filename<DateTimeOriginal" $MY_SRC_DIR/*
    for f in $(find $MY_WK_SRC_DIR -type f -name '*'$MY_EXT_JPEG'');do
         fout=${f/$MY_WK_SRC_DIR/$MY_WK_JPEG_DIR}
        [ -d  $(dirname $fout) ] || mkdir -p  $(dirname $fout)
        ln -sfn $f $fout
    done
    cd $MY_BASE_DIR
    SyncRawFromJpeg
}

function SyncRawFromJpeg() {
    echo "I: Sync Raw from Jpeg ..."
    [ -d $MY_WK_RAW_DIR ] || mkdir -p $MY_WK_RAW_DIR

    # remove all raw files
    for f in $(find $MY_WK_RAW_DIR -type l -name '*'$MY_EXT_RAW'');do
        rm -f $f
    done

    for f in $(find $MY_WK_JPEG_DIR -type l -name '*'$MY_EXT_JPEG'');do
        fin=$(readlink -f $f)
        fin=${fin/$MY_EXT_JPEG/$MY_EXT_RAW}
        fout=$(readlink -f $f)
        fout=${fout/$MY_WK_SRC_DIR/$MY_WK_RAW_DIR}
        fout=${fout/$MY_EXT_JPEG/$MY_EXT_RAW}
        [ -d  $(dirname $fout) ] || mkdir -p  $(dirname $fout)
        [ -f $(readlink -f $fin) ] && ln -sfn $fin $fout
    done
}

function MoveUnusedToTrash() {
    echo "I: Moving Unused to Trash ..."
    [ -d $MY_TRASH_DIR ] || mkdir -p $MY_TRASH_DIR
    for f in $(find $MY_WK_SRC_DIR -type f -name '*'$MY_EXT_JPEG'');do
        fout=${f/$MY_WK_SRC_DIR/$MY_WK_JPEG_DIR}
        if [ ! -f $fout ];then
            echo "Removing $f"
            ftrash=${f/$MY_WK_SRC_DIR/$MY_TRASH_DIR}
            [ -d  $(dirname $ftrash) ] || mkdir -p  $(dirname $ftrash)
            mv $f $ftrash
       fi
    done
    for f in $(find $MY_WK_SRC_DIR -type f -name '*'$MY_EXT_RAW'');do
        fout=${f/$MY_WK_SRC_DIR/$MY_WK_RAW_DIR}
        if [ ! -f $fout ];then
            echo "Removing $f"
            ftrash=${f/$MY_WK_SRC_DIR/$MY_TRASH_DIR}
            [ -d  $(dirname $ftrash) ] || mkdir -p  $(dirname $ftrash)
            mv $f $ftrash
        fi    
    done

}

function PrintSummary() {
    NUM_JPEG=$(find $MY_WK_SRC_DIR -type f -name '*'$MY_EXT_JPEG'' | wc -l)
    NUM_RAW=$(find $MY_WK_SRC_DIR -type f -name '*'$MY_EXT_RAW'' | wc -l)
    echo "SRC : JPEG=$NUM_JPEG RAW=$NUM_RAW"
    NUM_JPEG=$(find $MY_WK_JPEG_DIR -type l -name '*'$MY_EXT_JPEG'' | wc -l)
    NUM_RAW=$(find $MY_WK_RAW_DIR -type l -name '*'$MY_EXT_RAW'' | wc -l)
    echo "WK : JPEG=$NUM_JPEG RAW=$NUM_RAW"
    NUM_JPEG=$(find $MY_TRASH_DIR -type f -name '*'$MY_EXT_JPEG'' | wc -l)
    NUM_RAW=$(find $MY_TRASH_DIR -type f -name '*'$MY_EXT_RAW'' | wc -l)
    echo "TRASH : JPEG=$NUM_JPEG RAW=$NUM_RAW"
}


if [ $# -lt 1 ];then
    if [  ! -d $(pwd)/wk ];then
        echo "E: Working directory is missing !!!"
        exit 11
    fi
    PrintSummary
    exit 0
fi

while getopts ":rch" optname
do
    case "$optname" in
        "r")
            MY_SYNC_RAW_FROM_JPEG=1
            ;;
        "c")
            MY_MOVE_UNUSED_TO_TRASH=1
            ;;
        "h")
            Help
            exit 1
            ;;
        "?")
            echo "Unknown option $OPTARG"
	        exit 11
            ;;
        ":")
            echo "No argument value for option $OPTARG"
            ;;
        *)
            # Should not occur
            echo "Unknown error while processing options"
            ;;
    esac
done

shift $(( OPTIND - 1 ));

[ -n "$1" ] && MY_SRC_DIR=$(readlink -f $1)

IS_EXIF=$(which exiftool)
if [ ! $? -eq 0 ];then
    echo "Please install exiftool"
    exit 20
fi

for d in $*;do
    if [ -d $d ];then
        echo "Importing '$d' ..."
        ImportDirectory $d $(pwd) 
    else
        echo "Skipping directory '$d' !!!"
    fi
done
if [  ! -d $(pwd)/wk ];then
    echo "E: Working directory is missing !!!"
    exit 11
fi


if [ -d $MY_WK_DIR ];then
    [ $MY_SYNC_RAW_FROM_JPEG -eq 1 ] && SyncRawFromJpeg
    [ $MY_MOVE_UNUSED_TO_TRASH -eq 1 ] && MoveUnusedToTrash
fi

PrintSummary
