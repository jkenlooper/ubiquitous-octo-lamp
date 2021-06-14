#!/usr/bin/env bash

# Helper script for using terraform commands in a workspace.
# Don't use this script if doing anything other then mundane main commands like
# plan, apply, or destroy.

set -o nounset
set -o pipefail
set -o errexit

# Should be plan, apply, or destroy
terraform_command=$1

test $(basename $PWD) = "_infra" || (echo "Must run this script from the _infra directory." && exit 1)

# The workspace name is the folder that contains the terra.sh script.
script_dir=$(dirname $(realpath $0))
workspace=$(basename $script_dir)
project_dir=$(dirname $PWD)

project_description="Temporary instance for development"

echo "Terraform workspace is: $workspace"
echo "Project description will be: '$project_description'"

set -x

(cd $project_dir
md5sum bin/{add-dev-user.sh,update-sshd-config.sh,set-external-puzzle-massive-in-hosts.sh,setup.sh,infra-development-build.sh} > $script_dir/.bin_checksums
)

terraform workspace select $workspace || \
  terraform workspace new $workspace

test "$workspace" = "$(terraform workspace show)" || (echo "Sanity check to make sure workspace selected matches environment has failed." && exit 1)

terraform $terraform_command -var-file="$script_dir/config.tfvars" \
  -var "project_description=$project_description"