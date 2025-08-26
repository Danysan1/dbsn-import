#!/bin/bash
set -e

# To understand and find the filters, check out https://wiki.openstreetmap.org/wiki/Italy/DBSN#Data_model
# The list of available layers can be obtained by running ogrinfo on the gdb folder for any province
# Examples of usage:
# ./filter.sh <NAME> <LAYER> [FILTER]
# ./filter.sh buildings edifc
# ./filter.sh townhalls edifc "edifc_uso = '0201'"
# ./filter.sh police_buildings edifc "edifc_uso = '0306'"
# ./filter.sh hospital_buildings edifc "edifc_uso = '030102'"
# ./filter.sh hospitals pe_uins "pe_uins_ty = '0302'"

OUT_NAME="$1"
GDAL_LAYER="$2"
GDAL_FILTER="$3"

ZIP_DIR_PATH="$(dirname "$0")/zip"
UNZIPPED_DIR_PATH="$(dirname "$0")/unzipped"
TEMP_DIR_PATH="$(dirname "$0")/.temporary_data/$OUT_NAME"
mkdir -p "$TEMP_DIR_PATH"
mkdir -p "$UNZIPPED_DIR_PATH"

for province_zip_path in "$ZIP_DIR_PATH"/*.zip ; do
    base_name="$(basename $province_zip_path)"
    base_name_no_extension="${base_name%.zip}"

    province_file_path="$TEMP_DIR_PATH/$base_name_no_extension.geojson"
    if [ -f "$province_file_path" ]; then
        echo "===> $province_zip_path already extracted and filtered in $province_file_path"
    else
        unzipped_dir_path="$UNZIPPED_DIR_PATH/$base_name"
        if [ -e "$unzipped_dir_path" ]; then
            echo "===> $province_zip_path already extracted in $unzipped_dir_path/"
        else
            echo "===> Extraction of $province_zip_path in $unzipped_dir_path"
            unzip "$province_zip_path" -d "$unzipped_dir_path"
            echo "===> Extraction in $unzipped_dir_path completed"
        fi

        gdb_dir_path="$(find "$unzipped_dir_path" -maxdepth 2 -type d -name '*.gdb')"
        echo "===> Filtering of $gdb_dir_path in $province_file_path"
        if [[ -z "$GDAL_FILTER" ]]; then
            ogr2ogr -f 'GeoJSON' -t_srs 'EPSG:4326' "$province_file_path" "$gdb_dir_path" "$GDAL_LAYER"
        else
            ogr2ogr -f 'GeoJSON' -t_srs 'EPSG:4326' -where "$GDAL_FILTER" "$province_file_path" "$gdb_dir_path" "$GDAL_LAYER"
        fi
        echo "===> Filtering in $province_file_path completed"
    fi
done

GEOJSON_FILE_PATH="./notebooks/dbsn_$OUT_NAME.geojson"
PARQUET_FILE_PATH="./notebooks/dbsn_$OUT_NAME.parquet"
rm -f "$GEOJSON_FILE_PATH"
for province_file_path in "$TEMP_DIR_PATH"/*.geojson ; do
    echo "===> Merging $province_file_path in $GEOJSON_FILE_PATH"
    ogr2ogr -append -f 'GeoJSON' "$GEOJSON_FILE_PATH" "$province_file_path"
done
echo "===> Merge of $GEOJSON_FILE_PATH completed, converting in $PARQUET_FILE_PATH"
ogr2ogr -f 'Parquet' "$PARQUET_FILE_PATH" "$GEOJSON_FILE_PATH"
echo "===> Conversion in $PARQUET_FILE_PATH completed"
