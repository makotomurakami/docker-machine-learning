#!/bin/bash

uid=$(id -u)
gid=$(id -g)
user=$(id -un)
group=$(id -gn)
docker build --no-cache --build-arg uid=$uid --build-arg gid=$gid --build-arg user=$user --build-arg group=$group -t machine_learning .
