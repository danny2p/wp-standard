#!/bin/bash

# Usage
# ./test-live-deploy.sh <site-name or uuid>

# Exit on error
set -e

SITE=$1
START=$SECONDS
SITE_LABEL=$(terminus site:info --fields label --format string -- ${SITE})
BACKUP=$DO_BACKUP
NOTIFY=$DO_NOTIFY

# Tell slack we're starting this site
SLACK_START="------------- :lightningbolt-vfx: Started ${SITE_LABEL} deployment to Live :lightningbolt-vfx: ------------- \n";
[ $NOTIFY == "Yes" ] && curl -X POST -H 'Content-type: application/json' --data "{'text':'${SLACK_START}'}" $SLACK_WEBHOOK
echo -e "Starting ${SITE_LABEL} Live Deployment";

# Backup DB prior to deploy, 30 day retention
if [ $BACKUP == "Yes" ] 
then 
  terminus backup:create --element database --keep-for 30 -- $SITE.live
  terminus backup:create --element database --keep-for 30 -- $SITE.live
  SLACK="Finished ${SITE_LABEL} Live Backup. Deploying code."
  [ $NOTIFY == "Yes" ] && curl -X POST -H 'Content-type: application/json' --data "{'text':'${SLACK}'}" $SLACK_WEBHOOK
fi

# Deploy code to live 
terminus env:deploy $SITE.live --cc -n -q
SLACK="${SITE_LABEL} LIVE Code Deployment Finished. Importing config and clearing cache."
[ $NOTIFY == "Yes" ] && curl -X POST -H 'Content-type: application/json' --data "{'text':'${SLACK}'}" $SLACK_WEBHOOK

# Run any post-deploy commands here
# terminus env:clear-cache $SITE.live

# Report time to results.
DURATION=$(( SECONDS - START ))
TIME_DIFF=$(bc <<< "scale=2; $DURATION / 60")
MIN=$(printf "%.2f" $TIME_DIFF)
echo -e "Finished ${SITE} in ${MIN} minutes"

SITE_LINK="https://live-${SITE}.pantheonsite.io";
SLACK=":white_check_mark: Finished ${SITE_LABEL} full deployment in ${MIN} minutes. \n ${SITE_LINK}"
[ $NOTIFY == "Yes" ] && curl -X POST -H 'Content-type: application/json' --data "{'text':'${SLACK}'}" $SLACK_WEBHOOK
