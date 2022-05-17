#APIM distribution configurations below.
pathToBasePack=""
zipFilename=""
extractedPackDirName=""

#MySQL Connector path and the file below
pathToMySQLConnectorFile=""

#Constant. Do not change the below line
RESULT_SUCCESS=1

#APIM deployment patterns. Currently supporting only the PATTERN3
DEPLOYMENT_ACTIVE_ACTIVE="aa"
DEPLOYMENT_FULL="full"

#MySQL Root user credentials below
MYSQL_ROOT_USERNAME=""
MYSQL_ROOT_PASSWORD=""

#Collecting the parsed flag for the process
deploymentPattern=""

#Database names below
APIM_DB_WSO2AM_320=""
SHARED_DB_WSO2AM_320=""

LOG_STATEMENT=""
timestamp=""

printVersion(){
  printf "V1.1.0\n"
}

printUsage(){
  echo "-v  --version => To get the version of this script"
  echo "Eg: \n sh APIM_DEPLOYER_<OS>.sh -v \n"

  echo "-h  --help => Get all the information regarding this script"
  echo "Eg: \n sh APIM_DEPLOYER_<OS>.sh -h \n"

  echo "-d  => Parse the deployment pattern here"
  echo "Available patterns\n  * $DEPLOYMENT_ACTIVE_ACTIVE\n  * $DEPLOYMENT_FULL"
  echo "-f  => Base pack location path"
  echo "-z  => ZIP file name of the APIM pack (Eg: wso2am-3.2.0+<WUM_LEVEL>.full.zip)"
  echo "-b  => Extracted directory name of the pack. You can take this name inside the ZIP file. (Eg: wso2am-3.2.0)"
  echo "-r  => Root user name of the MySQL server"
  echo "-p  => Root user password of the MySQL server"
  echo "-c  => Path of the MySQL JDBC connector Jar (Optional)"
  echo "-a  => APIM database name"
  echo "-s  => SHARED database name"
  
  
  echo "Eg: \n sh APIM_DEPLOYER_<OS>.sh -f /home/sumudu/.wum3/products/wso2am/3.2.0/full/dist/wso2am-3.2.0+<WUM_LEVEL>.full.zip -z wso2am-3.2.0+<WUM_LEVEL>.full.zip -b wso2am-3.2.0 -d full -r root -p PASSWORD -c /home/sumudu/.wum3/products/wso2am/3.2.0/full/dist/mysql-connector-java-8.0.27.jar -a TEST_APIM_DB -s TEST_SHARED_DB"
  echo "Eg: \n sh APIM_DEPLOYER_<OS>.sh -f /home/sumudu/.wum3/products/wso2am/3.2.0/full/dist/wso2am-3.2.0+<WUM_LEVEL>.full.zip -z wso2am-3.2.0+<WUM_LEVEL>.full.zip -b wso2am-3.2.0 -d full -r root -p PASSWORD -a TEST_APIM_DB -s TEST_SHARED_DB"
}

for var in "$@"
    do
      case "$var" in
      "-v" | "--version") 
        printVersion
        exit
      ;;
      "-h" | "--help") 
        printUsage
        exit
      ;;
    esac
done

while getopts "d:f:z:b:p:r:c:a:s:" flags
  do
    case "${flags}" in
      d) deploymentPattern=${OPTARG};;
      b) extractedPackDirName=${OPTARG};;
      z) zipFilename=${OPTARG};;
      f) pathToBasePack=${OPTARG};;
      r) MYSQL_ROOT_USERNAME=${OPTARG};;
      p) MYSQL_ROOT_PASSWORD=${OPTARG};;
      c) pathToMySQLConnectorFile=${OPTARG};;
      a) APIM_DB_WSO2AM_320=${OPTARG};;
      s) SHARED_DB_WSO2AM_320=${OPTARG};;
    esac
  done

ARGS=$(getopt -a --options fzdbprcasvh --long "file,zip,base,deployment,password,version,help,root,connector,apim,shared" -- "$@")

activeActiveDeployment(){
  LOG_STATEMENT="Not Implemented Yet\n"
  printINFOLog
}

fullDistributedDeployment(){
  LOG_STATEMENT="Starting the fully distributed deployment\n"
  printINFOLog
  installUnzip
  copyTheBasePackToDirsPattern3
}

