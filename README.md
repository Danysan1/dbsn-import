# dbsn-import

Scripts and notebooks for analysis and preparation of IGM DBSN data for integration in OpenStreetMap.

* [OSM Wiki](https://wiki.openstreetmap.org/wiki/Italy/DBSN)
* [Official website](https://www.igmi.org/it/dbsn-database-di-sintesi-nazionale)

Main scripts:
1. [download.sh](./download.sh): Download the files (one zip for each province)
   * `./download.sh -wiah -d <date> [<area_name>]`
   * `<area_name>` can be the name of a region or a province
   * `-w` prefer wikimedia or externally hosted files
   * `-i` prefer IGM files
   * `-a` download all files, overrides <area_name>
   * `-d <date>` download only specific files on specific date in format YYYY-MM-DD
   * `-h` shows a little help
2. [filter.sh](./filter.sh): Filter all the elements of a certain type (one GeoJSON for each province)
   * `./filter.sh -guaoh -e <extension> -d <driver> <out_name> <gdal_layer> [<gdal_filter>] [<area_name>]`
   * `<out_name>` is an arbitrary name used for the output
   * `<gdal_layer>` must be one of the layers in https://wiki.openstreetmap.org/wiki/Italy/DBSN/Mapping
   * `<gdal_filter>` should have the format `"parameter = 'value'"`, you can use `""` for no filter
   * `<area_name>` can be the name of a region or a province
   * `-g` tell program to call [download.sh](./download.sh) to get missing files 
   * `-u` tell ogr2ogr to update existsing output dataset
   * `-a` tell ogr2ogr to append to existing file and update output dataset
   * `-o` tell ogr2ogr to overwrite existing output dataset
   * `-e <extension>` tell the output extension to the program 
   * `-d <driver>` tell the program which driver to use 
   * `-h` shows a little help
3. [compare.sh](./compare.sh): Extract all the elements of a certain type that have no intersection with any element of the corresponding type on OSM (one file for each province)
   * `./compare.sh <out_name> <osm_filter> [<area_name>]`
   * `<out_name>` should be the same used previously for filter.sh
   * `<osm_filter>` should have the format `key=*` or `key=value`
   * `<area_name>` can be the name of a region or a province
4. [merge.sh](./merge.sh): Merge the filtered files (one fgb / geojson / parquet / mbtiles / pmtiles file)
   * `./merge.sh <out_name> [<format>]`
   * `<out_name>` should be the same used previously for filter.sh
   * `<format>` can be `geojson`, `fgb`, `parquet`, `mbtiles`, `pmtiles`

Thematic scripts:
* [buildings.sh](./buildings/buildings.sh): filter buildings
* [roads.sh](./roads/roads.sh): filter roads
* [boundaries.sh](./boundaries/boundaries.sh): filter administrative boundaries
* [townhalls.sh](./townhalls/townhalls.sh): filter town halls
* [townhalls_dbsn.ipynb](./townhalls/townhalls_dbsn.ipynb): find missing town halls on OSM (run only after [townhalls.sh](./townhalls/townhalls.sh))
* [scril_filter.sh](./scril_filter.sh): Filter all the elements of a certain type based on their survey scale
   * `./filter.sh <out_name> <gdal_layer> [<area_name>]`
   * `<out_name>`, `<gdal_layer>` and `<area_name>` have the same meaning of filter.sh
