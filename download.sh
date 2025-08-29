#!/bin/bash
set -e

# Usage: ./download.sh [<nome_regione_o_provincia>]

AREA_NAME="$1"

ZIP_DIR_PATH="$(dirname "$0")/zip"


mkdir -p "$ZIP_DIR_PATH"

while IFS=$'\t' read -r file_name region province wmit_url igm_url igm_date ; do
    if [[ "$province" == "Province" ]]; then
        # Skip header line
        continue
    fi

    if [[ -n "$AREA_NAME" && "$province" != "$AREA_NAME" && "$region" != "$AREA_NAME" ]]; then
        echo "===> $region / $province: SKIPPED"
        continue
    fi

    file_path="$ZIP_DIR_PATH/$file_name"
    if [[ -f "$file_path" ]]; then
        echo "===> $region / $province: Already downloaded in '$file_path'"
    else
        echo "===> $region / $province: Downloading from $wmit_url"
        curl --fail --output "$file_path" "$wmit_url" && \
            echo "===> $region / $province: Download of '$file_path' COMPLETED" || \
            echo "===> $region / $province: Download of '$file_path' FAILED"
    fi
done < ./dbsn.tsv

echo "===> Download in $ZIP_DIR_PATH completed"