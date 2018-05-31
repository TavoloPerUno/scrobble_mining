#!/bin/bash
cd ../data
mkdir MSD
rsync -avzuP publicdata.opensciencedatacloud.org::ark:/31807/osdc-c1c763e4/ MSD
cd MSD
../sh/expand.sh
cd msd_downloader
cd ../sql
mysql -h "35.224.242.55" -u "root" "root" < "migration_script.sql"
cd ../MSD_downloader
python hdf5_to_mysql.py ../data/MSDData
cd ../sql
mysql -h "35.224.242.55" -u "root" "root" < "lastfm.sql"
cd ../lastfm_downloader
python exportLastfm2Mysql.py manorathan
cd ../mongodb_lake
python mongodb_loader.py

