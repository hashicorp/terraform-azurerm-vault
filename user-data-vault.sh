#!/bin/bash
# This script is meant to be run in the User Data of each EC2 Instance while it's booting. The script uses the
# run-consul script to configure and start Consul in client mode and then the run-vault script to configure and start
# Vault in server mode. Note that this script assumes it's running in an AMI built from the Packer template in
# examples/vault-consul-ami/vault-consul.json.

set -e

# Send the log output from this script to user-data.log, syslog, and the console
# From: https://alestic.com/2010/12/ec2-user-data-output/
exec > >(tee /var/log/user-data.log|logger -t user-data -s 2>/dev/console) 2>&1

# The Packer template puts the TLS certs in these file paths
readonly VAULT_TLS_CERT_FILE="/opt/vault/tls/vault.crt.pem"
readonly VAULT_TLS_KEY_FILE="/opt/vault/tls/vault.key.pem"

# The cluster_tag variables below are filled in via Terraform interpolation
/opt/consul/bin/run-consul --client --scale-set-name "${scale_set_name}" --subscription-id "${subscription_id}" --tenant-id "${tenant_id}" --client-id "${client_id}" --secret-access-key "${secret_access_key}"
/opt/vault/bin/run-vault --azure-account-name "${azure_account_name}" --azure-account-key "${azure_account_key}" --azure-container "${azure_container}" --tls-cert-file "$VAULT_TLS_CERT_FILE"  --tls-key-file "$VAULT_TLS_KEY_FILE"
