#!/bin/bash

flavor_name="${1}"
image_name="${2}"
network_id="${3}"
keypair_name="${4}"
instance_name="${5}"
region="${6}"

if [ "${flavor_name}" == "" ]; then
    echo "No flavor name supplied." >&2
    exit 1
elif [ "${image_name}" == "" ]; then
    echo "No image name supplied." >&2
    exit 1
elif [ "${network_id}" == "" ]; then
    echo "No network ID supplied." >&2
    exit 1
elif [ "${keypair_name}" == "" ]; then
    echo "No keypair name supplied." >&2
    exit 1
elif [ "${instance_name}" == "" ]; then
    echo "No instance name supplied." >&2
    exit 1
elif [ "${region}" == "" ]; then
    echo "No region supplied." >&2
    exit 1
else
    region=${region,,}
fi

if [ "${instance_name}" == "gentoo" ]; then
    volume_size="${7}"
    if [ "${volume_size}" == "" ]; then
        echo "No volume size supplied." >&2
        exit 1
    fi
fi

associate_floating_ip () {
    for line in $(nova floating-ip-list | grep -F 'Ext-Net' | sed -e 's/ //g'); do
        floating_ip_id=$(echo ${line} | awk -F\| '{print $2;}')
        floating_ip=$(echo ${line} | awk -F\| '{print $3;}')
        floating_ip_instance_id=$(echo ${line} | awk -F\| '{print $4;}')
        if [ "${floating_ip_instance_id}" == "-" ]; then
            nova floating-ip-associate "${instance_id}" "${floating_ip}" >/dev/null 2>&1
            echo "${floating_ip}"
            return 0
        fi
    done
    return 1
}

image_id=$(openstack image list --limit 1000 --private 2>/dev/null | grep -F " ${image_name} " | awk '{print $2;}')
if [ "${image_id}" == "" ]; then
    echo "Could not find id for image ${image_name}" >&2
    exit 1
fi

instance_number=1
for num in $(nova list --limit -1 2>/dev/null | grep -F "${region}-${instance_name}" | awk '{print $4;}' | awk -F- '{print $3;}' | sort); do
    if (( "${num}" == ${instance_number} )); then
        instance_number=$(expr ${instance_number} + 1)
    fi
done
instance_number="00${instance_number}"
instance_number=${instance_number: -3}

if [ "${instance_name}" == "gentoo" ]; then
    ssd_uuid=$(openstack volume list 2>/dev/null | grep -F " ${region}-${instance_name}-${instance_number}-dbvol " | awk '{print $2;}')
    if [ "${ssd_uuid}" == "" ]; then
        openstack volume create --size ${volume_size} --type Standard-HDD "${region}-${instance_name}-${instance_number}-data" >/dev/null 2>&1
        ssd_uuid=$(openstack volume list 2>/dev/null | grep -F " ${region}-${instance_name}-${instance_number}-data " | awk '{print $2;}')
        if [ "${ssd_uuid}" == "" ]; then
            echo "Could not create database SSD volume." >&2
            exit 1
        fi
    fi
fi

instance_id=$(nova boot \
    --flavor "${flavor_name}" \
    --block-device source=image,id=${image_id},dest=volume,size=40,shutdown=preserve,bootindex=0 \
    --nic net-id="${network_id}" \
    --security-groups "default,basic,web,dns" \
    --key-name "${keypair_name}" \
    --user-data "data/etc/cloud/cloud.cfg" \
    --poll \
    "${region}-${instance_name}-${instance_number}" \
    | grep -F ' id ' | awk '{print $4;}')

if [ "${instance_id}" == "" ]; then
    echo "Instance creation did not return an ID." >&2
    exit 1
fi

if [ "${instance_name}" == "gentoo" ]; then
    nova volume-attach ${instance_id} ${ssd_uuid} /dev/vdb >/dev/null 2>&1
fi

floating_ip_assigned=$(associate_floating_ip)
if (( ${?} == 1 )); then
    nova floating-ip-create Ext-Net >/dev/null 2>&1
    if (( ${?} == 0 )); then
        floating_ip_assigned=$(associate_floating_ip)
        if (( ${?} == 1 )); then
            echo "Could not associate floating IP." >&2
            exit 1
        fi
    fi
fi

for sec in basic web dns; do
    nova add-secgroup ${instance_id} ${sec} >/dev/null 2>&1
done

echo "${floating_ip_assigned}"
echo "${region}-${instance_name}-${instance_number}"

exit 0
