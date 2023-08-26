# dbsn-import

Scripts and notebooks for anlysis and preparation of IGM DBSN data for integration in OpenStreetMap.

* [OSM Wiki](https://wiki.openstreetmap.org/wiki/Italy/DBSN)
* [Official website](https://www.igmi.org/it/dbsn-database-di-sintesi-nazionale)
Main scripts:
* [download.sh](./download.sh): Download the files for each province
* [filter.sh](./filter.sh): Filter all the elements of a certain type
* [townhalls_dbsn.ipynb](./notebooks/townhalls_dbsn.ipynb): find missing townhalls (run only after creating townhalls.geojson with `./filter.sh edifc "\"edifc_uso\" = '0201'" townhalls geojson`; view on https://www.dsantini.it/dbsn/notebooks/townhalls_dbsn.html )
