#!/bin/bash
set -e

ZIP_DIR_PATH="$(dirname "$0")/zip"


mkdir -p "$ZIP_DIR_PATH"

while IFS=$'\t' read -r file_name region province wmit_url igm_url igm_date ; do 
    file_path="$ZIP_DIR_PATH/$file_name"
    if [[ -f "$file_path" ]]; then
        #echo "===> '$file_path' ('$province','$region') is already downloaded"
        echo "===> $province OK"
    elif [[ "$province" != "Province" && ( -z "$1" || "$province" == "$1" ) ]]; then
        echo "===> Downloading '$file_path' ('$province','$region') from $wmit_url"
        curl --fail --output "$file_path" "$wmit_url" && \
            echo "===> Download of '$file_path' ('$province','$region') completed" || \
            echo "===> Download of '$file_path' ('$province','$region') failed"
    fi
done < ./dbsn.tsv

echo "===> Download in $ZIP_DIR_PATH completate"