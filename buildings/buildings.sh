#!/bin/bash
set -e
cd $(dirname "$0")/..

./download.sh "$1"

./filter.sh edifc_no_osm edifc "meta_ist != '03'" "$1"
#./filter.sh edifc_osm edifc "meta_ist = '03'" "$1"
./filter.sh edi_min_no_osm edi_min "meta_ist != '03'" "$1"

#./compare.sh edifc_no_osm "building=*" "$1"
#./compare.sh edi_min_no_osm "building=*" "$1"

#./merge.sh edifc_no_osm pmtiles
./merge.sh edifc_no_osm fgb
#./merge.sh edifc_osm fgb
#./merge.sh edi_min_no_osm pmtiles
./merge.sh edi_min_no_osm fgb