copyTheDBMSConnector(){
  if [ -z "$pathToMySQLConnectorFile" ]
      then
        LOG_STATEMENT="JDBC connector path is not defined. Hence, the script will download the JDBC connector. For that, you need to parse the connector version (hit enter to download the default JDBC connector - 8.0.27)\n\n"
        printWARNLog
        read -p "Connector Version (Eg: 8.0.27): " connector_version
        if [ -z  "$connector_version" ]
          then
            LOG_STATEMENT="JDBC connector version is not defined. Hence downloading the default MySQL JDBC connector (v8.0.27)\n\n"
            printWARNLog
            connector_version="8.0.27"
            wget https://repo1.maven.org/maven2/mysql/mysql-connector-java/${connector_version}/mysql-connector-java-${connector_version}.jar
            LOG_STATEMENT="Downloaded the mySQL JDBC connector $connector_version Jar file\n"
            printINFOLog
            pathToMySQLConnectorFile="mysql-connector-java-${connector_version}.jar"
          else
          LOG_STATEMENT="Downloading the mySQL JDBC connector $connector_version Jar file\n"
          printINFOLog
          wget https://repo1.maven.org/maven2/mysql/mysql-connector-java/${connector_version}/mysql-connector-java-${connector_version}.jar
          LOG_STATEMENT="Downloaded the mySQL JDBC connector $connector_version Jar file\n"
          printINFOLog
          pathToMySQLConnectorFile="mysql-connector-java-${connector_version}.jar"
        fi
  fi

  LOG_STATEMENT="Copying the MySQL JDBC connector $pathToMySQLConnectorFile Jar file [5/19]\n"
  printINFOLog
  cp $pathToMySQLConnectorFile $extractedPackDirName/repository/components/lib

  LOG_STATEMENT="Copied the MySQL JDBC connector\n"
  printINFOLog

  deployThePack
}

copyTheBasePackToDirsPattern3(){
  LOG_STATEMENT="Creating the directory structure [2/19]\n"
  printINFOLog
  rm -rf distributed_deployment
  mkdir distributed_deployment
  cd distributed_deployment
  mkdir 0_gw 1_tm 2_km 3_pub 4_store
  LOG_STATEMENT="Created the directory structure\n"
  printINFOLog

  LOG_STATEMENT="Copying the ZIP pack to 0_gw directory [3/19]\n"
  printINFOLog
  cp $pathToBasePack 0_gw
  LOG_STATEMENT="Copied the ZIP pack to 0_gw directory\n"
  printINFOLog
  
  cd 0_gw
  extractTheBasePack
  removeTheCopiedZip

  copyTheDBMSConnector
}

removeTheCopiedZip(){
  LOG_STATEMENT="Removing the copied ZIP pack inside the 0_gw directory\n"
  printINFOLog
  rm -rf $zipFilename
  LOG_STATEMENT="Removed the copied ZIP pack inside the 0_gw directory\n"
  printINFOLog
}

