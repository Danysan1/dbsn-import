#!/bin/bash
set -e

if [[ -z "$1" || -z "$2" ]]; then
    echo "See README.md for usage instructions"
    exit 1
fi

# To understand and find the filters, check out https://wiki.openstreetmap.org/wiki/Italy/DBSN#Data_model
# The list of available layers can be obtained by running ogrinfo on the gdb folder for any province
# Examples of usage:
# ./filter.sh buildings edifc
# ./filter.sh townhalls edifc "edifc_uso = '0201'"
# ./filter.sh police_buildings edifc "edifc_uso = '0306'"
# ./filter.sh hospital_buildings edifc "edifc_uso = '030102'"
# ./filter.sh hospitals pe_uins "pe_uins_ty = '0302'"

OUT_NAME="$1"
GDAL_LAYER="$2"
GDAL_FILTER="$3"
AREA_NAME="$4"

ZIP_DIR_PATH="$(dirname "$0")/zip"
UNZIPPED_DIR_PATH="$(dirname "$0")/unzipped"
TEMP_DIR_PATH="$(dirname "$0")/.temporary_data/$OUT_NAME"
mkdir -p "$TEMP_DIR_PATH"
mkdir -p "$UNZIPPED_DIR_PATH"

while IFS=$'\t' read -r file_name region province wmit_url igm_url igm_date ; do
    if [[ "$file_name" == "File" ]]; then
        # Skip header line
        continue
    fi
    
    if [[ -n "$AREA_NAME" && "$province" != "$AREA_NAME" && "$region" != "$AREA_NAME" ]]; then
        echo "===> $region - $province: SKIPPED"
        continue
    fi

    file_name_no_extension="${file_name%.zip}"
    province_file_path="$TEMP_DIR_PATH/$file_name_no_extension.geojson"
    if [ -f "$province_file_path" ]; then
        echo "===> $region - $province: Already extracted and filtered in '$province_file_path'"
        continue
    fi
    
    province_zip_path="$ZIP_DIR_PATH/$file_name"
    unzipped_dir_path="$UNZIPPED_DIR_PATH/$file_name"
    if [ -e "$unzipped_dir_path" ]; then
        echo "===> $region - $province: Already extracted in '$unzipped_dir_path'"
    else
        echo "===> Extraction of $province_zip_path in $unzipped_dir_path"
        unzip "$province_zip_path" -d "$unzipped_dir_path"
        echo "===> Extraction in $unzipped_dir_path completed"
    fi

    gdb_dir_path="$(find "$unzipped_dir_path" -maxdepth 2 -type d -name '*.gdb')"
    echo "===> Filtering of '$gdb_dir_path' in '$province_file_path'"
    if [[ -z "$GDAL_FILTER" ]]; then
        ogr2ogr -f 'GeoJSON' -t_srs 'EPSG:4326' "$province_file_path" "$gdb_dir_path" "$GDAL_LAYER"
    else
        ogr2ogr -f 'GeoJSON' -t_srs 'EPSG:4326' -where "$GDAL_FILTER" "$province_file_path" "$gdb_dir_path" "$GDAL_LAYER"
    fi
    echo "===> $region - $province: Filtering in '$province_file_path' COMPLETED"
done < ./dbsn.tsv

echo "===> Filtering completed"
