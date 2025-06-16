#!/bin/bash

# Ensure /etc/hosts is updated with the provided Baxter IP and hostname

#sudo sh -c "echo '${BAXTER_IP:-172.16.208.51}  ${BAXTER_HOSTNAME:-011608P0034.local}' >> /etc/hosts"

# Start the container normally

exec "$@"