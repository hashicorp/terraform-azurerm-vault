#!/bin/bash
# This script is meant to be run in the Custom Data of each Azure Instance while it's booting. The script uses the
# run-consul script to configure and start Consul in client mode and then the run-vault script to configure and start
# Vault in server mode. Note that this script assumes it's running in an Azure Image built from the Packer template in
# examples/vault-consul-ami/vault-consul.json.

set -e

# Send the log output from this script to custom-data.log, syslog, and the console
exec > >(tee /var/log/custom-data.log|logger -t custom-data -s 2>/dev/console) 2>&1

# The Packer template puts the TLS certs in these file paths
readonly VAULT_TLS_CERT_FILE="/opt/vault/tls/vault.crt.pem"
readonly VAULT_TLS_KEY_FILE="/opt/vault/tls/vault.key.pem"

# The cluster_tag variables below are filled in via Terraform interpolation
/opt/consul/bin/run-consul --client --scale-set-name "${scale_set_name}" --subscription-id "${subscription_id}" --tenant-id "${tenant_id}" --client-id "${client_id}" --secret-access-key "${secret_access_key}"
/opt/vault/bin/run-vault --azure-account-name "${azure_account_name}" --azure-account-key "${azure_account_key}" --azure-container "${azure_container}" --tls-cert-file "$VAULT_TLS_CERT_FILE"  --tls-key-file "$VAULT_TLS_KEY_FILE"
