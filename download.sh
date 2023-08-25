#!/bin/bash
set -e

ZIP_DIR_PATH="../zip"


mkdir -p "$ZIP_DIR_PATH"

while IFS=$'\t' read -r file_name region province igm_url ; do 
    if [[ -f "$ZIP_DIR_PATH/$file_name" ]]; then
        echo "===> '$file_name' ('$province','$region') is already downloaded"
    elif [[ "$province" != "Province" && ( -z "$1" || "$province" == "$1" ) ]]; then
        echo "===> Downloading '$file_name' ('$province','$region') from $igm_url"
        curl --fail --output "$ZIP_DIR_PATH/$file_name" "$igm_url" && \
            echo "===> Download of '$file_name' ('$province','$region') completed" || \
            echo "===> Download of '$file_name' ('$province','$region') failed"
    fi
done < ./dbsn.tsv

echo "===> Download in $ZIP_DIR_PATH completate"