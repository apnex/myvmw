#!/bin/bash

RAW=$1
PAYLOAD=$(./drv.index.list.sh)
read -r -d '' JQSPEC <<CONFIG
	.productCategoryList[0].proList |
		map({
			"name": .name,
			"link": (.actions[] | select(.linkname=="View Download Components") | .target),
		}) |
		. +=
		[{
			"name": "VMware NSX-T",
			"link": "./info/slug/networking_security/vmware_nsx/2_x"
		}]

CONFIG
NEWJSON=$(echo "$PAYLOAD" | jq -r "$JQSPEC")
echo $NEWJSON | jq --tab . > index.json

read -r -d '' JQSPEC <<CONFIG
	. |
		["name", "link"]
		,["-----", "-----"]
		,(.[] | [.name, .link])
	| @csv
CONFIG
if [[ "$RAW" == "json" ]]; then
	echo "$NEWJSON" | jq --tab .
else
	echo "$NEWJSON" | jq -r "$JQSPEC" | sed 's/"//g' | column -s ',' -t
fi
