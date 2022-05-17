# APIM_DEPLOYER
This script will help to deploy the API Manager with MySQL databases within few seconds

Thank you for using the APIM Deployer script to deploy the API Manager 4.0.0 in Fully Distributed deployment (TM separated or not)

## For MAC OS users can use the below command to deploy the API Manager 4.0.0 in fully distributed way.

### FORMAT
```bash
sh APIM_DEPLOYER_MAC.sh -f <APIM_ZIP_PATH>/<APIM_ZIP_FILE_NAME> -z <APIM_ZIP_FILE_NAME> -b wso2am-4.0.0 -d <DEPLOYMENT_PATTERN> -r <MYSQL_ROOT_USERNAME> -p <MYSQL_ROOT_PASSWORD> -c <JDBC_CONNECTOR_JAR_LOCATION>/<JDBC_CONNECTOR_JAR_NAME> -a <APIM_DATABASE_NAME> -s <SHARED_DATABASE_NAME>  -u <UPDATE_LEVEL_TO_INSTALL>
```

```bash
sh APIM_DEPLOYER_MAC.sh -z <APIM_ZIP_FILE_NAME> -b wso2am-4.0.0 -d <DEPLOYMENT_PATTERN> -r <MYSQL_ROOT_USERNAME> -p <MYSQL_ROOT_PASSWORD> -a <APIM_DATABASE_NAME> -s <SHARED_DATABASE_NAME>  -u <UPDATE_LEVEL_TO_INSTALL>
```

### EXAMPLE
```bash
sh APIM_DEPLOYER_MAC.sh -f /home/sumudu/.wum3/products/wso2am/4.0.0/wso2am-4.0.0.zip -z wso2am-4.0.0.zip -b wso2am-4.0.0 -d FULL -r root -p PASSWORD -c /home/sumudu/.wum3/products/wso2am/mysql-connector-java-8.0.27.jar -a TEST_APIM_DB -s TEST_SHARED_DB -u 91
```

```bash
sh APIM_DEPLOYER_MAC.sh -z wso2am-4.0.0.zip -b wso2am-4.0.0 -d FULL -r root -p PASSWORD -a TEST_APIM_DB -s TEST_SHARED_DB -u 91
```

## For Linux OS users can use the below command to deploy the API Manager 4.0.0 in fully distributed way.

### FORMAT
```bash
sh APIM_DEPLOYER_LINUX.sh -f <APIM_ZIP_PATH>/<APIM_ZIP_FILE_NAME> -z <APIM_ZIP_FILE_NAME> -b wso2am-4.0.0 -d <DEPLOYMENT_PATTERN> -r <MYSQL_ROOT_USERNAME> -p <MYSQL_ROOT_PASSWORD> -c <JDBC_CONNECTOR_JAR_LOCATION>/<JDBC_CONNECTOR_JAR_NAME> -a <APIM_DATABASE_NAME> -s <SHARED_DATABASE_NAME>  -u <UPDATE_LEVEL_TO_INSTALL>
```

```bash
sh APIM_DEPLOYER_LINUX.sh -z <APIM_ZIP_FILE_NAME> -b wso2am-4.0.0 -d <DEPLOYMENT_PATTERN> -r <MYSQL_ROOT_USERNAME> -p <MYSQL_ROOT_PASSWORD> -a <APIM_DATABASE_NAME> -s <SHARED_DATABASE_NAME>  -u <UPDATE_LEVEL_TO_INSTALL>
```

### EXAMPLE
```bash
sh APIM_DEPLOYER_LINUX.sh -f /home/sumudu/.wum3/products/wso2am/4.0.0/wso2am-4.0.0.zip -z wso2am-4.0.0.zip -b wso2am-4.0.0 -d FULL -r root -p PASSWORD -c /home/sumudu/.wum3/products/wso2am/mysql-connector-java-8.0.27.jar -a TEST_APIM_DB -s TEST_SHARED_DB -u 91
```

```bash
sh APIM_DEPLOYER_LINUX.sh -z wso2am-4.0.0.zip -b wso2am-4.0.0 -d FULL -r root -p PASSWORD -a TEST_APIM_DB -s TEST_SHARED_DB -u 91
```

## Flags 
`-v` => To get the version of this script

```
Eg: \n sh APIM_DEPLOYER_<OS>.sh -v
```

`-h` => Get all the information regarding this script

```
Eg: \n sh APIM_DEPLOYER_<OS>.sh -h
```

`-d` => Parse the deployment pattern here Available patterns

- FULL => Traffic Manager separated deployment. (Control Plane, Traffic Manager and Gateway Worker)
- GWCP => Gateway Worker and Control Plane deployment. (Control Plane and Gateway Worker)

`-f` => Base pack location path (Optional)

`-z` => ZIP file name of the APIM pack (Eg: wso2am-4.0.0.zip)

`-b` => Extracted directory name of the pack. You can take this name inside the ZIP file. (Eg: wso2am-4.0.0)

`-r` => Root user name of the MySQL server

`-p` => Root user password of the MySQL server

`-c` => Path of the MySQL JDBC connector Jar (Optional)

`-a` => APIM database name

`-s` => SHARED database name

`-u` => Update level that needs to update the pack during the deployment. (Optional)
