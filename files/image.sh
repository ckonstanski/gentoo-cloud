#!/bin/bash

image_name="${1}"

if [ "${image_name}" == "" ]; then
    echo "No image name supplied." >&2
    exit 1
fi

image_id=$(openstack image list --limit 1000 --private 2>/dev/null | grep -F " ${image_name} " | awk '{print $2;}')
if [ "${image_id}" == "" ]; then
    echo -n "Cannot retrieve an image ID corresponding to the name: " >&2
    echo "${image_name}" >&2
    exit 1
fi

exit 0
