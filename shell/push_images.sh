#!/bin/bash
# this script will upload the given local images to a registry server ($registry is the default vvalue).
# usage: push_images image1 [image2...]
# author：yeasy@github
# create: 2014-09-23
# the registry server address where you want push the images into
registry=180.76.232.94:5000

### DO NOT MODIFY THE FOLLOWING PART, UNLESS YOU KNOW WHAT IT MEANS ###
echo_r () {
    [ $# -ne 1 ] && return 0
    echo -e "\e[31m$1\e[0m"
}
echo_g () {
    [ $# -ne 1 ] && return 0
    echo -e "\e[32m$1\e[0m"
}
echo_y () {
    [ $# -ne 1 ] && return 0
    echo -e "\e[33m$1\e[0m"
}
echo_b () {
    [ $# -ne 1 ] && return 0
    echo -e "\e[34m$1\e[0m"
}
usage () {
    docker images
    echo "Usage: $0 registry1:tag1 [registry2:tag2...]"
}

[ $# -lt 1 ] && usage && exit

echo_b "The registry server is $registry"

for image in "$*"
do
    echo_b "Uploading $image..."
    docker tag $image $registry/$image
    docker push $registry/$image
    echo_g "Done"
done

#for docker images | grep -vi "repository" | grep -vi "<none>" | awk '{print $1":"$2}'
#do
#    push_images.sh $image
#done
