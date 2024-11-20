#!/bin/bash
###########
#
# F5 Certificate Expiration Alert Report
#
#    Last Modified: 1/4/2022
#    Description:   This script identifies certificates flagged soon to expire and generates a report based on results
#
##########
############################################
# Env Variables 
############################################
mailserver=
maildistros=
############################################
# Global Variables 
############################################
sysstate=$(tmsh show sys failover | awk '{print $2}')
numcertsoontoexpire=$(tmsh run sys crypto check-cert ignore-large-cert-bundles enabled | grep 'will expire' | grep -oP '(?<=in file).*' | cut -d / -f 3 | wc -l)
############################################
# Check Failover Status
#  - If Active continue
#  - If Standby close
############################################
if [ "$sysstate" != "active" ]; then
	exit 0
fi
############################################
# Check Number of Certificates Expiring Soon
#  - If Num > 0 continue 
#  - If Num = 0 Close
############################################
if [ "$numcertsoontoexpire" == "0" ]; then
	exit 0
fi
############################################
# Data Collection
#  - Hostname
#  - Expired Certificates
#  - Certificates Expiring Soon
#  -- SSL Profiles Associated with soon to expire certs
#  -- Virtual Servers Associated with soon to expire certs
############################################
# Identify Hostname
syshost=$(tmsh list sys global-settings hostname| grep hostname|awk '{print $2}')
# Identify Number of Expired Certificates stored on system outside bundles
numcertexpire=$(tmsh run sys crypto check-cert ignore-large-cert-bundles enabled verbose enabled | grep expired | wc -l)
# Identify SSL Certificates Flagged To Expire and print to reference file
tmsh run sys crypto check-cert ignore-large-cert-bundles enabled | grep 'will expire' | grep -oP '(?<=in file).*' | cut -d / -f 3 > f5-certificate-expiration-alert-report_check-cert
# Identify Associated SSL Profiles and print to reference file
for i in `tmsh run sys crypto check-cert ignore-large-cert-bundles enabled | grep 'will expire' | grep -oP '(?<=in file).*'  | awk '{print $1}' | cut -d / -f 3`;do tmsh list ltm profile client-ssl cert | grep -B1 $i | grep client-ssl | awk '{print $4}';done > f5-certificate-expiration-alert-report_ssl-profiles
# Identify Associated Virtual Servers and print to reference file 
for i in `cat f5-certificate-expiration-alert-report_ssl-profiles`;do tmsh show ltm virtual profiles | grep -A2 "ClientSSL Profile: $i"| grep "Virtual Server Name"|awk '{print $5}';done > f5-certificate-expiration-alert-report_virtual-servers
############################################
# Report Generation
############################################
echo "================================================================================" >> f5-certificate-expiration-alert-report.txt
echo "Certificate Expiration Report           " 					>> f5-certificate-expiration-alert-report.txt
echo "  System		: $syshost" 							>> f5-certificate-expiration-alert-report.txt
echo "  State			: $sysstate" 						>> f5-certificate-expiration-alert-report.txt
echo "  Expired Certificates	: $numcertexpire" 					>> f5-certificate-expiration-alert-report.txt
echo "================================================================================" >> f5-certificate-expiration-alert-report.txt
echo "**The Following Certificates Are Flagged to Expire Soon**" 			>> f5-certificate-expiration-alert-report.txt
echo "================================================================================" >> f5-certificate-expiration-alert-report.txt
echo |cat f5-certificate-expiration-alert-report_check-cert				>> f5-certificate-expiration-alert-report.txt
echo "================================================================================" >> f5-certificate-expiration-alert-report.txt
echo "**Associated Profiles**" 								>> f5-certificate-expiration-alert-report.txt
echo "================================================================================" >> f5-certificate-expiration-alert-report.txt
echo |cat f5-certificate-expiration-alert-report_ssl-profiles				>> f5-certificate-expiration-alert-report.txt
echo "================================================================================" >> f5-certificate-expiration-alert-report.txt
echo "**Associated Virtual Servers**" 							>> f5-certificate-expiration-alert-report.txt
echo "================================================================================" >> f5-certificate-expiration-alert-report.txt
echo |cat f5-certificate-expiration-alert-report_virtual-servers			>> f5-certificate-expiration-alert-report.txt
echo "================================================================================" >> f5-certificate-expiration-alert-report.txt
############################################
# Report Formating
############################################
# Insert tab to end of line for Outlook to respect line breaks
sed 's/$/\t/;' f5-certificate-expiration-alert-report.txt > f5-certificate-expiration-alert-report-final.txt
############################################
# Mail Report
############################################
/bin/mail -S smtp=smtp://$mailserver -s "Certificate Expiration Alert Report - $syshost" -c $maildistros < f5-certificate-expiration-alert-report-final.txt
############################################
# Cleanup 
############################################
rm f5-certificate-expiration-alert-report_check-cert
rm f5-certificate-expiration-alert-report_ssl-profiles
rm f5-certificate-expiration-alert-report_virtual-servers
rm f5-certificate-expiration-alert-report.txt
rm f5-certificate-expiration-alert-report-final.txt
