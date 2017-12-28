#!/bin/sh
#$1 是yaml 文件
IMAGE_LIST=$(cat $1| grep image:  | grep  -o -E "\s\S+$")
for IMAGE in $IMAGE_LIST
do
  docker pull $IMAGE
done
