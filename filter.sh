#!/bin/bash
set -e

# To understand and find the filters, check out https://wiki.openstreetmap.org/wiki/Italy/DBSN#Data_model
# The list of available layers can be obtained by running ogrinfo on the gdb folder for any province
# Examples of usage:
# ./filter.sh edifc "\"edifc_uso\" = '0201'" townhalls geojson
# ./filter.sh edifc "\"edifc_uso\" = '030102'" hospital_buildings geojson
# ./filter.sh pe_uins "\"pe_uins_ty\" = '0302'" hospitals geojson

DEFAULT_GDAL_LAYER='edifc'
DEFAULT_GDAL_FILTER="\"edifc_uso\" = '0201'"
DEFAULT_OUT_NAME="townhalls"
DEFAULT_OUT_EXTENSION='geojson'

GDAL_LAYER="${1:-$DEFAULT_GDAL_LAYER}"
GDAL_FILTER="${2:-$DEFAULT_GDAL_FILTER}"
OUT_NAME="${3:-$DEFAULT_OUT_NAME}"
OUT_EXTENSION="${4:-$DEFAULT_OUT_EXTENSION}"

ZIP_DIR_PATH="../zip"
UNZIPPED_DIR_PATH='../unzipped'


TEMP_DIR_PATH="./.temporary_data/$OUT_NAME"
mkdir -p "$TEMP_DIR_PATH"
mkdir -p "$UNZIPPED_DIR_PATH"

for province_zip_path in "$ZIP_DIR_PATH"/*.zip ; do
    base_name="$(basename $province_zip_path)"
    base_name_no_extension="${base_name%.zip}"

    province_file_path="$TEMP_DIR_PATH/$base_name_no_extension.$OUT_EXTENSION"
    if [ -f "$province_file_path" ]; then
        echo "===> $province_zip_path è già stato estratto e filtrato in $province_file_path"
    else
        unzipped_dir_path="$UNZIPPED_DIR_PATH/$base_name"
        if [ -e "$unzipped_dir_path" ]; then
            echo "===> $province_zip_path è già stato estratto in $unzipped_dir_path/"
        else
            echo "===> Estrazione di $province_zip_path in $unzipped_dir_path"
            unzip "$province_zip_path" -d "$unzipped_dir_path"
            echo "===> Estrazione in $unzipped_dir_path completata"
        fi

        gdb_dir_path="$(find "$unzipped_dir_path" -maxdepth 2 -type d -name '*.gdb')"
        echo "===> Filtraggio di $gdb_dir_path in $province_file_path"
        ogr2ogr -t_srs 'EPSG:4326' -where "$GDAL_FILTER" "$province_file_path" "$gdb_dir_path" "$GDAL_LAYER"
        echo "===> Filtraggio in $province_file_path completato"
    fi
done

DEST_FILE_PATH="./notebooks/dbsn_$OUT_NAME.$OUT_EXTENSION"
rm -f "$DEST_FILE_PATH"
for province_file_path in "$TEMP_DIR_PATH"/*.$OUT_EXTENSION ; do
    echo "===> Unione di $province_file_path in $DEST_FILE_PATH"
    ogr2ogr -append "$DEST_FILE_PATH" "$province_file_path"
done
echo "===> Unione in $DEST_FILE_PATH completata"