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

# Tell slack we're starting this site
SLACK_START="Started ${SITE} deployment"

curl -X POST -H 'Content-type: application/json' --data "{'text':'${SLACK_START}'}" $SLACK_WEBHOOK
echo -e "Starting ${SITE}";

# Check site upstream for updates, apply
terminus site:upstream:clear-cache $1 -q

# terminus connection:set "${1}.dev" git
# STATUS=$(terminus upstream:update:status "${1}.dev")
terminus upstream:updates:apply $DEV -q
SLACK="Finished ${SITE} DEV Deployment"
curl -X POST -H 'Content-type: application/json' --data "{'text':'${SLACK}'}" $SLACK_WEBHOOK

# Run drush updates on dev, clear cache
# terminus drush "${1}.dev" -- updb -y
# terminus env:clear-cache "${1}.dev"

# Deploy code to test and live
terminus env:deploy $TEST --cc --updatedb -n -q
SLACK="Finished ${SITE} TEST Deployment"
curl -X POST -H 'Content-type: application/json' --data "{'text':'${SLACK}'}" $SLACK_WEBHOOK

# Backup DB only for live prior to deploy, 30 day retention
terminus backup:create --element database --keep-for 30 -- $LIVE
SLACK=":white_check_mark: Finished ${SITE} Live Backup"
curl -X POST -H 'Content-type: application/json' --data "{'text':'${SLACK}'}" $SLACK_WEBHOOK
terminus env:deploy $LIVE --cc -n -q

# Report time to results.
DURATION=$(( SECONDS - START ))
TIME_DIFF=$(bc <<< "scale=2; $DURATION / 60")
MIN=$(printf "%.2f" $TIME_DIFF)
echo -e "Finished ${SITE} in ${MIN} minutes"
echo "${SITE},${ID},${MIN}" >> /tmp/results.txt

SITE_LINK="https://live-${SITE}.pantheonsite.io";
SLACK=":white_check_mark: Finished ${SITE} full deployment in ${MIN} minutes. \n ${SITE_LINK}"
curl -X POST -H 'Content-type: application/json' --data "{'text':'${SLACK}'}" $SLACK_WEBHOOK
