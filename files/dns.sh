#!/bin/bash

instance_name="${1}"
floating_ip="${2}"

if [ "${instance_name}" == "" ]; then
    echo "No instance name supplied." >&2
    exit 1
elif [ "${floating_ip}" == "" ]; then
    echo "No floating IP supplied." >&2
    exit 1
fi

domain_id=$(designate domain-list 2>/dev/null | grep -F "cloud.twc.net" | awk '{print $2;}')
if [ "${domain_id}" == "" ]; then
    echo -n "Could not find the domain. It must be created in Horizon " >&2
    echo -n "prior to running this playbook so that the project will " >&2
    echo "get correctly wired up to infoblox." >&2
    exit 1
else
    domain_name=$(designate domain-list 2>/dev/null | grep -F "cloud.twc.net" | awk '{print $4;}')
    fqdn="${instance_name}.${domain_name}"
fi

record_id=$(designate record-list ${domain_id} 2>/dev/null | grep -F "${fqdn}" | grep -F ' A ' | awk '{print $2;}')
if [ "${record_id}" == "" ]; then
    designate record-create ${domain_id} --type A --name "${fqdn}" --data ${floating_ip} >/dev/null 2>&1
    record_id=$(designate record-list ${domain_id} 2>/dev/null | grep -F "${fqdn}" | grep -F ' A ' | awk '{print $2;}')
    if [ "${record_id}" == "" ]; then
        echo "No existing A record. Cannot create A record." >&2
        exit 1
    fi
else
    target_ip=$(designate record-list ${domain_id} 2>/dev/null | grep -F "${fqdn}" | grep -F ' A ' | awk '{print $8;}')
    if [ "${target_ip}" != "${floating_ip}" ]; then
        designate record-delete ${domain_id} ${record_id} >/dev/null 2>&1
        designate record-create ${domain_id} --type A --name "${fqdn}" --data ${floating_ip} >/dev/null 2>&1
        record_id=$(designate record-list ${domain_id} 2>/dev/null |grep -F "${fqdn}" | grep -F ' A ' | awk '{print $2;}')
        if [ "${record_id}" == "" ]; then
            echo "Existing A record had wrong IP. Cannot create A record." >&2
        exit 1
        fi
    fi
fi

echo "${fqdn::-1}"

exit 0
