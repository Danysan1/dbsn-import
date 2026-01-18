#!/bin/bash
set -e

if [[ -z "$1" || -z "$2" ]]; then
    echo "See README.md for usage instructions"
    exit 1
fi

if ! which ogr2ogr > /dev/null; then
    echo "=====> GDAL not found, install it with the instructions in https://gdal.org/download.html"
    exit 2
fi

OUT_DRIVER="FlatGeobuf" # GeoJSON / FlatGeobuf / ...
OUT_EXTENSION="fgb" # geojson / fgb / ...
DOWNLOAD_IF_MISSING=false
OVERWRITE=false
UPDATE=false
APPEND=false

while getopts "hguaoe:d:" flag; do
    case $flag in
        d)
            OUT_DRIVER=$OPTARG
            ;;
        e)
            OUT_EXTENSION=$OPTARG
            ;;
        g)
            DOWNLOAD_IF_MISSING=true
            ;;
        o)
            OVERWRITE=true
            ;;
        u)
            APPEND=true
            ;;
        a)
            UPDATE=true
            ;;
        h) 
            echo -e "\nDBSN Filter\n\nFlags:\n-e\t\tOutput extension for the file\n-d\t\tOutput driver for the file\n-g\t\tDownload if file is not available\n"
            exit 0
            ;;
        *) 
            echo -e "\nDBSN Filter\n\nFlags:\n-e <ext>\tOutput extension for the file, without .\n-d <name>\tOutput driver for the file\n-g\t\tDownload if file is not available\n-a\t\tAppend content to existing file\n-u\t\tUpdate current file\n-o\t\tOverwrite current file\n"
            exit 1
            ;;
    esac
done

shift $((OPTIND - 1))

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
OUT_DIR_PATH="$(dirname "$0")/data/$OUT_NAME/dbsn"

mkdir -p "$OUT_DIR_PATH"
mkdir -p "$UNZIPPED_DIR_PATH"

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


    if [[ $DOWNLOAD_IF_MISSING == true && ! -f $zip_file_path ]]; then
        sh download.sh $AREA_NAME
    
    elif [[ ! -f $zip_file_path ]]; then
        echo "===> Source file not found"
        exit 1
    fi

    original_file_name_no_extension="${zip_file_name%.zip}"
    province_file_path="$TEMP_DIR_PATH/$original_file_name_no_extension.$OUT_EXTENSION"
    if [ -f "$province_file_path" && ! OVERWRITE ]; then
        echo "===> $region/$province/$igm_date: Already extracted and filtered in '$province_file_path'"
        continue
    fi
    
    province_zip_path="$ZIP_DIR_PATH/$zip_file_name"
    unzipped_dir_path="$UNZIPPED_DIR_PATH/$original_file_name_no_extension"
    if [ -e "$unzipped_dir_path" ]; then
        echo "===> $region/$province/$igm_date: Already extracted in '$unzipped_dir_path'"
    else
        echo "===> Extraction of '$province_zip_path' in '$unzipped_dir_path'..."
        unzip "$province_zip_path" -d "$unzipped_dir_path"
        echo "===> Extraction in '$unzipped_dir_path' completed"
    fi

    gdb_dir_path="$(find "$unzipped_dir_path" -maxdepth 2 -type d -name '*.gdb')"

    ogr2ogr_cmd="-f \"$OUT_DRIVER\" -t_srs 'EPSG:4326' -nln \"$OUT_NAME\" -skipfailures"
    [[ -n "$GDAL_FILTER" ]] && ogr2ogr_cmd="$ogr2ogr_cmd -where \"$GDAL_FILTER\""
    [[ $OVERWRITE == true ]] && ogr2ogr_cmd="$ogr2ogr_cmd -overwrite"
    [[ $UPDATE == true ]] && ogr2ogr_cmd="$ogr2ogr_cmd -update"
    [[ $APPEND == true ]] && ogr2ogr_cmd="$ogr2ogr_cmd -append"

    echo "===> Filtering of '$gdb_dir_path' in '$province_file_path' with command ogr2ogr $ogr2ogr_cmd "$province_file_path" "$gdb_dir_path" "$GDAL_LAYER" ..."

    sh -c "ogr2ogr $ogr2ogr_cmd "$province_file_path" "$gdb_dir_path" "$GDAL_LAYER"" \
    && echo "===> $region/$province/$igm_date: Filtering COMPLETED" \
    || (echo "===> !!!!!!!!!! $region/$province/$igm_date: Filtering FAILED !!!!!!!!!!" && rm "$province_file_path")
done < ./dbsn.tsv
