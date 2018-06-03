#!/bin/bash

cd layout
tar zcvf layout.tar.gz *
mv layout.tar.gz ../
cd ..
docker build -t apnex/myvmw -f ./myvmw.docker .
rm layout.tar.gz
