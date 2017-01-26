#!/bin/bash

nameservers=$(for i in $DNS_SERVERS; do echo -n "'${i}',"; done)
nameservers="${nameservers::-1}"

mkdir -p "data/etc/cloud"
cat > "data/etc/cloud/cloud.cfg" <<EOF
#cloud-config
# vim: syntax=yaml

users:
  - name: default
  - name: ckonstanski
    groups: sudo
    shell: /bin/bash
    sudo: ['ALL=(ALL) NOPASSWD:ALL']
    ssh-authorized-keys:
      - ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQDOU0R+VeVatUbFq/jMwVzivQIFYhDJQKcRGXqk/NJKGRO2kqxAXplaUpG7XuA01NqtQ3yc8th8udWf7WbE5kqg1wpFpmTMJkpTHun2hb/hk15R6LHKDJ75Anv9l9FLbjb6QTW+okE0GKDWO4Taxtb0PPiIwOIuN30YL78prnIcTSgILZRgBqnjtwkB546YU7SvxbkhI8H5M1rMDGMhg97chUl5Gl5TsKme687n1YC6hlvlOqBpnrSsdZSZ7gDmiS+H13lFiLXQWO4k1dkZIqqsg6788cfdPHDUoJ6oJmoFTbZH3SgQsKLfN+0Bg5pIyZ5HCUL40abwVFyEeNL7Sx+/ ckonstanski@sphinkpad

manage-resolv-conf: True

resolv_conf:
  nameservers: [${nameservers}]

write_files:
  - content: |
      127.0.0.1       localhost

      # The following lines are desirable for IPv6 capable hosts
      ::1     localhost       ip6-localhost ip6-loopback
      ff02::1 ip6-allnodes
      ff02::2 ip6-allrouters
    path: /etc/hosts
EOF

exit 0
