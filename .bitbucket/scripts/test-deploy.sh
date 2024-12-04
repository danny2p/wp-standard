#!/bin/bash

# Usage
# ./live-deploy.sh <site-name or uuid>

# Exit on error
set -e

SITE=$1
START=$SECONDS
SITE_LABEL=$(terminus site:info --fields label --format string -- ${SITE})

# Tell slack we're starting this site
SLACK_START="------------- :building_construction: Started ${SITE_LABEL} deployment to Test :building_construction: ------------- \n";
curl -X POST -H 'Content-type: application/json' --data "{'text':'${SLACK_START}'}" $SLACK_WEBHOOK
echo -e "Starting ${SITE} Test Deployment";


# Deploy code to test 
terminus env:deploy $SITE.test --cc -n -q
SLACK="${SITE_LABEL} TEST Code Deployment Finished. Importing config and clearing cache."
curl -X POST -H 'Content-type: application/json' --data "{'text':'${SLACK}'}" $SLACK_WEBHOOK

# Run any post-deploy commands here
terminus env:clear-cache $SITE.test


# Report time to results.
DURATION=$(( SECONDS - START ))
MIN=$(( DURATION / 60 ))
SECONDS_REMAIN=$(( DURATION % 60 ))
# Round $MIN to 0 if it's less than 1
if [ "$MIN" -lt 1 ]; then
  MIN=0
  TOTAL_TIME="${DURATION} seconds"
else
  TOTAL_TIME="${MIN} minutes and ${SECONDS_REMAIN}"
fi

SITE_LINK="https://test-${SITE}.pantheonsite.io";
SLACK=":white_check_mark: Finished ${SITE_LABEL} deployment to Test in ${TOTAL_TIME}. \n ${SITE_LINK}"
curl -X POST -H 'Content-type: application/json' --data "{'text':'${SLACK}'}" $SLACK_WEBHOOK
