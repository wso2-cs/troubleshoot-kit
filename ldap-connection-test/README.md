# ldap-test

A Java client to view the time spent for creating LDAP connections and querying. In the meantime, it can be used to view the results for a given query. 

##### 1. You have to configure following parameters first.

    private static String LDAP_URL = "ldap://localhost:10389";
        Connectiion URL
    private static String LDAP_USER = "uid=admin,ou=system";
        LDAP User
    private static String LDAP_PASSWORD = "admin";
        Password of the LDAP User
    private static String LDAP_SEARCH_BASE = "ou=Users,dc=wso2,dc=org";
        User/Group searchbase which you are going to search for.
    private static String SEARCH_FILTER = "(&(objectClass=person)(uid=admin))";
        The filter to search for Users/Groups
    private static String ATTRIBUTE_TO_PRINT = "uid";
        User/Group attribute to print in the log
    private static String LDAP_REFERRAL = "follow";
        Whether to follow or ignore LDAP Referrals
    private static String KEYSTORE = "";
        Java Keystore (TrustStore) file if you are going to use LDAPS
    private static String KEYSTORE_PASSWORD = "wso2carbon";
        Password of the keystore, if keystore is specified
    private static int NUMBER_OF_ITERATIONS = 10;
        Number of iternations to run the same test
    private static long DELAY_BETWEEN_ITERATIONS = 2000; //ms
        Delay between two iterations in ms
        
##### 2. Compile the LDAPTest.java using javac.
```javac LDAPTest.java```

##### 3. Run the test
Some examples on specifying the parameters.
```
java LDAPTest
```
```
java LDAPTest ldappassword
```
```
java LDAPTest ldappassword /path/to/truststore.jks
```
```
java LDAPTest ldappassword /path/to/truststore.jks keystorepassword
```

##### Test LDAP Connection Pooling
```
javac LDAPPoolingTest.java

time java \
 -DENABLE_CONNECTION_POOLING=true \
 -Dcom.sun.jndi.ldap.connect.pool.maxsize=10 \
 -Dcom.sun.jndi.ldap.connect.pool.debug=all \
 -DNUMBER_OF_THREADS=100 \
 -DNUMBER_OF_ITERATIONS=10 \
 -DDELAY_BETWEEN_ITERATIONS=100 \
 -DENABLE_DEBUG=true \
 LDAPPoolingTest
 ```

More system properties related to connection pooling can be found at https://docs.oracle.com/javase/jndi/tutorial/ldap/connect/config.html

---
Derived initial version from http://soasecurity.org and improved later.
