#!/bin/bash

read -r -d '' XPATHSPEC <<CONFIG
<table class="fn_startOpen pDownloads">
	<tbody>
		<tr>
			<table class="child-table wide">
				<tbody>
					<tr>
						<td class="midProductColumn">{product:=text()}</td>
						<td class="midDateColumn">{date:=text()}</td>
						<td class="buttoncol"><a>{link:=.}</a></td>
					</tr>+
				</tbody>
			</table>
		</tr>+
	</tbody>
</table>
CONFIG
STEP1=$(./xidel --html product.html -e "${XPATHSPEC}")

TYPE1='^<span class="product">(.*)</span>$'
TYPE2='^<span class="date">(.*)</span>$'
TYPE3='^<span class="link"><a href="([^"]+productId=[0-9]+).*" class="button secondary">Go to Downloads</a></span>$'
while read -r ITEM; do
	if [[ $ITEM =~ $TYPE1 ]]; then
		echo "... ${BASH_REMATCH[1]} ..."
	fi
	if [[ $ITEM =~ $TYPE2 ]]; then
		echo "... ${BASH_REMATCH[1]} ..."
	fi
	if [[ $ITEM =~ $TYPE3 ]]; then
		echo "... ${BASH_REMATCH[1]} ..."
	fi
done <<< "$STEP1"

#read -r -d '' XPATHSPEC <<-CONFIG
#<body>
#	<span>
#		{text:=text()}
#		<a>{link:=@href}</a>?
#	</span>+
#</body>
#CONFIG
#STEP2=$(./xidel "$STEP1" -e "${XPATHSPEC}")
#echo "$STEP2"

