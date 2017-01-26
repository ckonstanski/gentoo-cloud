#!/bin/bash

if [ "$(nova secgroup-list | grep -F ' basic ' | awk '{print $4;}')" == "" ]; then
    nova secgroup-create basic 'Basic access' >/dev/null 2>&1
fi

if [ "$(nova secgroup-list-rules basic | grep -F ' icmp ')" == "" ]; then
    nova secgroup-add-rule basic icmp -1 -1 0.0.0.0/0 >/dev/null 2>&1
fi

if [ "$(nova secgroup-list-rules basic | grep -F ' 22 ')" == "" ]; then
    nova secgroup-add-rule basic tcp 22 22 0.0.0.0/0 >/dev/null 2>&1
fi

if [ "$(nova secgroup-list | grep -F ' dns ' | awk '{print $4;}')" == "" ]; then
    nova secgroup-create dns 'DNS ports' >/dev/null 2>&1
fi

if [ "$(nova secgroup-list-rules dns | grep -F ' 53 ')" == "" ]; then
    nova secgroup-add-rule dns udp 53 53 0.0.0.0/0 >/dev/null 2>&1
fi

if [ "$(nova secgroup-list | grep -F ' web ' | awk '{print $4;}')" == "" ]; then
    nova secgroup-create web 'HTTP and HTTPS ports' >/dev/null 2>&1
fi

if [ "$(nova secgroup-list-rules web | grep -F ' 80 ')" == "" ]; then
    nova secgroup-add-rule web tcp 80 80 0.0.0.0/0 >/dev/null 2>&1
fi

if [ "$(nova secgroup-list-rules web | grep -F ' 443 ')" == "" ]; then
    nova secgroup-add-rule web tcp 443 443 0.0.0.0/0 >/dev/null 2>&1
fi

exit 0
