#!/bin/bash

flavor_name="${1}"

if [ "${flavor_name}" == "" ]; then
    echo "No flavor name supplied." >&2
    exit 1
fi

flavor_id=$(nova flavor-list | grep -F "${flavor_name}" | awk '{print $2;}')
if [ "${flavor_id}" == "" ]; then
    echo -n "Cannot retrieve a flavor ID corresponding to the name: " >&2
    echo "${flavor_name}" >&2
    exit 1
fi

exit 0
