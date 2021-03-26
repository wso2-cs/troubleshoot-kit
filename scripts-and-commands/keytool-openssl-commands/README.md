# OpenSSL-Essentials
OpenSSL Essentials commands for linux

**OPEN SSL Show Certificate**

    openssl s_client -showcerts -connect www.example.com:443

**Generate a Private Key**

    openssl genrsa -out <private_key_name> <key_length>

**Generate a Private Key and a CSR**

    openssl req -newkey rsa:2048 -nodes -keyout domain.key -out domain.csr

**Generate a CSR from an Existing Private Key**

    openssl req -key domain.key -new -out domain.csr

**Generate a CSR from an Existing Certificate and Private Key**

    openssl x509 -in domain.crt -signkey domain.key -x509toreq -out domain.csr

**Generate a Self-Signed Certificate (With private key in one command)**

    openssl req -newkey rsa:2048 -nodes -keyout domain.key -x509 -days 365 -out domain.crt

**Generate a Self-Signed Certificate from an Existing Private Key**

    openssl req -key domain.key -new -x509 -days 365 -out domain.crt

**Generate a Self-Signed Certificate from an Existing Private Key and CSR**

    openssl x509 -signkey domain.key -in domain.csr -req -days 365 -out domain.crt

**View Certificate Entries**

    openssl x509 -text -noout -in domain.crt
    
**Convert a DER file (.crt .cer .der) to PEM**

    openssl x509 -inform der -in certificate.cer -out certificate.pem

**Convert a PEM file to DER**

    openssl x509 -outform der -in certificate.pem -out certificate.der

**Convert a PKCS#12 file (.pfx .p12) containing a private key and certificates to PEM**

    openssl pkcs12 -in keyStore.pfx -out keyStore.pem -nodes

**Convert a PEM certificate file and a private key to PKCS#12 (.pfx .p12)**

    openssl pkcs12 -export -out certificate.pfx -inkey privateKey.key -in certificate.crt -certfile CACert.crt


**Convert a pfx to java keystore**

    keytool -importkeystore -srckeystore mykeystore.p12 -destkeystore clientcert.jks -srcstoretype pkcs12 -deststoretype JKS

**Convert PEM to CRT (.CRT file)**

    openssl x509 -outform der -in certificate.pem -out certificate.crt  
    
**own bundle file from CRT files**

    cat EssentialSSLCA_2.crt intermediate.crt root.crt > yourDomain.ca-bundle

***Reference***
[1] https://www.digitalocean.com/community/tutorials/openssl-essentials-working-with-ssl-certificates-private-keys-and-csrs
