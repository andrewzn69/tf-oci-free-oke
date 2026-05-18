#!/usr/bin/env bash
set -euo pipefail

# oke bootstrap - has to run first for node registration
if [[ ! -f /var/run/oke-init.done ]]; then
  curl --fail -H "Authorization: Bearer Oracle" -L0 http://169.254.169.254/opc/v2/instance/metadata/oke_init_script | base64 --decode > /var/run/oke-init.sh
  bash /var/run/oke-init.sh
  touch /var/run/oke-init.done
fi

# expand root filesystem to use full boot volume size - OCI images don't do this automatically
/usr/libexec/oci-growfs -y
