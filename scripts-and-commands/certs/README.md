# Get Details About a TLS Certificate
One of the most common tasks once a system is in production for a while is the need to replace expired TLS certificates. The number one symptom that notifies you that this is needed is that back-end system fail to connect and will give an error message in the log files. 

Tracking down why you can't connect is simplified if you can check for the expired use case from the server that is making the connection call. These servers almost never have UI frontends allowing for the certificate view trick we often use in a web browser to check for the dates. This is especially important when server whitelisting rules are in place. 

These linux shell commands are provided to aid in identifying exactly this use case and also to trouble shoot issues that may come up once the new certificate is in place.

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
