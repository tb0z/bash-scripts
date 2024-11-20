#!/bin/bash

#GLOBAL VARS
groups=$(for i in `ipa sudorule-find | grep "Rule name:" | awk '{print $3}'`;do ipa sudorule-show $i | grep "User Groups" | cut -d : -f 2| awk '{ sub(/^[ \t]+/, ""); print}' | sed 's/^ //g' | sed 's/ /\n/g' | sed 's/\(.*\),/\1/';done | sort | uniq)
users=$(for i in `ipa sudorule-find | grep "Rule name:" | awk '{print $3}'`;do ipa sudorule-show $i | grep Users | awk {'first = $1; $1=""; print $0'} | sed 's/^ //g' | sed 's/ /\n/g' | sed 's/\(.*\),/\1/';done | sort | uniq)
users2=$(for j in $groups;do ipa group-show $j | grep "Member users" | cut -d : -f 2| awk '{ sub(/^[ \t]+/, ""); print}' | sed 's/^ //g' | sed 's/ /\n/g' | sed 's/\(.*\),/\1/';done | sort | uniq)

#Report Generation
#Loop 1 - extract users based on ipa sudorule-show
for i in $users;do ipa user-show $i | egrep "User login|First name|Last name|Email" | sed ':a; N; $!ba; s/\n/;/g' | sed 's/;;/\n/g' | sed 's/;/ /g' | sort | uniq;done >> ipa-priv-user-report-temp.txt
#Loop 2 - extract users based on group association
for i in $users2;do ipa user-show $i | egrep "User login|First name|Last name|Email" | sed ':a; N; $!ba; s/\n/;/g' | sed 's/;;/\n/g' | sed 's/;/ /g' | sort | uniq;done >> ipa-priv-user-report-temp.txt
#Remove duplicates
cat ipa-priv-user-report-temp.txt | sort | uniq >> ipa-priv-user-report_$(date +%Y-%^b).txt

#Clean up
rm ipa-priv-user-report-temp.txt