deployThePack(){
  LOG_STATEMENT="Copying the extracted content to 1_tm  [6/19]\n"
  printINFOLog
  cp -a $extractedPackDirName ../1_tm
  LOG_STATEMENT="Copied the extracted content to 1_tm\n"
  printINFOLog

  LOG_STATEMENT="Copying the extracted content to 2_km [7/19]\n"
  printINFOLog
  cp -a $extractedPackDirName ../2_km
  LOG_STATEMENT="Copied the extracted content to 2_km\n"
  printINFOLog

  LOG_STATEMENT="Copying the extracted content to 3_pub [8/19]\n"
  printINFOLog
  cp -a $extractedPackDirName ../3_pub
  LOG_STATEMENT="Copied the extracted content to 3_pub\n"
  printINFOLog

  LOG_STATEMENT="Copying the extracted content to 4_store [9/19]\n"
  printINFOLog
  cp -a $extractedPackDirName ../4_store
  LOG_STATEMENT="Copied the extracted content to 4_store\n"
  printINFOLog

  cd ..

  LOG_STATEMENT="Creating the gateway worker profile [10/19]\n"
  printINFOLog
  sh 0_gw/$extractedPackDirName/bin/profileSetup.sh -Dprofile=gateway-worker
  LOG_STATEMENT="Created the gateway worker profile\n"
  printINFOLog
 
  LOG_STATEMENT="Creating the traffic manager profile [11/19]\n"
  printINFOLog
  sh 1_tm/$extractedPackDirName/bin/profileSetup.sh -Dprofile=traffic-manager
  LOG_STATEMENT="Created the traffic manager profile\n"
  printINFOLog
  
  LOG_STATEMENT="Creating the key manager profile [12/19]\n"
  printINFOLog
  sh 2_km/$extractedPackDirName/bin/profileSetup.sh -Dprofile=api-key-manager
  LOG_STATEMENT="Created the key manager profile\n"
  printINFOLog

  LOG_STATEMENT="Creating the publisher profile [13/19]\n"
  printINFOLog
  sh 3_pub/$extractedPackDirName/bin/profileSetup.sh -Dprofile=api-publisher
  LOG_STATEMENT="Created the publisher profile\n"
  printINFOLog

  LOG_STATEMENT="Creating the dev portal profile [14/19]\n"
  printINFOLog
  sh 4_store/$extractedPackDirName/bin/profileSetup.sh -Dprofile=api-devportal
  LOG_STATEMENT="Created the dev portal profile\n"
  printINFOLog

  LOG_STATEMENT="Configuring databases by executing scripts [15/19]\n[APIM_DB] => $APIM_DB_WSO2AM_320\n[SHARED_DB] => $SHARED_DB_WSO2AM_320\nYou need to enter the MySQL root password to continue this step\n"
  printINFOLog

  cd 0_gw/$extractedPackDirName/dbscripts
  mysql -u$MYSQL_ROOT_USERNAME -p -e "DROP DATABASE IF EXISTS $APIM_DB_WSO2AM_320; DROP DATABASE IF EXISTS $SHARED_DB_WSO2AM_320; CREATE DATABASE $APIM_DB_WSO2AM_320;CREATE DATABASE $SHARED_DB_WSO2AM_320;USE $APIM_DB_WSO2AM_320;SOURCE apimgt/mysql.sql;USE $SHARED_DB_WSO2AM_320;SOURCE mysql.sql;SHOW TABLES;USE $APIM_DB_WSO2AM_320;SHOW TABLES;"
  
  LOG_STATEMENT="Configured databases by executing scripts successfully\n"
  printINFOLog

  cd ../../..

  rm -rf 0_gw/$extractedPackDirName/repository/conf/deployment.toml
  rm -rf 1_tm/$extractedPackDirName/repository/conf/deployment.toml
  rm -rf 2_km/$extractedPackDirName/repository/conf/deployment.toml
  rm -rf 3_pub/$extractedPackDirName/repository/conf/deployment.toml
  rm -rf 4_store/$extractedPackDirName/repository/conf/deployment.toml

  cd ../toml_files

  cp gateway-worker.toml ../distributed_deployment/0_gw/$extractedPackDirName/repository/conf
  cp traffic-manager.toml ../distributed_deployment/1_tm/$extractedPackDirName/repository/conf
  cp api-key-manager.toml ../distributed_deployment/2_km/$extractedPackDirName/repository/conf
  cp api-publisher.toml ../distributed_deployment/3_pub/$extractedPackDirName/repository/conf
  cp api-devportal.toml ../distributed_deployment/4_store/$extractedPackDirName/repository/conf

  mv ../distributed_deployment/0_gw/$extractedPackDirName/repository/conf/gateway-worker.toml ../distributed_deployment/0_gw/$extractedPackDirName/repository/conf/deployment.toml
  mv ../distributed_deployment/1_tm/$extractedPackDirName/repository/conf/traffic-manager.toml ../distributed_deployment/1_tm/$extractedPackDirName/repository/conf/deployment.toml
  mv ../distributed_deployment/2_km/$extractedPackDirName/repository/conf/api-key-manager.toml ../distributed_deployment/2_km/$extractedPackDirName/repository/conf/deployment.toml
  mv ../distributed_deployment/3_pub/$extractedPackDirName/repository/conf/api-publisher.toml ../distributed_deployment/3_pub/$extractedPackDirName/repository/conf/deployment.toml
  mv ../distributed_deployment/4_store/$extractedPackDirName/repository/conf/api-devportal.toml ../distributed_deployment/4_store/$extractedPackDirName/repository/conf/deployment.toml

  LOG_STATEMENT="Starting to replacing deployment.toml files in all 5 nodes by taking from the toml_files directory [16/19]\n"
  printINFOLog

  LOG_STATEMENT="deployment.toml file replacement is success\n"
  printINFOLog

  cd ../distributed_deployment

  LOG_STATEMENT="Starting to change root user configurations in deployment.toml files [17/19]\n"
  printINFOLog

  #FOR MAC OS,
  #sed -i '' "s/MYSQL_ROOT_USERNAME/$MYSQL_ROOT_USERNAME/gi" 0_gw/$extractedPackDirName/repository/conf/deployment.toml

  sed -i "s/MYSQL_ROOT_USERNAME/$MYSQL_ROOT_USERNAME/gi" 0_gw/$extractedPackDirName/repository/conf/deployment.toml
  sed -i "s/MYSQL_ROOT_USERNAME/$MYSQL_ROOT_USERNAME/gi" 1_tm/$extractedPackDirName/repository/conf/deployment.toml
  sed -i "s/MYSQL_ROOT_USERNAME/$MYSQL_ROOT_USERNAME/gi" 2_km/$extractedPackDirName/repository/conf/deployment.toml
  sed -i "s/MYSQL_ROOT_USERNAME/$MYSQL_ROOT_USERNAME/gi" 3_pub/$extractedPackDirName/repository/conf/deployment.toml
  sed -i "s/MYSQL_ROOT_USERNAME/$MYSQL_ROOT_USERNAME/gi" 4_store/$extractedPackDirName/repository/conf/deployment.toml

  sed -i "s/MYSQL_ROOT_PASSWORD/$MYSQL_ROOT_PASSWORD/gi" 0_gw/$extractedPackDirName/repository/conf/deployment.toml
  sed -i "s/MYSQL_ROOT_PASSWORD/$MYSQL_ROOT_PASSWORD/gi" 1_tm/$extractedPackDirName/repository/conf/deployment.toml
  sed -i "s/MYSQL_ROOT_PASSWORD/$MYSQL_ROOT_PASSWORD/gi" 2_km/$extractedPackDirName/repository/conf/deployment.toml
  sed -i "s/MYSQL_ROOT_PASSWORD/$MYSQL_ROOT_PASSWORD/gi" 3_pub/$extractedPackDirName/repository/conf/deployment.toml
  sed -i "s/MYSQL_ROOT_PASSWORD/$MYSQL_ROOT_PASSWORD/gi" 4_store/$extractedPackDirName/repository/conf/deployment.toml

  LOG_STATEMENT="MySQL root username change is completed successfully files\n"
  printINFOLog

  LOG_STATEMENT="Starting to change [database.shared_db] database name configurations in deployment.toml files [18/19]\n"
  printINFOLog

  sed -i "s/SHARED_DB_WSO2AM_320/$SHARED_DB_WSO2AM_320/gi" 0_gw/$extractedPackDirName/repository/conf/deployment.toml
  sed -i "s/SHARED_DB_WSO2AM_320/$SHARED_DB_WSO2AM_320/gi" 1_tm/$extractedPackDirName/repository/conf/deployment.toml
  sed -i "s/SHARED_DB_WSO2AM_320/$SHARED_DB_WSO2AM_320/gi" 2_km/$extractedPackDirName/repository/conf/deployment.toml
  sed -i "s/SHARED_DB_WSO2AM_320/$SHARED_DB_WSO2AM_320/gi" 3_pub/$extractedPackDirName/repository/conf/deployment.toml
  sed -i "s/SHARED_DB_WSO2AM_320/$SHARED_DB_WSO2AM_320/gi" 4_store/$extractedPackDirName/repository/conf/deployment.toml

  LOG_STATEMENT="[database.shared_db] database name configurations changes successfully completed\n"
  printINFOLog

  LOG_STATEMENT="Starting to change [database.apim_db] database name configurations in deployment.toml files [19/19]\n"
  printINFOLog

  sed -i "s/APIM_DB_WSO2AM_320/$APIM_DB_WSO2AM_320/gi" 1_tm/$extractedPackDirName/repository/conf/deployment.toml
  sed -i "s/APIM_DB_WSO2AM_320/$APIM_DB_WSO2AM_320/gi" 2_km/$extractedPackDirName/repository/conf/deployment.toml
  sed -i "s/APIM_DB_WSO2AM_320/$APIM_DB_WSO2AM_320/gi" 3_pub/$extractedPackDirName/repository/conf/deployment.toml
  sed -i "s/APIM_DB_WSO2AM_320/$APIM_DB_WSO2AM_320/gi" 4_store/$extractedPackDirName/repository/conf/deployment.toml

  LOG_STATEMENT="[database.apim_db] database name configurations changes successfully completed\n"
  printINFOLog

  sleep 2

  LOG_STATEMENT="Distributed deployment is completed. Now you can start all nodes by executing the wso2server.sh file. (OFFSET value already available in the deployment.toml file.)\n"
  printINFOLog

  LOG_STATEMENT="\n\nNODE DETAILS \n\n----------- Key Manager -----------\n\n * Offset: 2\n * Carbon Console URL: https://localhost:9445/carbon\n\n----------- Traffic Manager -----------\n\n * Offset: 1\n * Carbon Console URL: https://localhost:9444/carbon\n\n----------- API Publisher -----------\n\n * Offset: 3\n * Carbon Console URL: https://localhost:9446/carbon\n * Publisher Access URL: https://localhost:9446/publisher\n\n----------- API Dev Portal -----------\n\n * Offset: 4\n * Carbon Console URL: https://localhost:9447/carbon\n * Dev Portal Access URL: https://localhost:9447/devportal\n\n----------- API Gateway -----------\n\n * Offset: 0\n * Carbon Console URL: https://localhost:9443/carbon\n * HTTP URL: https://localhost:8280\n * HTTPS URL: https://localhost:8243\n\n"
  printConfigDetail
}

