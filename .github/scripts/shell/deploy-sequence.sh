#!/bin/bash

# Usage
# ./deploy-sequence.sh <site-name or uuid>

# Exit on error
set -e

SITE=$1
DEV=$(echo "${SITE}.dev")
TEST=$(echo "${SITE}.test")
LIVE=$(echo "${SITE}.live")
START=$SECONDS

echo -e "Starting ${SITE}";

# Check site upstream for updates, apply
terminus site:upstream:clear-cache $1 -q

# terminus connection:set "${1}.dev" git
# STATUS=$(terminus upstream:update:status "${1}.dev")
terminus upstream:updates:apply $DEV -q
echo -e "Deployment to Dev complete (${SITE})";

# Run drush updates on dev, clear cache
# terminus drush "${1}.dev" -- updb -y
# terminus env:clear-cache "${1}.dev"

# Deploy code to test and live
terminus env:deploy $TEST --cc --updatedb -n -q
echo -e "Deployment to Test complete (${SITE})";

# Backup DB only for live prior to deploy, 30 day retention
terminus backup:create --element database --keep-for 30 -- $LIVE
echo -e "Backup of Live complete (${SITE})";

terminus env:deploy $LIVE --cc --updatedb -n -q
echo -e "Deployment to Live complete (${SITE})";

# Report time to results.
DURATION=$(( SECONDS - START ))
TIME_DIFF=$(bc <<< "scale=2; $DURATION / 60")
MIN=$(printf "%.2f" $TIME_DIFF)
echo -e "Finished ${SITE} in ${MIN} minutes"
echo "${SITE},${ID},${MIN}" >> /tmp/results.txt
