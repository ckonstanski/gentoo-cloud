#!/bin/bash

router_name="${1}"
private_network_name="${2}"
private_network_cidr="${3}"
ext_network_name="${4}"

if [ "${router_name}" == "" ]; then
    echo "No router name supplied." >&2
    exit 1
elif [ "${private_network_name}" == "" ]; then
    echo "No private network name supplied." >&2
    exit 1
elif [ "${private_network_cidr}" == "" ]; then
    echo "No private network CIDR supplied." >&2
    exit 1
elif [ "${ext_network_name}" == "" ]; then
    echo "No external network name supplied." >&2
    exit 1
fi

ext_network_id=$(neutron net-show -f shell -c id "${ext_network_name}" 2>/dev/null | awk -F= '{print $2;}' | sed -e 's/\"//g')
if [ "${ext_network_id}" == "" ]; then
    echo "No ${ext_network_name} network exists." >&2
    exit 1
fi

private_network_id=$(neutron net-show -f shell -c id "${private_network_name}" 2>/dev/null | awk -F= '{print $2;}' |sed -e 's/\"//g')
if [ "${private_network_id}" == "" ]; then
    neutron net-create "${private_network_name}" >/dev/null
    neutron subnet-create \
        --name "${private_network_name}" \
        --dns-nameserver $(echo $DNS_SERVERS | awk '{print $1;}') \
        --dns-nameserver $(echo $DNS_SERVERS | awk '{print $2;}') \
        --dns-nameserver $(echo $DNS_SERVERS | awk '{print $3;}') \
        --enable-dhcp \
        "${private_network_name}" \
        "${private_network_cidr}" \
        >/dev/null
    private_network_id=$(neutron net-show -f shell -c id "${private_network_name}" 2>/dev/null | awk -F= '{print $2;}' |sed -e 's/\"//g')
    if [ "${private_network_id}" == "" ]; then
        echo "Cannot retrieve private network ID after creation." >&2
        exit 1
    fi
fi

router_id=$(neutron router-show -f shell -c id "${router_name}" 2>/dev/null | awk -F= '{print $2;}' | sed -e 's/\"//g')
if [ "${router_id}" == "" ]; then
    neutron router-create "${router_name}" >/dev/null
    router_id=$(neutron router-show -f shell -c id "${router_name}" 2>/dev/null | awk -F= '{print $2;}' | sed -e 's/\"//g')
    if [ "${router_id}" == "" ]; then
        echo "Cannot retrieve router ID after creation." >&2
        exit 1
    fi
fi

gateway_info=$(neutron router-show -f shell -c external_gateway_info "${router_name}" 2>/dev/null | grep -F 'external_fixed_ips')
if [ "${gateway_info}" == "" ]; then
    neutron router-gateway-set "${router_id}" "${ext_network_id}" >/dev/null
fi

neutron router-interface-add "${router_id}" "${private_network_name}" >/dev/null 2>&1 || true

echo -n "${private_network_id}"

exit 0
