#!/bin/bash
source drv.core

PRODUCT="VMware Integrated OpenStack"
INDEX=$(cat index.json)
MYVMW="my.vmware.com"
URI="/group/vmware"

read -r -d '' JQSPEC <<CONFIG
	.[]
		| select(.name=="${PRODUCT}").link
CONFIG
LINK=$(cat index.json | jq -r "$JQSPEC")

URL="https://$MYVMW$URI${LINK:1}"
echo "$LINK"
echo "${URL}"
printf "Reversing shield polarity for: $PRODUCT\n" 1>&2
PAYLOAD=$(curl --location-trusted -b cookies.txt -X GET \
-A "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/60.0.3112.113 Safari/537.36" \
-H "Cache-Control: no-cache" \
"$URL" 2>/dev/null)

echo "$PAYLOAD" > product.html
