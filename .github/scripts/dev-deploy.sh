#!/bin/bash

# Usage
# ./dev-deploy.sh <site-name or uuid>

# Exit on error
set -e

SITE=$1
DEV=$(echo "${SITE}.dev")
START=$SECONDS

# Tell slack we're starting this site
SLACK_START="Started ${SITE} deployment to Dev"

#curl -X POST -H 'Content-type: application/json' --data "{'text':'${SLACK_START}'}" $SLACK_WEBHOOK
echo -e "Starting ${SITE}";

# Backup DB prior to deploy, 30 day retention
terminus backup:create --element database --keep-for 30 -- $SITE.dev

# Check site upstream for updates, apply
# terminus site:upstream:clear-cache $1 -q

# terminus connection:set "${1}.dev" git
# STATUS=$(terminus upstream:update:status "${1}.dev")
terminus upstream:updates:apply $DEV --accept-upstream -q

# if you want to push these updates to any multidev branch-based 
# environments on a Pantheon site (ie: permanent pre-prod environment)
# you can specify as below

# terminus upstream:updates:apply --updatedb --accept-upstream -- <site>.<env>

SLACK="${SITE} DEV Code Deployment Finished. Importing config and clearing cache."
#curl -X POST -H 'Content-type: application/json' --data "{'text':'${SLACK}'}" $SLACK_WEBHOOK

# Run any post-deploy commands here
terminus env:clear-cache $SITE.dev

# Report time to results.
DURATION=$(( SECONDS - START ))
TIME_DIFF=$(bc <<< "scale=2; $DURATION / 60")
MIN=$(printf "%.2f" $TIME_DIFF)
SITE_LINK="https://dev-${SITE}.pantheonsite.io";
SLACK=":white_check_mark: Finished ${SITE} deployment to Dev in ${MIN} minutes. \n ${SITE_LINK}"
#curl -X POST -H 'Content-type: application/json' --data "{'text':'${SLACK}'}" $SLACK_WEBHOOK

