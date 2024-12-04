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
SLACK_START="Started ${SITE_LABEL} Live deployment"
[ $NOTIFY == "Yes" ] && curl -X POST -H 'Content-type: application/json' --data "{'text':'${SLACK_START}'}" $SLACK_WEBHOOK
echo -e "Starting ${SITE_LABEL} Live Deployment";

# Backup DB only for live prior to deploy, 30 day retention
terminus backup:create --element database --keep-for 30 -- $SITE.live

SLACK="Finished ${SITE_LABEL} Live Backup. Deploying code."
[ $NOTIFY == "Yes" ] && curl -X POST -H 'Content-type: application/json' --data "{'text':'${SLACK}'}" $SLACK_WEBHOOK

# Deploy code to live 
terminus env:deploy $SITE.live --cc -n -q

# Run any post-deploy commands here
terminus env:clear-cache $SITE.dev

# Report time to results.
DURATION=$(( SECONDS - START ))
TIME_DIFF=$(bc <<< "scale=2; $DURATION / 60")
MIN=$(printf "%.2f" $TIME_DIFF)

SITE_LINK="https://live-${SITE}.pantheonsite.io";
SLACK=":white_check_mark: Finished ${SITE_LABEL} full deployment in ${MIN} minutes. \n ${SITE_LINK}"
[ $NOTIFY == "Yes" ] && curl -X POST -H 'Content-type: application/json' --data "{'text':'${SLACK}'}" $SLACK_WEBHOOK
