#!/usr/bin/env bash

set -xeu

echo "No, really, don't do this."
exit -1

# !!!
# This will likely corrupt your Azure Cloud Shell stateful home directory.
# You should not do this with a Cloud Shell (or Azure File Share) that you care about.
# !!!

# This will have mounted the home dir of your Azure cloud shell locally.
# This requires an SSH proxy VM in your File Share region.
# When I tested, somewhat expectedly, changes made locally were not reflected in my browser
# Azure Cloud Shell instance until I closed it and let it be recreated (I assume a Pod
# was recycled, and the cifs mount was detached/reattached...)

MNT_POINT="$HOME/az/azure_share"
MNT_POINT2="$HOME/az/azure_share_inner"
MNT_POINT3="$HOME/az/azure_share_inner_bindfs"

sudo umount -lf "${MNT_POINT3}" || true
sudo umount -lf "${MNT_POINT2}" || true
sudo umount -lf "${MNT_POINT}" || true
rm -rf "${MNT_POINT}" "${MNT_POINT2}" "${MNT_POINT3}"
mkdir -p "${MNT_POINT}" "${MNT_POINT2}" "${MNT_POINT3}"

SSH_PUBLIC_KEY="$HOME/.azure/id_rsa"

# Booted with:
# az group create --name "test" --location "westus" # note loc must be same as cloud shell file share loc
# az vm create --name "test" --image "coreos" --admin-username "${USERNAME}" --ssh-key "${SSH_PUBLIC_KEY}"
PROXY_VM_IP="13.91.104.38"

SHARE_NAME="cs-cole-mickens-gmail-com-10033fff877a6a35"
SHARE_USERNAME="cs4aff271eee9bex4441xb9b"
SHARE_PASSWORD="Sgm6BXo+4Eyb9KjXA0iMALaL/p+Y7COBzH5jHeHTx+s8/D3UK8os7RLvE6uTQayjODLSIAApwAT8tuvEBxcNVQ=="

sudo ssh -N -i "${SSH_PUBLIC_KEY}" \
    -L "138:${SHARE_USERNAME}.file.core.windows.net:138" \
    -L "139:${SHARE_USERNAME}.file.core.windows.net:139" \
    -L "445:${SHARE_USERNAME}.file.core.windows.net:445" \
    "${USERNAME}@${PROXY_VM_IP}" &

sudo mount \
    -t cifs \
    "//127.0.0.1/${SHARE_NAME}" \
    "${MNT_POINT}" \
    -o "vers=3.0,username=${SHARE_USERNAME},password=${SHARE_PASSWORD},dir_mode=0777,file_mode=0777,sec=ntlmssp"

sudo mount "${MNT_POINT}/.cloudconsole/acc_${USERNAME}.img" "${MNT_POINT2}"
sudo bindfs -u "${USERNAME}" "${MNT_POINT2}" "${MNT_POINT3}"
