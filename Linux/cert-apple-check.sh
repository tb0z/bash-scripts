#!/bin/bash
###########
#
# Apple TLS Requirements Validator Script
#
#    Last Modified: 12/03/2019
#    Description:   This script validates the following Apple Trusted TLS Requirements
#`
#    -  TLS server certificates and issuing CAs using RSA keys must use key sizes greater than or equal to 2048 bits
#    -  TLS server certificates must present the DNS name of the server in the Subject Alternative Name extension of the certificate
#    -  TLS server certificates and issuing CAs must use a hash algorithm from the SHA-2 family in the signature algorithm
#    -  TLS server certificates must have a validity period of 825 days or fewer
#    -  TLS server certificates must contain an ExtendedKeyUsage (EKU) extension containing the id-kp-serverAuth TLS Web Server Authentication OID.1.3.6.1.5.5.7.3.1
#
###########


#Retrieve certificate bundle to operate on from user
echo Input certificate:
read certname

#Key Lenght Check
cert_Key=$(sed -ne 's/^\( *\)Subject:/\1/p;/Public Key Algorithm/{N;;s/^.*\n//;:a;s/^\( *\)\(.*\), /\1\2\n\1/;ta;p;q; }' < <(openssl x509 -in $certname -noout -text -certopt no_subject,no_header,no_version,no_serial,no_signame,no_validity,no_issuer,no_sigdump,no_aux,no_extensions) | awk -F '[^0-9]*' '{print $2}')

#Debug
#echo $cert_Key

if [[ $cert_Key -ge 2048 ]]; then
   Key_check="Passed"
  else
   Key_check="Failed"
fi

#Subject Alternative Name Check
cert_SAN=$(sed -ne 's/^\( *\)Subject:/\1/p;/X509v3 Subject Alternative Name/{N;;s/^.*\n//;:a;s/^\( *\)\(.*\), /\1\2\n\1/;ta;p;q; }' < <( openssl x509 -in $certname -noout -text -certopt no_subject,no_header,no_version,no_serial,no_signame,no_validity,no_issuer,no_pubkey,no_sigdump,no_aux))

#Debug
#echo $cert_SAN

if [[ $cert_SAN == *'DNS'* ]]; then
   SAN_check="Passed"
  else
   SAN_check="Failed"
fi

#Signature Algorithm Check
cert_sig=$(openssl x509 -in $certname -noout -text | grep -m 1 'Signature Algorithm')

#Debug
#echo $cert_sig

if [[ $cert_sig == sha1WithRSAEncryption ]]; then
   sig_check="Failed"
  else
   sig_check="Passed"
fi

#Extended Key Usage OID Check
cert_eku=$(sed -ne 's/^\( *\)Subject:/\1/p;/Extended Key Usage/{N;;s/^.*\n//;:a;s/^\( *\)\(.*\), /\1\2\n\1/;ta;p;q; }' < <(openssl x509 -in $certname -noout -text -certopt no_subject,no_header,no_version,no_serial,no_signame,no_validity,no_issuer,no_sigdump,no_aux,no_pubkey) | grep 'TLS Web Server Authentication')

#Debug
#echo $cert_eku

if [[ -z $cert_eku ]]; then
   eku_check="Failed"
  else
   eku_check="Passed"
fi

#Date Check
startdate=$(date -d "`openssl x509 -in $certname -noout -startdate | cut -d = -f 2`" +%s)
enddate=$(date -d "`openssl x509 -in $certname -noout -enddate | cut -d = -f 2`" +%s)
datediff=$(expr $enddate - $startdate)
num_days=$(expr $datediff / 86400)

#Debug
#echo $num_days

if [[ $num_days -le 825 ]]; then
   date_check="Passed"
  else
   date_check="Failed"
fi

#Print Results

echo
echo Check Key Length............$Key_check
echo Check Signature Algorithm...$sig_check
echo Check SAN...................$SAN_check
echo Check Extended Key Usage....$eku_check
echo Check Lifetime..............$date_check
echo

if [ $Key_check == "Failed" ] || [ $sig_check == "Failed" ] || [ $SAN_check == "Failed" ] || [ $eku_check == "Failed" ] || [ $date_check == "Failed" ]; then
   echo "============================================================"
   echo "= Certificate does not meet Apple Trusted TLS Requirements ="
   echo "============================================================"
   echo
  else

   echo "==========================================================="
   echo "=    Certificate meets Apple Trusted TLS Requirements     ="
   echo "==========================================================="
   echo
fi
