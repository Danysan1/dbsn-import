#!/bin/bash
set -e
cd $(dirname "$0")/..

./download.sh "$1"

./filter.sh townhalls edifc "edifc_uso = '0201'" "$1"

#./compare.sh townhalls "amenity=townhall" "$1"

#./merge.sh townhalls pmtiles
./merge.sh townhalls fgb

cp data/townhalls/townhalls.fgb townhalls/
