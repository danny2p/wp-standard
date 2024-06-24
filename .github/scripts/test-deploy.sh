#!/bin/bash

# Usage
# ./live-deploy.sh <site-name or uuid>

# Exit on error
set -e

SITE=$1
START=$SECONDS

# Tell slack we're starting this site
SLACK_START="Started ${SITE} Test deployment"
curl -X POST -H 'Content-type: application/json' --data "{'text':'${SLACK_START}'}" $SLACK_WEBHOOK
echo -e "Starting ${SITE} Test Deployment";

# Deploy code to test 
terminus env:deploy $SITE.test --cc --updatedb -n -q
SLACK="${SITE} TEST Code Deployment Finished. Importing config and clearing cache."
curl -X POST -H 'Content-type: application/json' --data "{'text':'${SLACK}'}" $SLACK_WEBHOOK

#import config, clear cache if needed
# Run drush config import, clear cache
#terminus drush $SITE.dev -- cim -y
#terminus env:clear-cache $SITE.dev


# Report time to results.
DURATION=$(( SECONDS - START ))
TIME_DIFF=$(bc <<< "scale=2; $DURATION / 60")
MIN=$(printf "%.2f" $TIME_DIFF)
echo -e "Finished ${SITE} in ${MIN} minutes"
echo "${SITE},${ID},${MIN}" >> /tmp/results.txt

SITE_LINK="https://test-${SITE}.pantheonsite.io";
SLACK=":white_check_mark: Finished ${SITE} full deployment in ${MIN} minutes. \n ${SITE_LINK}"
curl -X POST -H 'Content-type: application/json' --data "{'text':'${SLACK}'}" $SLACK_WEBHOOK
