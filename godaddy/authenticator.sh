#!/bin/bash
#
################################################################
#
# Global Variables
#
################################################################
SCRIPT_NAME=`basename $0`
API_KEY=changeme
API_SECRET=changeme
################################################################
#
# Functions
#
################################################################
function write_log
{
        logger -p local1.info -t ${SCRIPT_NAME} "$*"
}
################################################################
#
# Main
#
################################################################
echo "[
  {
    \"data\": \"${CERTBOT_VALIDATION}\",
    \"name\": \"_acme-challenge\",
    \"port\": 80,
    \"priority\": 0,
    \"protocol\": \"string\",
    \"service\": \"string\",
    \"ttl\": 600,
    \"type\": \"TXT\",
    \"weight\": 0
  }
]" > /tmp/${SCRIPT_NAME}-${CERTBOT_DOMAIN}.tmp
curl -X PATCH -H"Authorization: sso-key ${API_KEY}:${API_SECRET}" -H "accept: application/json" -H "Content-Type: application/json" -d @/tmp/${SCRIPT_NAME}-${CERTBOT_DOMAIN}.tmp "https://api.godaddy.com/v1/domains/${CERTBOT_DOMAIN}/records"
echo "CERTBOT_VALIDATION=${CERTBOT_VALIDATION},CERTBOT_DOMAIN=${CERTBOT_DOMAIN}"
write_log "CERTBOT_VALIDATION=${CERTBOT_VALIDATION},CERTBOT_DOMAIN=${CERTBOT_DOMAIN}"

# Sleep to make sure the change has time to propagate over to DNS
sleep 25
