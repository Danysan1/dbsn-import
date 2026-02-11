#!/bin/bash
set -e
cd $(dirname "$0")/..

./download.sh "$1"

./filter.sh tr_str_no_osm tr_str "meta_ist != '03'" "$1"
./filter.sh el_vms_no_osm el_vms "meta_ist != '03'" "$1"

#./compare.sh tr_str_no_osm "highway=*" "$1"
#./compare.sh el_vms_no_osm "highway=*" "$1"

#./merge.sh tr_str_no_osm pmtiles
./merge.sh tr_str_no_osm fgb
#./merge.sh el_vms_no_osm pmtiles
./merge.sh el_vms_no_osm fgb
