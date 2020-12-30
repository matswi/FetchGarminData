#!/bin/sh -e
docker build --tag weatherbox https://github.com/matswi/FetchGarminData/raw/master/Dockerfile
docker run --hostname $(hostname) --interactive --rm --tty --privileged -v /home/pi/FetchGarminData/Configuration.json:/root/FetchGarminData/Configuration.json FetchGarminData