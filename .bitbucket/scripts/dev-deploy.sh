#!/bin/bash

# Usage
# ./dev-deploy.sh <site-name or uuid>

# Exit on error
set -e

SITE=$1
DEV=$(echo "${SITE}.dev")
START=$SECONDS
SITE_LABEL=$(terminus site:info --fields label --format string -- ${SITE})

# Tell slack we're starting this site
SLACK_START="------------- :building_construction: Started ${SITE_LABEL} deployment to Dev :building_construction: ------------- \n";
curl -X POST -H 'Content-type: application/json' --data "{'text':'${SLACK_START}'}" $SLACK_WEBHOOK
echo -e "Starting ${SITE}";

# Backup DB prior to deploy, 30 day retention
# terminus backup:create --element database --keep-for 30 -- $SITE.dev

# Check site upstream for updates, apply
# terminus site:upstream:clear-cache $1 -q
# terminus connection:set "${1}.dev" git
# STATUS=$(terminus upstream:update:status "${1}.dev")
terminus upstream:updates:apply $DEV --accept-upstream -q

# if you want to push these updates to any multidev branch-based 
# environments on a Pantheon site (ie: permanent pre-prod environment)
# you can specify as below

# terminus upstream:updates:apply --updatedb --accept-upstream -- <site>.<env>

SLACK="${SITE_LABEL} DEV Code Deployment Finished. Importing config and clearing cache."

curl -X POST -H 'Content-type: application/json' --data "{'text':'${SLACK}'}" $SLACK_WEBHOOK

# Run any post-deploy commands here
terminus env:clear-cache $SITE.dev

# Report time to results.
DURATION=$(( SECONDS - START ))
MIN=$(( DURATION / 60 ))
SECONDS_REMAIN=$(( DURATION % 60 ))
# Round $MIN to 0 if it's less than 1
if [ "$MIN" -lt 1 ]; then
  MIN=0
  TOTAL_TIME="${DURATION} seconds"
else
  TOTAL_TIME="${MIN} minutes ${SECONDS_REMAIN} seconds"
fi

SITE_LINK="https://dev-${SITE}.pantheonsite.io";
SLACK=":white_check_mark: Finished ${SITE_LABEL} deployment to Dev in ${TOTAL_TIME}. \n ${SITE_LINK}"
curl -X POST -H 'Content-type: application/json' --data "{'text':'${SLACK}'}" $SLACK_WEBHOOK