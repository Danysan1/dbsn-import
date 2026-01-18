#!/bin/bash
set -e

PREF_WM=0
AREA_SET=1

while getopts "wihad:" flag; do
    case $flag in
        w)
            PREF_WM=1
            ;;
        i)
            PREF_WM=-1
            ;;
        a)
            AREA_SET=0
            ;;
        d)
            DATE=$OPTARG
            ;;
        *) echo -e "\nDBSN Downloader\n\nFlags:\n-w\t\tPrefer WikiMedia downloads\n-i\t\tPrefer IGM downloads\n-a \t\tDownload every file available\n-d <date>\tDownload datasets of specified date in format YYYY-MM-DD\n" && exit;;
    esac
done

ZIP_DIR_PATH="$(dirname "$0")/zip"
shift $((OPTIND - 1))

if [[ $1 && $AREA_SET != 0 ]]; then 
    AREA_NAME=$1
fi

mkdir -p "$ZIP_DIR_PATH"

while IFS=$'\t' read -r region province zip_file_name wmit_url igm_url igm_date latest ; do
    if [[ "$zip_file_name" == "File" || (-z "$DATE" && $latest != "yes") || ( "$DATE" && "$DATE" != $igm_date) ]]; then
        # Skip header line and old files
        # echo "===> $region/$province/$igm_date: SKIPPED"
        continue
    fi

    # ${var,,} makes the value lowercase, used for case insensitive comparison
    if [[ -n "$AREA_NAME" && "${province,,}" != "${AREA_NAME,,}" && "${region,,}" != "${AREA_NAME,,}" && "${zip_file_name:0:2}" != "${AREA_NAME^^}" ]]; then
        # echo "===> $region/$province/$igm_date: SKIPPED"
        continue
    fi

    zip_file_path="$ZIP_DIR_PATH/${zip_file_name:0:2}_$igm_date.zip"
    if [[ -f "$zip_file_path" ]]; then
        echo "===> $region/$province/$igm_date: ZIP Already downloaded in '$zip_file_path'"
    else
        if [[ $PREF_WM == 1 ]]; then
            [[ "$wmit_url" == "TODO" ]] && echo "Wikimedia download not available" || url="$wmit_url"
        elif [[ $PREF_WM == -1 ]]; then
            url="$igm_url"
        elif [[ $PREF_WM = 0 ]]; then
            [[ "$wmit_url" == "TODO" ]] && url="$igm_url" || url="$wmit_url"
        fi
            
        echo "===> $region/$province/$igm_date: Downloading ZIP from $url"
        curl --fail --output "$zip_file_path" "$url" && \
            echo "===> $region/$province/$igm_date: Download of '$zip_file_path' COMPLETED" || \
            echo "===> $region/$province/$igm_date: Download of '$zip_file_path' FAILED"
    fi
done < ./dbsn.tsv

echo "===> Download in $ZIP_DIR_PATH completed"
