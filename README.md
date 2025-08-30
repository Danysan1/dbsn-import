# dbsn-import

Scripts and notebooks for analysis and preparation of IGM DBSN data for integration in OpenStreetMap.

* [OSM Wiki](https://wiki.openstreetmap.org/wiki/Italy/DBSN)
* [Official website](https://www.igmi.org/it/dbsn-database-di-sintesi-nazionale)

Main scripts:
1. [download.sh](./download.sh): Download the files (one zip for each province)
   * `./download.sh [<area_name>]`
   * `<area_name>` can be the name of a region or a province
2. [filter.sh](./filter.sh): Filter all the elements of a certain type (one GeoJSON for each province)
   * `./filter.sh <out_name> <gdal_layer> [<gdal_filter>] [<area_name>]`
   * `<out_name>` is an arbitrary name used for the output
   * `<gdal_layer>` must be one of the layers in https://wiki.openstreetmap.org/wiki/Italy/DBSN/Mapping
   * `<gdal_filter>` should have the format `"parameter = 'value'"`, you can use `""` for no filter
   * `<area_name>` can be the name of a region or a province
3. [merge.sh](./merge.sh): Merge the filtered files (one geojson / parquet / mbtiles file)
   * `./merge.sh <out_name> [<format>]`
   * `<out_name>` should be the same used previously for filter.sh
   * `<format>` can be `geojson`, `parquet` or `mbtiles`
4. [townhalls_dbsn.ipynb](./notebooks/townhalls_dbsn.ipynb): find missing townhalls, execute it only after creating townhalls.geojson with:
    1. `./download.sh`
    2. `./filter.sh townhalls edifc "edifc_uso = '0201'"`
    3. `./merge.sh townhalls geojson`
