#!/usr/bin/env bash

# ensure terraform destroy is called on exit
trap 'terraform destroy; exit;' EXIT INT TERM

# configure ssh key associated with $AWS_SSH_KEY_ID
mkdir -p ~/.ssh
chmod 700 ~/.ssh
aws s3 cp s3://chef-cd-citadel/cd-infrastructure-aws ~/.ssh/id_rsa
chmod 600 ~/.ssh/id_rsa

# override terraform backend to use shared s3 bucket
cat > "/workdir/terraform/aws/scenarios/${TF_VAR_scenario}/backend.tf" <<EOF
terraform {
  backend "s3" {
    key     = "chef-server/integration_test-${BUILDKITE_BUILD_NUMBER}.tfstate"
    profile = "${TF_VAR_aws_profile}"
    bucket  = "${TF_VAR_aws_profile}-terraform-state"
    region  = "${TF_VAR_aws_region}"
  }
}
EOF

# set install version to latest in "stable" channel if a version was not provided
[[ -z "$INSTALL_VERSION" ]] || export INSTALL_VERSION="$(mixlib-install list-versions chef-server stable | tail -n 1)"

# set upgrade version to latest in "current" channel if a version was not provided
[[ -z "$UPGRADE_VERSION" ]] || export UPGRADE_VERSION="$(mixlib-install list-versions chef-server current | tail -n 1)"

# set version artifact urls
platform="$TF_VAR_platform"
export TF_VAR_install_version_url=$(for channel in unstable current stable; do mixlib-install download chef-server --url -c $channel -a x86_64 -p $(echo ${platform%-*} | sed 's/rhel/el/') -l ${platform##*-} -v $INSTALL_VERSION 2>/dev/null && break; done | head -n 1)
export TF_VAR_upgrade_version_url=$(for channel in unstable current stable; do mixlib-install download chef-server --url -c $channel -a x86_64 -p $(echo ${platform%-*} | sed 's/rhel/el/') -l ${platform##*-} -v $UPGRADE_VERSION 2>/dev/null && break; done | head -n 1)

cat <<EOF

BEGIN SCENARIO

 Scenario: $TF_VAR_scenario
 Platform: $TF_VAR_platform
     IPv6: $TF_VAR_enable_ipv6
  Install: $INSTALL_VERSION
  Install URL: $TF_VAR_install_version_url
  Upgrade: $UPGRADE_VERSION
  Upgrade URL: $TF_VAR_upgrade_version_url

EOF

cd "/workdir/terraform/aws/scenarios/${TF_VAR_scenario}"

# initialize the terraform scenario
terraform init

# run the terraform scenario
terraform apply
