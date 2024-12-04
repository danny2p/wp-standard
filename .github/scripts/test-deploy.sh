#!/bin/bash

# Usage
# ./live-deploy.sh <site-name or uuid>

# Exit on error
set -e

SITE=$1
START=$SECONDS
SITE_LABEL=$(terminus site:info --fields label --format string -- ${SITE})
BACKUP=$DO_BACKUP
NOTIFY=$DO_NOTIFY

# Tell slack we're starting this site
SLACK_START="------------- :building_construction: Started ${SITE_LABEL} deployment to Test :building_construction: ------------- \n";
[ $NOTIFY == "Yes" ] && curl -X POST -H 'Content-type: application/json' --data "{'text':'${SLACK_START}'}" $SLACK_WEBHOOK
echo -e "Starting ${SITE_LABEL} Test Deployment";

# Backup DB prior to deploy, 30 day retention
if [ $BACKUP == "Yes" ] 
then 
  terminus backup:create --element database --keep-for 30 -- $SITE.test
  terminus backup:create --element database --keep-for 30 -- $SITE.test
  SLACK="Finished ${SITE_LABEL} Test Backup. Deploying code."
  [ $NOTIFY == "Yes" ] && curl -X POST -H 'Content-type: application/json' --data "{'text':'${SLACK}'}" $SLACK_WEBHOOK
fi

# Deploy code to test 
terminus env:deploy $SITE.test --cc -n -q
SLACK="${SITE_LABEL} TEST Code Deployment Finished. Importing config and clearing cache."
[ $NOTIFY == "Yes" ] && curl -X POST -H 'Content-type: application/json' --data "{'text':'${SLACK}'}" $SLACK_WEBHOOK

# Run any post-deploy commands here
terminus env:clear-cache $SITE.test

# Report time to results.
DURATION=$(( SECONDS - START ))
TIME_DIFF=$(bc <<< "scale=2; $DURATION / 60")
MIN=$(printf "%.2f" $TIME_DIFF)
echo -e "Finished ${SITE} in ${MIN} minutes"

SITE_LINK="https://test-${SITE}.pantheonsite.io";
SLACK=":white_check_mark: Finished ${SITE_LABEL} full deployment in ${MIN} minutes. \n ${SITE_LINK}"
[ $NOTIFY == "Yes" ] && curl -X POST -H 'Content-type: application/json' --data "{'text':'${SLACK}'}" $SLACK_WEBHOOK
