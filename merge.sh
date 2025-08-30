#!/bin/bash
set -e

if [[ -z "$1" ]]; then
    echo "Usage: ./merge.sh <out_name> [<format>]"
    exit 1
fi

OUT_NAME="$1"
FORMAT="${2:-geojson}" # Default format is geojson

TEMP_DIR_PATH="./.temporary_data/$OUT_NAME"
GEOJSON_FILE_PATH="./data/dbsn_$OUT_NAME.geojson"

mkdir -p "./data"

if [[ "$FORMAT" == "geojson" || "$FORMAT" == "parquet" ]]; then
    if which ogr2ogr ; then
        rm -f "$GEOJSON_FILE_PATH"
        for province_file_path in "$TEMP_DIR_PATH"/*.geojson ; do
            echo "=====> Merging $province_file_path in $GEOJSON_FILE_PATH"
            ogr2ogr -append -f 'GeoJSON' "$GEOJSON_FILE_PATH" "$province_file_path"
        done
        echo "=====> Merge of $GEOJSON_FILE_PATH completed"
    else
        echo "=====> GDAL not found, install it with the instructions in https://gdal.org/download.html"
        exit 1
    fi
fi

if [[ "$FORMAT" == "parquet" ]]; then
    PARQUET_FILE_PATH="./data/dbsn_$OUT_NAME.parquet"
    echo "=====> Converting $GEOJSON_FILE_PATH in $PARQUET_FILE_PATH"
    ogr2ogr -f 'Parquet' "$PARQUET_FILE_PATH" "$GEOJSON_FILE_PATH"
    echo "=====> Conversion in $PARQUET_FILE_PATH completed"
fi

if [[ "$FORMAT" == "mbtiles" ]]; then
    if which tippecanoe ; then
        MBTILES_FILE_PATH="./data/dbsn_$OUT_NAME.mbtiles"
        echo "=====> Converting "$TEMP_DIR_PATH/*.geojson" in $MBTILES_FILE_PATH"
        # https://github.com/felt/tippecanoe#try-this-first
        tippecanoe -zg -o "$MBTILES_FILE_PATH" -l "$OUT_NAME" --drop-densest-as-needed "$TEMP_DIR_PATH"/*.geojson
        echo "=====> Conversion in $PARQUET_FILE_PATH completed"
    else
        echo "=====> Tippecanoe not found, install it with the instructions in https://github.com/felt/tippecanoe"
        exit 1
    fi
fi
