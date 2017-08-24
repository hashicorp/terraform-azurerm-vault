#!/bin/bash
#
# Build the example AMI, copy it to all AWS regions, and make all AMIs public. 
#
# This script is meant to be run in a CircleCI job.
#

set -e

readonly PACKER_TEMPLATE_PATH="/home/ubuntu/$CIRCLE_PROJECT_REPONAME/examples/vault-consul-ami/vault-consul.json"
readonly PACKER_TEMPLATE_DEFAULT_REGION="us-east-1"
readonly AMI_PROPERTIES_FILE="/tmp/ami.properties"
readonly AMI_LIST_MARKDOWN_DIR="/home/ubuntu/$CIRCLE_PROJECT_REPONAME/_docs"
readonly GIT_COMMIT_MESSAGE="Add latest AMI IDs."
readonly GIT_USER_NAME="gruntwork-ci"
readonly GIT_USER_EMAIL="ci@gruntwork.io"

# In CircleCI, every build populates the branch name in CIRCLE_BRANCH...except builds triggered by a new tag, for which
# the CIRCLE_BRANCH env var is empty. We assume tags are only issued against the master branch.
readonly BRANCH_NAME="${CIRCLE_BRANCH:-master}"

readonly PACKER_BUILD_NAME="$1"

if [[ -z "$PACKER_BUILD_NAME" ]]; then
  echo "ERROR: You must pass in the Packer build name as the first argument to this function."
  exit 1
fi

# Build the example AMI. Note that we pass in the example TLS files. WARNING! In a production setting, you should
# decrypt or fetch secrets like this when the AMI boots versus embedding them statically into the AMI.
build-packer-artifact \
  --packer-template-path "$PACKER_TEMPLATE_PATH" \
  --build-name "$PACKER_BUILD_NAME" \
  --output-properties-file "$AMI_PROPERTIES_FILE" \
  --var ca_public_key_path=~/$CIRCLE_PROJECT_REPONAME/examples/vault-consul-ami/tls/ca.crt.pem \
  --var tls_public_key_path=~/$CIRCLE_PROJECT_REPONAME/examples/vault-consul-ami/tls/vault.crt.pem \
  --var tls_private_key_path=~/$CIRCLE_PROJECT_REPONAME/examples/vault-consul-ami/tls/vault.key.pem

# Copy the AMI to all regions and make it public in each
source "$AMI_PROPERTIES_FILE"
publish-ami \
  --all-regions \
  --source-ami-id "$ARTIFACT_ID" \
  --source-ami-region "$PACKER_TEMPLATE_DEFAULT_REGION" \
  --output-markdown > "$AMI_LIST_MARKDOWN_DIR/$PACKER_BUILD_NAME-list.md" \
  --markdown-title-text "$PACKER_BUILD_NAME: Latest Public AMIs" \
  --markdown-description-text "**WARNING! Do NOT use these AMIs in a production setting.** They contain TLS certificate files that are publicly available through this repo and using these AMIs in production would represent a serious security risk. The AMIs are meant only to make initial experiments with this blueprint more convenient."

# Git add, commit, and push the newly created AMI IDs as a markdown doc to the repo
git-add-commit-push \
  --path "$AMI_LIST_MARKDOWN_DIR/$PACKER_BUILD_NAME-list.md" \
  --message "$GIT_COMMIT_MESSAGE" \
  --user-name "$GIT_USER_NAME" \
  --user-email "$GIT_USER_EMAIL" \
  --git-push-behavior "current" \
  --branch-name "$BRANCH_NAME"
