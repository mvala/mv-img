#!/bin/bash

MY_BASE_DIR=$(readlink -f $(pwd))

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
    exiftool -o dummy -d %Y-%m-%d/%Y%m%d-%H%M%S%%-.2c.%%e "-filename<DateTimeOriginal" $MY_SRC_DIR/*
}

while getopts ":rch" optname
do
    case "$optname" in
        "h")
            Help
            exit 1
            ;;
        "?")
         Help
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

[ -n "$1" ] && MY_SRC_DIR=$(readlink -f $1) || { Help; exit 1; }

IS_EXIF=$(which exiftool)
if [ ! $? -eq 0 ];then
    echo "Please install exiftool"
    exit 20
fi

ImportDirectory

