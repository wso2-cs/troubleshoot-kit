# Get Details About a TLS Certificate

## checkcert
These scripts are for getting the notbefore and notafter dates of a certificate.
* checkcert - uses openssl to fetch
* checkcert_curl - uses curl to fetch 

## checkcertserial
These scripts are for getting the serial number of a certificate
* checkcertserial - returns in default format
* checkcertserialhex - returns in hex format

## getcertchain
This script will show you the certificate chain. Sometimes different versions
of certificates will have differnt intermediate chains and that can lead to 
handshaking issues.
* getcertchain

## serial_audit
These files are used to audit a set of servers to ensure they have the 
same target serial number.
* serial_audit - script to kick off the audit
* server_list.txt - list of the servers to audit. Format like localhost:9443
* target_serial.txt - standard serial format to verify being present 

# Retrieve a certificate
## getcert
This script will retrieve the certificate and write it locally.
* getcert