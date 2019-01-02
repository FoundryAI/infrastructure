#!/usr/bin/env bash

set -e
curl https://s3.dualstack.us-east-2.amazonaws.com/aws-xray-assets.us-east-2/xray-daemon/aws-xray-daemon-2.x.rpm -o /home/ec2-user/xray.rpm
yum install -y /home/ec2-user/xray.rpm
sed -i -e 's/UDPAddress.*$/UDPAddress: "0.0.0.0:2000"/' /etc/amazon/xray/cfg.yaml
pkill xray

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
