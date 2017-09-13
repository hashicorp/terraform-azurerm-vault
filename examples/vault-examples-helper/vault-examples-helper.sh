#!/bin/bash
# A script that is meant to be used with the private Valut cluster examples to:
#
# 1. Wait for the Vault server cluster to come up.
# 2. Print out the IP addresses of the Vault servers.
# 3. Print out some example commands you can run against your Vault servers.

set -e

readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly SCRIPT_NAME="$(basename "$0")"

readonly MAX_RETRIES=30
readonly SLEEP_BETWEEN_RETRIES_SEC=10

function log {
  local readonly level="$1"
  local readonly message="$2"
  local readonly timestamp=$(date +"%Y-%m-%d %H:%M:%S")
  >&2 echo -e "${timestamp} [${level}] [$SCRIPT_NAME] ${message}"
}

function log_info {
  local readonly message="$1"
  log "INFO" "$message"
}

function log_warn {
  local readonly message="$1"
  log "WARN" "$message"
}

function log_error {
  local readonly message="$1"
  log "ERROR" "$message"
}

function assert_is_installed {
  local readonly name="$1"

  if [[ ! $(command -v ${name}) ]]; then
    log_error "The binary '$name' is required by this script but is not installed or in the system's PATH."
    exit 1
  fi
}

function get_optional_terraform_output {
  local readonly output_name="$1"
  terraform output -no-color "$output_name"
}

function get_required_terraform_output {
  local readonly output_name="$1"
  local output_value

  output_value=$(get_optional_terraform_output "$output_name")

  if [[ -z "$output_value" ]]; then
    log_error "Unable to find a value for Terraform output $output_name"
    exit 1
  fi

  echo "$output_value"
}

#
# Usage: join SEPARATOR ARRAY
#
# Joins the elements of ARRAY with the SEPARATOR character between them.
#
# Examples:
#
# join ", " ("A" "B" "C")
#   Returns: "A, B, C"
#
function join {
  local readonly separator="$1"
  shift
  local readonly values=("$@")

  printf "%s$separator" "${values[@]}" | sed "s/$separator$//"
}

function wait_for_vault_server_to_come_up {
  local readonly server_ip="$1"

  for (( i=1; i<="$MAX_RETRIES"; i++ )); do
    local readonly vault_health_url="https://$server_ip:8200/v1/sys/health"
    log_info "Checking health of Vault server via URL $vault_health_url"

    local response
    local status
    local body

    response=$(curl --show-error --location --insecure --silent --write-out "HTTPSTATUS:%{http_code}" "$vault_health_url" || true)
    status=$(echo "$response" | tr -d '\n' | sed -e 's/.*HTTPSTATUS://')
    body=$(echo "$response" | sed -e 's/HTTPSTATUS\:.*//g')

    log_info "Got a $status response from Vault server $server_ip with body:\n$body"

    # Response code for the health check endpoint are defined here: https://www.vaultproject.io/api/system/health.html

    if [[ "$status" -eq 200 ]]; then
      log_info "Vault server $server_ip is initialized, unsealed, and active."
      return
    elif [[ "$status" -eq 429 ]]; then
      log_info "Vault server $server_ip is unsealed and in standby mode."
      return
    elif [[ "$status" -eq 501 ]]; then
      log_info "Vault server $server_ip is uninitialized."
      return
    elif [[ "$status" -eq 503 ]]; then
      log_info "Vault server $server_ip is sealed."
      return
    else
      log_info "Vault server $server_ip returned unexpected status code $status. Will sleep for $SLEEP_BETWEEN_RETRIES_SEC seconds and check again."
      sleep "$SLEEP_BETWEEN_RETRIES_SEC"
    fi
  done

  log_error "Did not get a successful response code from Vault server $server_ip after $MAX_RETRIES retries."
  exit 1
}

function print_instructions {
  local num_servers
  local load_balancer_ip
  local admin_user_name

  num_servers=$(get_required_terraform_output "vault_cluster_size")
  load_balancer_ip=$(get_required_terraform_output "load_balancer_ip_address")
  admin_user_name=$(get_required_terraform_output "vault_admin_user_name")

  local instructions=()
  instructions+=("\nYour Vault servers are running behind the load balancer at the following IP address:\n\n${load_balancer_ip/#/    }\n")

  instructions+=("To initialize your Vault cluster, SSH to the first of the servers and run the init command:\n")
  instructions+=("    ssh -p 2200 $admin_user_name@$load_balancer_ip")
  instructions+=("    vault init")

  instructions+=("\nTo unseal your Vault cluster, SSH to each of the servers and run the unseal command with 3 of the 5 unseal keys:\n")
  local counter
  counter=0

  while [[  $counter -lt $num_servers ]]; do
    instructions+=("    ssh -p 220${counter} $admin_user_name@$load_balancer_ip")
    instructions+=("    vault unseal (run this 3 times)\n")
    let counter=counter+1
  done

  instructions+=("\nOnce your cluster is unsealed, you can read and write secrets via the load balancer:\n")
  instructions+=("    vault auth -address=https://$load_balancer_ip")
  instructions+=("    vault write -address=https://$load_balancer_ip secret/example value=secret")
  instructions+=("    vault read -address=https://$load_balancer_ip secret/example")

  local instructions_str
  instructions_str=$(join "\n" "${instructions[@]}")

  echo -e "$instructions_str\n"
}

function run {
  assert_is_installed "jq"
  assert_is_installed "terraform"
  assert_is_installed "curl"

  local load_balancer_ip=$(get_required_terraform_output "load_balancer_ip_address")

  wait_for_vault_server_to_come_up "$load_balancer_ip"
  print_instructions
}

run