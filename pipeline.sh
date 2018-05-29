#!/bin/bash
cd data
mkdir MSD
rsync -avzuP publicdata.opensciencedatacloud.org::ark:/31807/osdc-c1c763e4/ MSD
cd MSD
./expand.sh
cd msd_downloader
mysql -h "35.224.242.55" -u "root" "root" < "migration_script.sql"
python hdf5_to_mysql.py ../data/MSDData
cd ..
mysql -h "35.224.242.55" -u "root" "root" < "lastfm.sql"
python exportLastfm2Mysql.py manorathan

