#!/bin/bash

# Usage
# ./dev-deploy.sh <site-name or uuid>

# Exit on error
set -e

SITE=$1
DEV=$(echo "${SITE}.dev")
START=$SECONDS
SITE_LABEL=$(terminus site:info --fields label --format string -- ${SITE})
BACKUP=$DO_BACKUP
NOTIFY=$DO_NOTIFY

# Tell slack we're starting this site
SLACK_START="------------- :building_construction: Started ${SITE_LABEL} deployment to Dev :building_construction: ------------- \n";
[ $NOTIFY == "Yes" ] && curl -X POST -H 'Content-type: application/json' --data "{'text':'${SLACK_START}'}" $SLACK_WEBHOOK

echo -e "Starting ${SITE} \n";

# Backup DB prior to deploy, 30 day retention
if [ $BACKUP == "Yes" ] 
then 
  terminus backup:create --element database --keep-for 30 -- $SITE.dev
  SLACK="Finished ${SITE_LABEL} Dev Backup. Deploying code."
  [ $NOTIFY == "Yes" ] && curl -X POST -H 'Content-type: application/json' --data "{'text':'${SLACK}'}" $SLACK_WEBHOOK
fi

# Check site upstream for updates, apply
# terminus site:upstream:clear-cache $1 -q

# terminus connection:set "${1}.dev" git
# STATUS=$(terminus upstream:update:status "${1}.dev")
terminus upstream:updates:apply $DEV --accept-upstream -q
echo -e "Finished applying upstream updates for ${SITE} \n";

# if you want to push these updates to any multidev branch-based 
# environments on a Pantheon site (ie: permanent pre-prod environment)
# you can specify as below

# terminus upstream:updates:apply --updatedb --accept-upstream -- <site>.<env>
  SLACK="${SITE_LABEL} DEV Code Deployment Finished. Importing config and clearing cache."
[ $NOTIFY == "Yes" ] && curl -X POST -H 'Content-type: application/json' --data "{'text':'${SLACK}'}" $SLACK_WEBHOOK

# Run any post-deploy commands here
terminus env:clear-cache $SITE.dev --verbose 3
echo -e "Finished clearing cache for ${SITE} \n";

# Report time to results.
DURATION=$(( SECONDS - START ))
TIME_DIFF=$(bc <<< "scale=2; $DURATION / 60")
MIN=$(printf "%.2f" $TIME_DIFF)
SITE_LINK="https://dev-${SITE}.pantheonsite.io";
SLACK=":white_check_mark: Finished ${SITE_LABEL} deployment to Dev in ${MIN} minutes. \n ${SITE_LINK}"
[ $NOTIFY == "Yes" ] && curl -X POST -H 'Content-type: application/json' --data "{'text':'${SLACK}'}" $SLACK_WEBHOOK

exit 0  # Done!