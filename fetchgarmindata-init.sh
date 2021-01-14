#!/bin/sh -e
docker build --tag fetchgarmindata https://github.com/matswi/FetchGarminData/raw/master/Dockerfile
docker run --hostname $(hostname) --name="fetchgarmindata" --interactive --rm --tty --privileged -v /home/pi/FetchGarminData/Configuration.json:/root/FetchGarminData/Configuration.json -v /etc/localtime:/etc/localtime:ro fetchgarmindata