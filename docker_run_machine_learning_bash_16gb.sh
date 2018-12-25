#!/bin/bash

home=$(echo ~)
pwd=$(pwd)
user=$(id -un)
docker run -ti --rm --runtime=nvidia --shm-size=16gb -e DISPLAY=$DISPLAY -e XMODIFIERS=$XMODIFIERS -e COLUMNS=86 -e LINES=104 -v /tmp/.X11-unix/:/tmp/.X11-unix -v $home:$home -w $pwd -u $user --privileged -v /dev/video0:/dev/video0 --name machine_learning machine_learning /bin/bash
