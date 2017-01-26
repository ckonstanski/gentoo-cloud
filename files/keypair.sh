#!/bin/bash

keypair_name="${1}"
pubkey_path="${2}"

if [ "${keypair_name}" == "" ]; then
    echo "No keypair name was supplied." >&2
    exit 1
fi

keypair_fingerprint=$(nova keypair-list | grep -F "${keypair_name}" | awk '{print $4;}')
if [ "${keypair_fingerprint}" == "" ]; then
    if [ "${pubkey_path}" == "" ]; then
        echo -n "Need to create an SSH keypair, but no path to a pubkey " >&2
        echo "was supplied." >&2
        exit 1
    elif [ ! -f "${pubkey_path}" ]; then
        echo -n "Need to create an SSH keypair, but the supplied path " >&2
        echo "to the pubkey is invalid:" >&2
        echo "${pubkey_path}" >&2
        exit 1
    fi

    nova keypair-add --pub-key "${pubkey_path}" "${keypair_name}"
    keypair_fingerprint=$(nova keypair-list | grep -F "${keypair_name}" | awk '{print $4;}')
    if [ "${keypair_fingerprint}" == "" ]; then
        echo "Could not retrieve keypair after creation." >&2
        exit 1
    fi
fi

exit 0
