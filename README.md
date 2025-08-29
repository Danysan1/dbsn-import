# dbsn-import

Scripts and notebooks for analysis and preparation of IGM DBSN data for integration in OpenStreetMap.

* [OSM Wiki](https://wiki.openstreetmap.org/wiki/Italy/DBSN)
* [Official website](https://www.igmi.org/it/dbsn-database-di-sintesi-nazionale)
Main scripts:
1. [download.sh](./download.sh): Download the files (one GeoJSON for each province)
2. [filter.sh](./filter.sh): Filter all the elements of a certain type (one GeoJSON for each province)
3. [merge.sh](./merge.sh): Merge the filtered files (one geojson / parquet / mbtiles file)
4. [townhalls_dbsn.ipynb](./notebooks/townhalls_dbsn.ipynb): find missing townhalls, execute it only after creating townhalls.geojson with:
    1. `./download.sh`
    2. `./filter.sh townhalls edifc "edifc_uso = '0201'"`
    3. `./merge.sh townhalls geojson`
