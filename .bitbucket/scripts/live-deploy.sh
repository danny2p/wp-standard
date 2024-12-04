
#!/bin/bash

# Usage
# ./test-live-deploy.sh <site-name or uuid>

# Exit on error
set -e

SITE=$1
START=$SECONDS
SITE_LABEL=$(terminus site:info --fields label --format string -- ${SITE})

# Tell slack we're starting this site
SLACK_START="------------- :lightningbolt-vfx: Started ${SITE_LABEL} deployment to Live :lightningbolt-vfx: ------------- \n";
curl -X POST -H 'Content-type: application/json' --data "{'text':'${SLACK_START}'}" $SLACK_WEBHOOK
echo -e "Starting ${SITE_LABEL} Live Deployment";

# Backup DB only for live prior to deploy, 30 day retention
terminus backup:create --element database --keep-for 30 -- $SITE.live
SLACK="Finished ${SITE_LABEL} Live Backup. Deploying code."
curl -X POST -H 'Content-type: application/json' --data "{'text':'${SLACK}'}" $SLACK_WEBHOOK
terminus env:deploy $SITE.live --cc -n -q

# Run any post-deploy commands here
terminus env:clear-cache $SITE.live

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

SITE_LINK="https://live-${SITE}.pantheonsite.io";
SLACK=":white_check_mark: Finished ${SITE_LABEL} deployment to Live in ${TOTAL_TIME}. \n ${SITE_LINK}"
curl -X POST -H 'Content-type: application/json' --data "{'text':'${SLACK}'}" $SLACK_WEBHOOK