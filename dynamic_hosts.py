#!/usr/bin/python

from __future__ import print_function
import yaml
import json
import sys
import os


def doit():
    ENV_YAML_PATH = os.path.dirname(__file__) + "/conf/env.yaml"
    environ = ""
    for env in ["lab"]:
        if env in os.path.basename(__file__):
            environ = env
            break
    if environ == "":
        print("Unable to determine environment. Exiting.", file=sys.stderr)
        sys.exit(1)
    if not os.path.isfile(ENV_YAML_PATH):
        print("Unable to find env.yaml. Exiting.", file=sys.stderr)
        sys.exit(1)
    with open(ENV_YAML_PATH, 'r') as stream:
        config = yaml.load(stream)
        hosts = []
        hostvars = {}
        outobj = {}
        for x in config["environments"]:
            for e in x:
                if e == environ:
                    for r in x[e]:
                        for region in r:
                            for i in r[region]["instances"]:
                                for instance in i:
                                    hosts.append(instance)
                                    hostvars[instance] = {"username": r[region]["username"],
                                                          "tenant_name": r[region]["tenant_name"],
                                                          "tenant_id": r[region]["tenant_id"],
                                                          "endpoint": r[region]["endpoint"],
                                                          "region": r[region]["region"],
                                                          "ansible_ssh_host": i[instance]["ansible_ssh_host"],
                                                          "ansible_ssh_user": i[instance]["ansible_ssh_user"],
                                                          "ansible_ssh_private_key_file": i[instance]["ansible_ssh_private_key_file"],
                                                          "ansible_python_interpreter": i[instance]["ansible_python_interpreter"],
                                                          "fqdn": i[instance]["fqdn"]}
        outobj["target"] = {"hosts": hosts}
        outobj["_meta"] = {"hostvars": hostvars}
        print(json.dumps(outobj))


if __name__ == "__main__":
    doit()
sys.exit(0)
