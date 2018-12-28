#!/usr/bin/env bash

set -e
cat <<EOF > foo
Host *
  IdentityFile ~/.ssh/key.pem
  User ubuntu
EOF

# Threatstack (Ubuntu agent install)
# 1. Add the PGP key
curl https://app.threatstack.com/APT-GPG-KEY-THREATSTACK | sudo apt-key add -

# 2. Add repository info
echo "deb https://pkg.threatstack.com/Ubuntu `lsb_release -c | cut -f2` main" | sudo tee /etc/apt/sources.list.d/threatstack.list > /dev/null

# 3. Install and configure the agent
sudo apt-get update && sudo apt-get install threatstack-agent -y && \
sudo cloudsight setup --deploy-key=29c5e5a38c36fbc45cd3325ca737b678hsR6utKVzwUeBFTeTO284T9vrPITbMX9LpldMBwt --ruleset="Base Rule Set" --agent_type=i
