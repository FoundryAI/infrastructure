#!/usr/bin/env bash

set -e

# Threatstack (AWS Linux agent install)
# 1. Add repo location
THREATSTACK_YUM_REPO="/etc/yum.repos.d/threatstack.repo"
cat <<EOF > $THREATSTACK_YUM_REPO
[threatstack]
name=Threat Stack Package Repository
baseurl=https://pkg.threatstack.com/Amazon
enabled=1
gpgcheck=1
EOF
 
# 2. Import PGP Key
sudo wget https://app.threatstack.com/RPM-GPG-KEY-THREATSTACK -O /etc/pki/rpm-gpg/RPM-GPG-KEY-THREATSTACK
sudo rpm --import /etc/pki/rpm-gpg/RPM-GPG-KEY-THREATSTACK
 
# 3. Install and configure the agent
sudo yum -y install threatstack-agent &&\
sudo cloudsight setup --deploy-key=29c5e5a38c36fbc45cd3325ca737b678hsR6utKVzwUeBFTeTO284T9vrPITbMX9LpldMBwt --ruleset="Base Rule Set" --agent_type=i
