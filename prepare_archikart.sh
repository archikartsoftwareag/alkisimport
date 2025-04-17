#!/bin/bash

cd /root/archikart/alkis/alkisimport
chmod 744 alkis-import.sh
chmod 744 watch_folder.sh
chmod 744 create_db.sh
make tables.lst alkis-functions.sql
cd postupdate.d
rm -f archikart.sql
ln -s ../postcreate.d/archikart.sql ./
rm -f nas2alb_archikart.sql
ln -s ../postcreate.d/nas2alb_archikart.sql ./
