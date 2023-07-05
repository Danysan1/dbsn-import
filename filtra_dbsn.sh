#!/bin/bash
set -e

# Il filtro da applicare ai dati e il layer da usare vanno ricavati dal PDF delle specifiche
# La lista dei layer disponibili si può ottenere eseguendo ogrinfo sulla cartella gdb di una qualsiasi provincia

GDAL_FILTER="\"edifc_uso\" = '0201'"
GDAL_LAYER='edifc'
DEST_DIR_PATH='./.temporary_data/municipi'
DEST_FILE_PATH='./notebooks/municipi.geojson'

# GDAL_FILTER="\"edifc_uso\" = '030102'"
# GDAL_LAYER='edifc'
# DEST_DIR_PATH='./.temporary_data/ospedali'
# DEST_FILE_PATH='./notebooks/ospedali.geojson'

# TODO add other categories

SOURCE_DIR_PATH="../zip"
UNZIPPED_DIR_PATH='../unzipped'


mkdir -p "$DEST_DIR_PATH"
mkdir -p "$UNZIPPED_DIR_PATH"

for province_zip_path in "$SOURCE_DIR_PATH"/*.zip ; do
    base_name="$(basename $province_zip_path)"
    base_name_no_extension="${base_name%.zip}"

    province_file_path="$DEST_DIR_PATH/$base_name_no_extension.geojson"
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
        ogr2ogr -f 'GeoJSON' -t_srs 'EPSG:4326' -where "$GDAL_FILTER" "$province_file_path" "$gdb_dir_path" "$GDAL_LAYER"
        echo "===> Filtraggio in $province_file_path completato"
    fi
done

rm -f "$DEST_FILE_PATH"
for province_file_path in "$DEST_DIR_PATH"/*.geojson ; do
    echo "===> Unione di $province_file_path in $DEST_FILE_PATH"
    ogr2ogr -f 'GeoJSON' -append "$DEST_FILE_PATH" "$province_file_path"
done
echo "===> Unione in $DEST_FILE_PATH completata"