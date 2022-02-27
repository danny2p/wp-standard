#!/bin/bash

# Add timeout wrapper to deploy process

# Get paths
__dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

SITE=$1
echo -e "Starting ${SITE}";

# Timeout after 15 minutes.
timeout --foreground 15m ${__dir}/deploy-sequence.sh $1
