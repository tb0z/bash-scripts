#!/bin/bash
###########
#
# Axway Enterprise Validation Authority Manual CRL Fetch & Import Script
#
#    Created:       03/30/2020
#    Last Modified: 04/02/2020
#    Description:   This script manually fetches crls using curl with specified headers and imports
#                   fetched crls to the crldb using crlutil toolset
#
###########
#Global VARs
###########
proxyURL=
logLOC=
vaPORT=
###########
#Local VARs
###########
crldpURL=
crlFN=
###########
#-Template: This is a template if needed to add additional CRLs for manual fetch and import
#  The following variables are required to be filled out upon adding additional crls...
#       $crldpURL = crl endpoint for fetching
#       $crlFN = local crl filename
###########
##CRL Endpoint: $crldpURL
#echo "CRL Import for $crldpURL" >> $logLOC
#echo -e "\n" >> $logLOC
#
##Pull certificate crl using curl with customized headers
#curl -vvv -o /var/tmp/$crlFN.`date +%Y-%m-%d` -H "Accept:*/*" $crldpURL -x $proxyURL  &>> $logLOC
#echo -e "\n" >> $logLOC
#
##Import certificate crl to crldb using crlutil
#/va/inst/va/tools/crlutil -command publish_crl -encoding der -crlFile /var/tmp/$crlFN.`date +%Y-%m-%d` -url `hostname -f`:$vaPORT  &>>  $logLOC
#echo -e "\n" >> $logLOC
#
##Remove CRL after ingest into CRLDB
#rm /var/tmp/$crlFN.`date +%Y-%m-%d`
#
#####################################################################################################################
#Manual CRL Import Log Header
echo -------------------------------------------------------------------->> $logLOC
echo Manual CRL Import Trigger: `date` >> $logLOC
echo -------------------------------------------------------------------->> $logLOC
echo -e "\n" >> $logLOC
##CRL Endpoint: $crldpURL
echo "CRL Import for $crldpURL:" >> $logLOC
echo -e "\n" >> $logLOC
#Pull certificate crl using curl with customized headers
curl -vvv -o /var/tmp/$crldpURL.`date +%Y-%m-%d` -H "Accept:*/*" $crldpURL -x $proxyURL  &>> $logLOC
echo -e "\n" >> $logLOC
#Import certificate crl to crldb using crlutil
/va/inst/va/tools/crlutil -command publish_crl -encoding der -crlFile /var/tmp/$crldpURL.`date +%Y-%m-%d` -url `hostname -f`:$vaPORT &>> $logLOC
echo -e "\n" >> $logLOC
#Remove CRL after ingest into CRLDB
rm /var/tmp/$crldpURL.`date +%Y-%m-%d`
#Manual CRL Import Log Footer
echo ----------------------- >> $logLOC
echo -e "\n" >> $logLOC
#####################################################################################################################
