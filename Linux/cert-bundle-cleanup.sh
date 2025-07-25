#!/bin/bash
###########
#
# F5 Certificate Bundle Cleanup Script
#
#    Created:       7/21/2019 
#    Last Modified: 5/20/2022 
#    Description:   This script scans for and removes expired certificates from a given certificate bundle
#      - Hotfix 2/28/2020: Fixed issue with split function that was only printing every other record 
#      - Feature Update 2/28/2020: Added additional parser for removal and logging of sha1 certificates 
#      - Feature Update 5/20/2022: Added transform and parser for removal and logging of duplicate certificates 
#                                  Added feature to remove blank lines
#                                  Added hotfix to logging 
#
###########

#Retrieve certificate bundle to operate on from user
echo Input certificate bundle:
read bundlename

#Delimit bundle with delimiter = ; and create transform.pem
sed 's/-----BEGIN CERTIFICATE-----/;&/g' $bundlename > transform.pem

#Split individual certificates from bundle naming them as Cert## 
awk 'NR>1{ print > "Cert"++i }' RS=';' transform.pem

#Identify expired certificates and remove  
for i in $(find . -name "Cert*" -print);do if ! openssl x509 -checkend 1 -noout -in $i;then echo  -e `openssl x509 -in $i -noout -subject` \\n "Certificate is expired...removing from bundle" && rm $i;fi;done | tee -a $bundlename-cleanup.$(date +%Y-%m-%d).log 

#Identify sha1 certificates and remove
for i in $(find . -name "Cert*" -print);do if openssl x509 -noout -text -in $i | grep "Signature Algorithm: sha1"; then echo -e `openssl x509 -in $i -noout -subject` \\n "Certificate is sha1...removing from bundle" && rm $i;fi;done | tee -a $bundlename-cleanup.$(date +%Y-%m-%d).log

#Transform name for certificate duplication check
for i in $(find . -name "Cert*" -print); do mv $i $i-`openssl x509 -in $i -noout -fingerprint | openssl sha256 |awk '{print $2}'`;done

#Identify duplicate certificates and remove
if [ $(ls | grep Cert | cut -d - -f 2 | sort | uniq -d | wc -l) -ne 0 ]; then 
	for i in $(find . -name "Cert*" -print | cut -d - -f 2 | sort | uniq -d);do echo -e "DUPLICATE DETECTED" \\n`ls | grep $i` ; openssl x509 -in `ls | grep $i | sed -n '1p'` -noout -subject -fingerprint ; echo -e "Removing" `ls | grep $i | sed -n '1d;p'`; rm `ls | grep $i | sed -n '1d;p'`;done | tee -a $bundlename-cleanup.$(date +%Y-%m-%d).log
else
	echo "No Duplicates Detected" | tee -a $bundlename-cleanup.$(date +%Y-%m-%d).log
fi

#Glue bundle back together
sed '/^$/d' Cert* >> new-$bundlename.pem

#Script Cleanup
find . \( -name "Cert*" -o -name "transform.pem" \) -exec rm {} \;
