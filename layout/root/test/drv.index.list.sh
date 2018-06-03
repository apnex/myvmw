#!/bin/bash
source drv.core

URL="https://my.vmware.com/group/vmware/downloads?p_p_id=ProductIndexPortlet_WAR_itdownloadsportlet&p_p_lifecycle=2&p_p_state=normal&p_p_mode=view&p_p_resource_id=productsAtoZ&p_p_cacheability=cacheLevelPage&p_p_col_id=column-6&p_p_col_pos=1&p_p_col_count=2"
printf "Using cunning cookie distraction to glean VMW product index...\n" 1>&2
PAYLOAD=$(curl --location-trusted -b cookies.txt -X GET \
-A "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/60.0.3112.113 Safari/537.36" \
-H "Cache-Control: no-cache" \
"$URL" 2>/dev/null)

echo "$PAYLOAD" | jq --tab .
