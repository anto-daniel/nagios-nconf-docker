#!/bin/bash

filename=$1
search=$2
replace=$3

if [  $# != 3 ]; then
    echo "3 arguments reqd.."
    exit 1
fi

if [[ ! -d $filename ]]; then
    echo "1st argument is not a directory...."
    exit 1
fi
cd $filename
grep -r -i -n * > lines
cat lines | while read -r line
do
    fn=$(echo $line | awk -F: '{print $1}')
    ln=$(echo $line | awk -F: '{print $2}')
    sed -i "${ln}s/${search}/${replace}/g" $fn
    if [ $? -ne 0 ]; then
        echo "Not able to replace on line $ln in file $fn"
    fi
    echo "Replaced: ... "
    sed -n "${ln} p" ${fn}
done
rm -rfv lines
