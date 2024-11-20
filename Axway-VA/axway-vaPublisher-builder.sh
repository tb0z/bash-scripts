#!/bin/bash
###########
#
# Axway vaPublisher Builder Script
#
#    Last Modified: 8/14/2019
#    Description:   This script takes CRL endpoint list and transforms into valid vaPublisher format for CRL file import 
#
###########

#Retrieve CRL endpoint list to operate on from user
echo Input CRL endpoint list:
read crlenpointlist 

#Run through bash for loop to create individual CRL publisher data fields; Post sed commands to provide addtional required data tags
for ((i=1;i<=`cat $crlenpointlist | wc -l`;i++));do echo -e [INPUT_SECTION_$i]\\nLOCATION=CRL\;DER\;`sed -n $(($i))p $crlenpointlist` \\nSCHEDULE_CRON_STRING=0 0,6,12,18 \* \* \* \*\\nRETRY_COUNT=3\\nRETRY_FREQUENCY=20;done | sed -e "1s/^/[VAPublisher]\nNUM_INPUT_LOCATIONS=$(awk 'END{print NR}' $crlenpointlist )\n/;" > vaPublisher.$(date +%Y-%m-%d)
