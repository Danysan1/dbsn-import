#!/bin/bash
set -e

# Usage: ./download.sh [<nome_regione_o_provincia>]

OUT_DRIVER="FlatGeobuf" # GeoJSON / FlatGeobuf / ...
OUT_EXTENSION="fgb" # geojson / fgb / ...

OUT_NAME="$1"
OSM_TAG_FILTER="$2"
AREA_NAME="$3"

DBSN_DIR_PATH="$(dirname "$0")/data/$OUT_NAME/dbsn"
OSM_DIR_PATH="$(dirname "$0")/data/$OUT_NAME/osm"
COMPARE_DIR_PATH="$(dirname "$0")/data/$OUT_NAME/compare"
PBF_DIR_PATH="$(dirname "$0")/osm.pbf"

mkdir -p "$DBSN_DIR_PATH"
mkdir -p "$OSM_DIR_PATH"
mkdir -p "$COMPARE_DIR_PATH"
mkdir -p "$PBF_DIR_PATH"

while IFS=$'\t' read -r region province zip_file_name wmit_url igm_url igm_date latest ; do
    if [[ "$zip_file_name" == "File" || "$latest" != "yes" ]]; then
        # Skip header line and old files
        #echo "===> $region/$province/$igm_date: SKIPPED"
        continue
    fi

    # ${var,,} makes the value lowercase, used for case insensitive comparison
    if [[ -n "$AREA_NAME" && "${province,,}" != "${AREA_NAME,,}" && "${region,,}" != "${AREA_NAME,,}" && "${zip_file_name:0:2}" != "${AREA_NAME^^}" ]]; then
        #echo "===> $region/$province/$igm_date: SKIPPED"
        continue
    fi
    zip_file_name="${zip_file_name:0:2}_$igm_date.zip"
    zip_file_path="$ZIP_DIR_PATH/${zip_file_name}"

    pbf_file_url="$(grep "$province" ./wmit-estratti.tsv | cut -f 2 | tr -d '\r\n')"
    pbf_file_path="$PBF_DIR_PATH/$province.osm.pbf"
    if [[ -z "$pbf_file_url" ]]; then
        echo "===> !!!!!!!!!!!!!!!!!!!! $region/$province: OSM PBF URL not found !!!!!!!!!!!!!!!!!!!!"
        continue
    elif [[ -f "$pbf_file_path" ]]; then
        echo "===> $region/$province: OSM PBF already downloaded in '$pbf_file_path'"
    else
        echo "===> $region/$province: Downloading OSM PBF from '$pbf_file_url'"
        curl --fail --output "$pbf_file_path" "$pbf_file_url" && \
            echo "===> $region/$province: Download of '$pbf_file_path' COMPLETED" || \
            echo "===> $region/$province: Download of '$pbf_file_path' FAILED"
    fi

    filtered_file_path="$OSM_DIR_PATH/$province.osm.pbf"
    osm_geojson_file_path="$OSM_DIR_PATH/$province.geojson"
    if [[ -f "$osm_geojson_file_path" ]]; then
        echo "===> $region/$province: OSM filtered GeoJSON already exists: '$osm_geojson_file_path'"
    elif which osmium ; then
        if [[ ! -f "$filtered_file_path" ]]; then
            echo "===> $region/$province: Filtering OSM data in '$filtered_file_path'"
            osmium tags-filter -o "$filtered_file_path" "$pbf_file_path" "$OSM_TAG_FILTER"
        fi
        echo "===> $region/$province: Converting '$filtered_file_path' to '$osm_geojson_file_path'"
        osmium export "$filtered_file_path" -o "$osm_geojson_file_path"
    else
        echo "=====> osmium not found, install it with the instructions in https://osmcode.org/osmium-tool/"
        exit 1
    fi

    zip_file_name_no_extension="${zip_file_name%.zip}"
    dbsn_fgb_file_path="$DBSN_DIR_PATH/$zip_file_name_no_extension.$OUT_EXTENSION"
    out_file_path="$COMPARE_DIR_PATH/$province.fgb"
    if [[ -f "$out_file_path" ]]; then
        echo "===> $region/$province: OSM comparison already exists: '$out_file_path'"
    elif which ogr_layer_algebra ; then
        echo "===> $region/$province: Comparing '$dbsn_fgb_file_path' and '$osm_geojson_file_path' with ogr_layer_algebra"
        # https://gdal.org/en/stable/programs/ogr_layer_algebra.html
        ogr_layer_algebra Erase -input_ds "$dbsn_fgb_file_path" -method_ds "$osm_geojson_file_path" -output_ds "$out_file_path" -output_lyr "$OUT_FILE_NAME" -f "$OUT_DRIVER"
    elif which gdal ; then
        echo "===> $region/$province: Comparing '$dbsn_fgb_file_path' and '$osm_geojson_file_path' with gdal cli"
        # https://gdal.org/en/stable/programs/gdal_vector_layer_algebra.html
        gdal vector layer-algebra erase "$dbsn_fgb_file_path" "$osm_geojson_file_path" "$out_file_path" -f "$OUT_DRIVER"
    else
        echo "=====> GDAL not found, install it with the instructions in https://gdal.org/download.html"
        exit 1
    fi
done < ./dbsn.tsv

echo "===> Download in $PBF_DIR_PATH completed"
