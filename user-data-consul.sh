#!/bin/bash
# This script is meant to be run in the User Data of each EC2 Instance while it's booting. The script uses the
# run-consul script to configure and start Consul in server mode. Note that this script assumes it's running in an AMI
# built from the Packer template in examples/consul-ami/consul.json.

set -e

# Send the log output from this script to user-data.log, syslog, and the console
# From: https://alestic.com/2010/12/ec2-user-data-output/
exec > >(tee /var/log/user-data.log|logger -t custom-data -s 2>/dev/console) 2>&1

# These variables are passed in via Terraform template interplation
/opt/consul/bin/run-consul --server --scale-set-name "${scale_set_name}" --subscription-id "${subscription_id}" --tenant-id "${tenant_id}" --client-id "${client_id}" --secret-access-key "${secret_access_key}"
