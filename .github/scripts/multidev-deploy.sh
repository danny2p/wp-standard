#!/bin/bash

# Usage
# ./dev-deploy.sh <site-name or uuid> 
# called from deploy-dev.yml workflow

# Exit on error
set -e

SITE=$1
SITE_ENV=$(echo "${SITE}.${CI_BRANCH}")
START=$SECONDS

# Tell slack we're starting this site
SLACK_START="Started ${SITE} deployment"
curl -X POST -H 'Content-type: application/json' --data "{'text':'${SLACK_START}'}" $SLACK_WEBHOOK
echo -e "Starting ${SITE}";

# Tell slack we're creating multidev
SLACK_START="Creating Multidev ${CI_BRANCH} for ${SITE}"
curl -X POST -H 'Content-type: application/json' --data "{'text':'${SLACK_START}'}" $SLACK_WEBHOOK
echo -e "Creating Multidev ${CI_BRANCH} for ${SITE}";

# Create a new multidev environment (or push to an existing one)
terminus -n build:env:create "$SITE.$ENV" "$CI_BRANCH" --yes

# Check site upstream for updates, apply
terminus site:upstream:clear-cache $SITE -q

# terminus connection:set "${1}.dev" git
# STATUS=$(terminus upstream:update:status "${1}.dev")
terminus upstream:updates:apply $SITE.$ENV --updatedb -q
SLACK="Finished ${SITE} ${ENV} Deployment"
curl -X POST -H 'Content-type: application/json' --data "{'text':'${SLACK}'}" $SLACK_WEBHOOK

# Run drush config import, clear cache
# terminus drush "${1}.dev" -- cim -y
terminus env:clear-cache "$SITE.$ENV"

# Report time to results.
DURATION=$(( SECONDS - START ))
TIME_DIFF=$(bc <<< "scale=2; $DURATION / 60")
MIN=$(printf "%.2f" $TIME_DIFF)
SITE_LINK="https://live-${SITE}.pantheonsite.io";
SLACK=":white_check_mark: Finished ${SITE} deployment in ${MIN} minutes. \n ${SITE_LINK}"
curl -X POST -H 'Content-type: application/json' --data "{'text':'${SLACK}'}" $SLACK_WEBHOOK