installUnzip(){
  LOG_STATEMENT="Trying to install Unzip  [1/19]\nYou need to enter the root user credentials to continue\n"
  printINFOLog
  
  sudo apt-get install unzip
  
  LOG_STATEMENT="Installed Unzip\n"
  printINFOLog
}

extractTheBasePack(){
  LOG_STATEMENT="Extracting the ZIP file  [4/19]\n"
  printINFOLog
  
  unzip $zipFilename

  LOG_STATEMENT="ZIP file extracted\n"
  printINFOLog
}

init(){
  LOG_STATEMENT="Starting the distributed deployment script of the WSO2 API Manager 3.2.0\n"
  printINFOLog
  LOG_STATEMENT="Created by Sumudu Weerasuriya from the Integration CS Team\n"
  printINFOLog

  for var in "$@"
    do
      case "$var" in
      "-v" | "--version") 
        printVersion
        exit
      ;;
      "-h" | "--help") 
        printUsage
        exit
      ;;
    esac
    done

    if [ -z "$deploymentPattern" ]
      then
        LOG_STATEMENT="Deployment pattern is not defined\n"
        printERRLog
        exit 1
    fi

    if [ -z "$extractedPackDirName" ]
      then
        LOG_STATEMENT="Extracted ZIP directory name is not defined\n"
        printERRLog
        exit 1
    fi

    if [ -z "$zipFilename" ]
      then
        LOG_STATEMENT="Zip file name is not defined\n"
        printERRLog
        exit 1
    fi

    if [ -z "$pathToBasePack" ]
      then
        LOG_STATEMENT="Base pack path is not defined\n"
        printERRLog
        exit 1
    fi

    if [ -z "$MYSQL_ROOT_USERNAME" ]
      then
        LOG_STATEMENT="MySQL root user name is not defined\n"
        printERRLog
        exit 1
    fi

    if [ -z "$MYSQL_ROOT_PASSWORD" ]
      then
        LOG_STATEMENT="MySQL root user password is not defined\n"
        printERRLog
        exit 1
    fi

    if [ -z "$APIM_DB_WSO2AM_320" ]
      then
        LOG_STATEMENT="APIM database name is not defined\n"
        printERRLog
        exit 1
    fi

    if [ -z "$SHARED_DB_WSO2AM_320" ]
      then
        LOG_STATEMENT="SHARED database name is not defined\n"
        printERRLog
        exit 1
    fi

    LOG_STATEMENT="\n\nDEPLOYMENT DETAILS \n\n* Deployment Pattern: $deploymentPattern \n* Base Pack Path: $pathToBasePack\n* ZIP Name: $zipFilename\n* Directory Name Of The Extracted Content: $extractedPackDirName \n\n"
    printConfigDetail

    LOG_STATEMENT="\n\nDATABASE DETAILS \n\n* ROOT User Name: $MYSQL_ROOT_USERNAME\n* APIM Database Name: $APIM_DB_WSO2AM_320\n* Shared Database Name: $SHARED_DB_WSO2AM_320\n\n"
    printConfigDetail

    case "$deploymentPattern" in
      $DEPLOYMENT_ACTIVE_ACTIVE) 
        activeActiveDeployment
      ;;
      $DEPLOYMENT_FULL) 
        fullDistributedDeployment
      ;;
      *)
        LOG_STATEMENT="Invalid Deployment Pattern"
        printERRLog
        exit 1;;
    esac
}

getSystemTimestamp() {
	timestamp=`date '+%Y-%m-%d %H:%M:%S' | sed 's/\(:[0-9][0-9][0-9]\)[0-9]*$/\1/' `
}

printINFOLog(){
  getSystemTimestamp
  printf "[${timestamp}] INFO - $LOG_STATEMENT"
}

printERRLog(){
  getSystemTimestamp
  printf "[${timestamp}] ERROR - $LOG_STATEMENT"
}

printWARNLog(){
  getSystemTimestamp
  printf "[${timestamp}] WARN - $LOG_STATEMENT"
}

printConfigDetail(){
  getSystemTimestamp
  printf "[${timestamp}] CONFIG_DETAIL \n$LOG_STATEMENT"
}

init
