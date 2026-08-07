#APIM distribution configurations below.
pathToBasePack=""
zipFilename=""
extractedPackDirName=""

#MySQL Connector path and the file below
pathToMySQLConnectorFile=""

#Constant. Do not change the below line
RESULT_SUCCESS=1

#APIM deployment patterns.
DEPLOYMENT_ACTIVE_ACTIVE="ACTIVE"
DEPLOYMENT_GWCP="GWCP"
DEPLOYMENT_FULL="FULL"

#MySQL Root user credentials below
MYSQL_ROOT_USERNAME=""
MYSQL_ROOT_PASSWORD=""

#Collecting the parsed flag for the process
deploymentPattern=""

#Database names below
APIM_DB_WSO2AM_4xx=""
SHARED_DB_WSO2AM_4xx=""

UPDATE_LEVEL=0
UPDATE_SKIP_LEVEL=0

LOG_STATEMENT=""
timestamp=""

printVersion(){
  printf "V2.0.0\n"
}

printUsage(){
  echo "-v  --version => To get the version of this script"
  echo "Eg: \n sh APIM_DEPLOYER_<OS>.sh -v \n"

  echo "-h  --help => Get all the information regarding this script"
  echo "Eg: \n sh APIM_DEPLOYER_<OS>.sh -h \n"

  echo "-d  => Parse the deployment pattern here"
  echo "Available patterns\n  * $DEPLOYMENT_ACTIVE_ACTIVE\n  * $DEPLOYMENT_FULL\n  * $DEPLOYMENT_FULL"
  echo "-f  => Base pack location path"
  echo "-z  => ZIP file name of the APIM pack (Eg: wso2am-4.2.0.zip)"
  echo "-b  => Extracted directory name of the pack. You can take this name inside the ZIP file. (Eg: wso2am-4.2.0)"
  echo "-r  => Root user name of the MySQL server"
  echo "-p  => Root user password of the MySQL server"
  echo "-c  => Path of the MySQL JDBC connector Jar (Optional)"
  echo "-a  => APIM database name"
  echo "-s  => SHARED database name"
  echo "-u  => Update level that needs to update the pack. (Optional)"
  
  echo "Eg: \n sh APIM_DEPLOYER_<OS>.sh -f /home/suza/.wum3/products/wso2am/4.2.0/wso2am-4.2.0.zip -z wso2am-4.2.0.zip -b wso2am-4.2.0 -d FULL -r root -p PASSWORD -c /home/suza/.wum3/products/wso2am/mysql-connector-java-8.0.27.jar -a TEST_APIM_DB -s TEST_SHARED_DB -u 100"
  echo "Eg: \n sh APIM_DEPLOYER_<OS>.sh -f /home/suza/.wum3/products/wso2am/4.4.0/wso2am-4.4.0.zip  -z wso2am-4.4.0.zip -b wso2am-4.4.0 -d FULL -r root -p PASSWORD -a TEST_APIM_DB -s TEST_SHARED_DB -u 100"
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

while getopts "d:f:z:b:p:r:c:a:s:u:" flags
  do
    case "${flags}" in
      d) deploymentPattern=${OPTARG};;
      b) extractedPackDirName=${OPTARG};;
      z) zipFilename=${OPTARG};;
      f) pathToBasePack=${OPTARG};;
      r) MYSQL_ROOT_USERNAME=${OPTARG};;
      p) MYSQL_ROOT_PASSWORD=${OPTARG};;
      c) pathToMySQLConnectorFile=${OPTARG};;
      a) APIM_DB_WSO2AM_4xx=${OPTARG};;
      s) SHARED_DB_WSO2AM_4xx=${OPTARG};;
      u) UPDATE_LEVEL=${OPTARG};;
    esac
  done

ARGS=$(getopt -a --options fzdbprcasvhu --long "file,zip,base,deployment,password,version,help,root,connector,apim,shared,update" -- "$@")

ActiveActiveDeployment(){
  LOG_STATEMENT="Starting Active-Active deployment\n"
  printINFOLog
  installWget
  copyTheBasePackToDirs
}

GWCPDeployment(){
  LOG_STATEMENT="Starting CP GW deployment\n"
  printINFOLog
  installWget
  copyTheBasePackToDirs
}

TMSeparatedDeployment(){
  LOG_STATEMENT="Starting Traffic Manager separated deployment\n"
  printINFOLog
  installWget
  copyTheBasePackToDirs
}

checkTheUpdateFlagAndUpdate(){
  if [ "$UPDATE_LEVEL" -gt "$UPDATE_SKIP_LEVEL" ]
    then
      LOG_STATEMENT="Executing the update 2.0 script\n"
      printINFOLog
      LOG_STATEMENT="Updating the Update 2.0 client\n"
      printINFOLog
      
      cd ../../U2_CLIENT/bin
      cp ../../distributed_deployment/0_gw/$extractedPackDirName/updates/product.txt ../updates/.
      ./wso2update_darwin_original
      
      LOG_STATEMENT="Updated the Update 2.0 client\n"
      printINFOLog

      LOG_STATEMENT="Starting to update the API Manager pack to level: $UPDATE_LEVEL\n"
      printINFOLog

      rm -rf ../../distributed_deployment/0_gw/$extractedPackDirName/bin/wso2update_darwin
      cp wso2update_darwin ../../distributed_deployment/0_gw/$extractedPackDirName/bin

      cd ../../distributed_deployment/0_gw/$extractedPackDirName/bin
      ./wso2update_darwin --no-backup --level $UPDATE_LEVEL

      LOG_STATEMENT="Updated the API Manager pack to level: $UPDATE_LEVEL\n"
      printINFOLog
    else
     cd ../../distributed_deployment/0_gw/$extractedPackDirName/bin
     LOG_STATEMENT="Skipping the update script and continue the deployment\n"
     printINFOLog
  fi
  copyTheDBMSConnector
}

copyTheBasePackToDirs(){
  LOG_STATEMENT="Creating the directory structure\n"
  printINFOLog
  rm -rf distributed_deployment
  mkdir distributed_deployment
  cd distributed_deployment

  if [ "$deploymentPattern" = "$DEPLOYMENT_GWCP" ]
    then
      mkdir 0_gw 1_cp
  elif [ "$deploymentPattern" = "$DEPLOYMENT_ACTIVE_ACTIVE" ]
    then 
      mkdir 0_gw node_1 node_2
    else
      mkdir 0_gw 1_tm 2_cp
  fi

  LOG_STATEMENT="Created the directory structure\n"
  printINFOLog
  
  cd 0_gw

  LOG_STATEMENT="Copying the ZIP pack to 0_gw directory\n"
  printINFOLog
  cp $pathToBasePack .
  LOG_STATEMENT="Copied the ZIP pack to 0_gw directory\n"
  printINFOLog
  extractTheBasePack
  removeTheCopiedZip

  checkTheUpdateFlagAndUpdate
}

removeTheCopiedZip(){
  LOG_STATEMENT="Removing the copied ZIP pack inside the 0_gw directory\n"
  printINFOLog
  rm -rf $zipFilename
  LOG_STATEMENT="Removed the copied ZIP pack inside the 0_gw directory\n"
  printINFOLog
}

copyTheDBMSConnector(){
  cd ../../

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
pwd
  LOG_STATEMENT="Copying the MySQL JDBC connector $pathToMySQLConnectorFile Jar file\n"
  printINFOLog
  cp $pathToMySQLConnectorFile $extractedPackDirName/repository/components/lib

  LOG_STATEMENT="Copied the MySQL JDBC connector\n"
  printINFOLog

  if [ "$deploymentPattern" = "$DEPLOYMENT_GWCP" ]
    then
      GWCPDeployments
  elif [ "$deploymentPattern" = "$DEPLOYMENT_ACTIVE_ACTIVE" ]
    then
      ActiveActiveDeployments
    else
      fullDeployment
  fi
}

ActiveActiveDeployments(){
  LOG_STATEMENT="Copying the extracted content to node_1\n"
  printINFOLog
  cp -a $extractedPackDirName ../node_1
  LOG_STATEMENT="Copied the extracted content to node_1\n"
  printINFOLog

  LOG_STATEMENT="Copying the extracted content to node_2\n"
  printINFOLog
  cp -a $extractedPackDirName ../node_2
  LOG_STATEMENT="Copied the extracted content to node_2\n"
  printINFOLog

  cd ..

  LOG_STATEMENT="Configuring databases by executing scripts\n[APIM_DB] => $APIM_DB_WSO2AM_4xx\n[SHARED_DB] => $SHARED_DB_WSO2AM_4xx\nYou need to enter the MySQL root password to continue this step\n"
  printINFOLog

  cd node_1/$extractedPackDirName/dbscripts
  mysql -u$MYSQL_ROOT_USERNAME -p -e "DROP DATABASE IF EXISTS $APIM_DB_WSO2AM_4xx; DROP DATABASE IF EXISTS $SHARED_DB_WSO2AM_4xx; CREATE DATABASE $APIM_DB_WSO2AM_4xx character set latin1;CREATE DATABASE $SHARED_DB_WSO2AM_4xx character set latin1;USE $APIM_DB_WSO2AM_4xx;SOURCE apimgt/mysql.sql;USE $SHARED_DB_WSO2AM_4xx;SOURCE mysql.sql;SHOW TABLES;USE $APIM_DB_WSO2AM_4xx;SHOW TABLES;"
  
  LOG_STATEMENT="Configured databases by executing scripts successfully\n"
  printINFOLog

  cd ../../..

  rm -rf node_1/$extractedPackDirName/repository/conf/deployment.toml
  rm -rf node_2/$extractedPackDirName/repository/conf/deployment.toml

  cd ../toml_files

  cp node_1.toml ../distributed_deployment/node_1/$extractedPackDirName/repository/conf
  cp node_2.toml ../distributed_deployment/node_2/$extractedPackDirName/repository/conf

  LOG_STATEMENT="Starting to replacing deployment.toml files in both nodes by taking from the toml_files directory\n"
  printINFOLog

  mv ../distributed_deployment/node_1/$extractedPackDirName/repository/conf/node_1.toml ../distributed_deployment/node_1/$extractedPackDirName/repository/conf/deployment.toml
  mv ../distributed_deployment/node_2/$extractedPackDirName/repository/conf/node_2.toml ../distributed_deployment/node_2/$extractedPackDirName/repository/conf/deployment.toml

  LOG_STATEMENT="deployment.toml file replacement is success\n"
  printINFOLog

  cd ../distributed_deployment

  LOG_STATEMENT="Starting to change root user configurations in deployment.toml files\n"
  printINFOLog

  sed -i '' "s/MYSQL_ROOT_USERNAME/$MYSQL_ROOT_USERNAME/gi" node_1/$extractedPackDirName/repository/conf/deployment.toml
  sed -i '' "s/MYSQL_ROOT_USERNAME/$MYSQL_ROOT_USERNAME/gi" node_2/$extractedPackDirName/repository/conf/deployment.toml

  sed -i '' "s/MYSQL_ROOT_PASSWORD/$MYSQL_ROOT_PASSWORD/gi" node_1/$extractedPackDirName/repository/conf/deployment.toml
  sed -i '' "s/MYSQL_ROOT_PASSWORD/$MYSQL_ROOT_PASSWORD/gi" node_2/$extractedPackDirName/repository/conf/deployment.toml

  LOG_STATEMENT="MySQL root username change is completed successfully files\n"
  printINFOLog

  LOG_STATEMENT="Starting to change [database.shared_db] database name configurations in deployment.toml files\n"
  printINFOLog

  sed -i '' "s/SHARED_DB_WSO2AM_4xx/$SHARED_DB_WSO2AM_4xx/gi" node_1/$extractedPackDirName/repository/conf/deployment.toml
  sed -i '' "s/SHARED_DB_WSO2AM_4xx/$SHARED_DB_WSO2AM_4xx/gi" node_2/$extractedPackDirName/repository/conf/deployment.toml

  LOG_STATEMENT="[database.shared_db] database name configurations changes successfully completed\n"
  printINFOLog

  LOG_STATEMENT="Starting to change [database.apim_db] database name configurations in deployment.toml files\n"
  printINFOLog

  sed -i '' "s/APIM_DB_WSO2AM_4xx/$APIM_DB_WSO2AM_4xx/gi" node_1/$extractedPackDirName/repository/conf/deployment.toml
  sed -i '' "s/APIM_DB_WSO2AM_4xx/$APIM_DB_WSO2AM_4xx/gi" node_2/$extractedPackDirName/repository/conf/deployment.toml

  LOG_STATEMENT="[database.apim_db] database name configurations changes successfully completed\n"
  printINFOLog

  rm -rf 0_gw

  sleep 2

  LOG_STATEMENT="Active-Active deployment is completed. Now you can start all nodes by executing the api-manager.sh file. (OFFSET value already available in the deployment.toml file.)\n"
  printINFOLog

  LOG_STATEMENT="\n\nNODE DETAILS \n\n----------- Node_1 -----------\n\n * Offset: 0\n * Carbon Console URL: https://localhost:9443/carbon\n * Publisher Access URL: https://localhost:9443/publisher\n * Dev Portal Access URL: https://localhost:9443/devportal\n\n----------- Node_2 -----------\n\n * Offset: 1\n * Carbon Console URL: https://localhost:9444/carbon\n * Publisher Access URL: https://localhost:9444/publisher\n * Dev Portal Access URL: https://localhost:9444/devportal\n\n\n\n"
  printConfigDetail
}

GWCPDeployments(){
  LOG_STATEMENT="Copying the extracted content to 1_cp\n"
  printINFOLog
  cp -a $extractedPackDirName ../1_cp
  LOG_STATEMENT="Copied the extracted content to 1_cp\n"
  printINFOLog

  cd ..

  LOG_STATEMENT="Creating the gateway worker profile\n"
  printINFOLog
  sh 0_gw/$extractedPackDirName/bin/profileSetup.sh -Dprofile=gateway-worker
  LOG_STATEMENT="Created the gateway worker profile\n"
  printINFOLog

  LOG_STATEMENT="Creating the control plane profile\n"
  printINFOLog
  sh 1_cp/$extractedPackDirName/bin/profileSetup.sh -Dprofile=control-plane
  LOG_STATEMENT="Created the control plane profile\n"
  printINFOLog


  LOG_STATEMENT="Configuring databases by executing scripts\n[APIM_DB] => $APIM_DB_WSO2AM_4xx\n[SHARED_DB] => $SHARED_DB_WSO2AM_4xx\nYou need to enter the MySQL root password to continue this step\n"
  printINFOLog

  cd 0_gw/$extractedPackDirName/dbscripts
  mysql -u$MYSQL_ROOT_USERNAME -p -e "DROP DATABASE IF EXISTS $APIM_DB_WSO2AM_4xx; DROP DATABASE IF EXISTS $SHARED_DB_WSO2AM_4xx; CREATE DATABASE $APIM_DB_WSO2AM_4xx character set latin1;CREATE DATABASE $SHARED_DB_WSO2AM_4xx character set latin1;USE $APIM_DB_WSO2AM_4xx;SOURCE apimgt/mysql.sql;USE $SHARED_DB_WSO2AM_4xx;SOURCE mysql.sql;SHOW TABLES;USE $APIM_DB_WSO2AM_4xx;SHOW TABLES;"
  
  LOG_STATEMENT="Configured databases by executing scripts successfully\n"
  printINFOLog

  cd ../../..

  rm -rf 0_gw/$extractedPackDirName/repository/conf/deployment.toml
  rm -rf 1_cp/$extractedPackDirName/repository/conf/deployment.toml

  cd ../toml_files

  cp gateway-worker-2.toml ../distributed_deployment/0_gw/$extractedPackDirName/repository/conf
  cp control-plane-2.toml ../distributed_deployment/1_cp/$extractedPackDirName/repository/conf

  LOG_STATEMENT="Starting to replacing deployment.toml files in all 2 nodes by taking from the toml_files directory\n"
  printINFOLog

  mv ../distributed_deployment/0_gw/$extractedPackDirName/repository/conf/gateway-worker-2.toml ../distributed_deployment/0_gw/$extractedPackDirName/repository/conf/deployment.toml
  mv ../distributed_deployment/1_cp/$extractedPackDirName/repository/conf/control-plane-2.toml ../distributed_deployment/1_cp/$extractedPackDirName/repository/conf/deployment.toml

  LOG_STATEMENT="deployment.toml file replacement is success\n"
  printINFOLog

  cd ../distributed_deployment

  LOG_STATEMENT="Starting to change root user configurations in deployment.toml files\n"
  printINFOLog

  # #FOR MAC OS,
  # #sed -i '' "s/MYSQL_ROOT_USERNAME/$MYSQL_ROOT_USERNAME/gi" 0_gw/$extractedPackDirName/repository/conf/deployment.toml

  sed -i '' "s/MYSQL_ROOT_USERNAME/$MYSQL_ROOT_USERNAME/gi" 0_gw/$extractedPackDirName/repository/conf/deployment.toml
  sed -i '' "s/MYSQL_ROOT_USERNAME/$MYSQL_ROOT_USERNAME/gi" 1_cp/$extractedPackDirName/repository/conf/deployment.toml

  sed -i '' "s/MYSQL_ROOT_PASSWORD/$MYSQL_ROOT_PASSWORD/gi" 0_gw/$extractedPackDirName/repository/conf/deployment.toml
  sed -i '' "s/MYSQL_ROOT_PASSWORD/$MYSQL_ROOT_PASSWORD/gi" 1_cp/$extractedPackDirName/repository/conf/deployment.toml

  LOG_STATEMENT="MySQL root username change is completed successfully files\n"
  printINFOLog

  LOG_STATEMENT="Starting to change [database.shared_db] database name configurations in deployment.toml files\n"
  printINFOLog

  sed -i '' "s/SHARED_DB_WSO2AM_4xx/$SHARED_DB_WSO2AM_4xx/gi" 0_gw/$extractedPackDirName/repository/conf/deployment.toml
  sed -i '' "s/SHARED_DB_WSO2AM_4xx/$SHARED_DB_WSO2AM_4xx/gi" 1_cp/$extractedPackDirName/repository/conf/deployment.toml

  LOG_STATEMENT="[database.shared_db] database name configurations changes successfully completed\n"
  printINFOLog

  LOG_STATEMENT="Starting to change [database.apim_db] database name configurations in deployment.toml files\n"
  printINFOLog

  sed -i '' "s/APIM_DB_WSO2AM_4xx/$APIM_DB_WSO2AM_4xx/gi" 1_cp/$extractedPackDirName/repository/conf/deployment.toml

  LOG_STATEMENT="[database.apim_db] database name configurations changes successfully completed\n"
  printINFOLog

  sleep 2

  LOG_STATEMENT="Distributed deployment is completed. Now you can start all nodes by executing the api-manager.sh file. (OFFSET value already available in the deployment.toml file.)\n"
  printINFOLog

  LOG_STATEMENT="\n\nNODE DETAILS \n\n----------- Control Plane -----------\n\n * Offset: 1\n * Carbon Console URL: https://localhost:9444/carbon\n * Publisher Access URL: https://localhost:9444/publisher\n * Dev Portal Access URL: https://localhost:9444/devportal\n\n----------- API Gateway -----------\n\n * Offset: 0\n * Carbon Console URL: https://localhost:9443/carbon\n * HTTP URL: https://localhost:8280\n * HTTPS URL: https://localhost:8243\n\n"
  printConfigDetail
}

fullDeployment(){
  LOG_STATEMENT="Copying the extracted content to 1_tm\n"
  printINFOLog
  cp -a $extractedPackDirName ../1_tm
  LOG_STATEMENT="Copied the extracted content to 1_tm\n"
  printINFOLog

  LOG_STATEMENT="Copying the extracted content to 2_cp\n"
  printINFOLog
  cp -a $extractedPackDirName ../2_cp
  LOG_STATEMENT="Copied the extracted content to 2_cp\n"
  printINFOLog

  cd ..

  LOG_STATEMENT="Creating the gateway worker profile\n"
  printINFOLog
  sh 0_gw/$extractedPackDirName/bin/profileSetup.sh -Dprofile=gateway-worker
  LOG_STATEMENT="Created the gateway worker profile\n"
  printINFOLog
 
  LOG_STATEMENT="Creating the traffic manager profile\n"
  printINFOLog
  sh 1_tm/$extractedPackDirName/bin/profileSetup.sh -Dprofile=traffic-manager
  LOG_STATEMENT="Created the traffic manager profile\n"
  printINFOLog
  
  LOG_STATEMENT="Creating the control plane profile\n"
  printINFOLog
  sh 2_cp/$extractedPackDirName/bin/profileSetup.sh -Dprofile=control-plane
  LOG_STATEMENT="Created the control plane profile\n"
  printINFOLog

  LOG_STATEMENT="Configuring databases by executing scripts\n[APIM_DB] => $APIM_DB_WSO2AM_4xx\n[SHARED_DB] => $SHARED_DB_WSO2AM_4xx\nYou need to enter the MySQL root password to continue this step\n"
  printINFOLog

  cd 0_gw/$extractedPackDirName/dbscripts
  mysql -u$MYSQL_ROOT_USERNAME -p -e "DROP DATABASE IF EXISTS $APIM_DB_WSO2AM_4xx; DROP DATABASE IF EXISTS $SHARED_DB_WSO2AM_4xx; CREATE DATABASE $APIM_DB_WSO2AM_4xx character set latin1;CREATE DATABASE $SHARED_DB_WSO2AM_4xx character set latin1;USE $APIM_DB_WSO2AM_4xx;SOURCE apimgt/mysql.sql;USE $SHARED_DB_WSO2AM_4xx;SOURCE mysql.sql;SHOW TABLES;USE $APIM_DB_WSO2AM_4xx;SHOW TABLES;"
  
  LOG_STATEMENT="Configured databases by executing scripts successfully\n"
  printINFOLog

  cd ../../..

  rm -rf 0_gw/$extractedPackDirName/repository/conf/deployment.toml
  rm -rf 1_tm/$extractedPackDirName/repository/conf/deployment.toml
  rm -rf 2_cp/$extractedPackDirName/repository/conf/deployment.toml

  cd ../toml_files

  cp gateway-worker.toml ../distributed_deployment/0_gw/$extractedPackDirName/repository/conf
  cp traffic-manager.toml ../distributed_deployment/1_tm/$extractedPackDirName/repository/conf
  cp control-plane.toml ../distributed_deployment/2_cp/$extractedPackDirName/repository/conf

  LOG_STATEMENT="Starting to replacing deployment.toml files in all 3 nodes by taking from the toml_files directory\n"
  printINFOLog

  mv ../distributed_deployment/0_gw/$extractedPackDirName/repository/conf/gateway-worker.toml ../distributed_deployment/0_gw/$extractedPackDirName/repository/conf/deployment.toml
  mv ../distributed_deployment/1_tm/$extractedPackDirName/repository/conf/traffic-manager.toml ../distributed_deployment/1_tm/$extractedPackDirName/repository/conf/deployment.toml
  mv ../distributed_deployment/2_cp/$extractedPackDirName/repository/conf/control-plane.toml ../distributed_deployment/2_cp/$extractedPackDirName/repository/conf/deployment.toml

  LOG_STATEMENT="deployment.toml file replacement is success\n"
  printINFOLog

  cd ../distributed_deployment

  LOG_STATEMENT="Starting to change root user configurations in deployment.toml files\n"
  printINFOLog

  # #FOR MAC OS,
  # #sed -i '' "s/MYSQL_ROOT_USERNAME/$MYSQL_ROOT_USERNAME/gi" 0_gw/$extractedPackDirName/repository/conf/deployment.toml

  sed -i '' "s/MYSQL_ROOT_USERNAME/$MYSQL_ROOT_USERNAME/gi" 0_gw/$extractedPackDirName/repository/conf/deployment.toml
  sed -i '' "s/MYSQL_ROOT_USERNAME/$MYSQL_ROOT_USERNAME/gi" 1_tm/$extractedPackDirName/repository/conf/deployment.toml
  sed -i '' "s/MYSQL_ROOT_USERNAME/$MYSQL_ROOT_USERNAME/gi" 2_cp/$extractedPackDirName/repository/conf/deployment.toml

  sed -i '' "s/MYSQL_ROOT_PASSWORD/$MYSQL_ROOT_PASSWORD/gi" 0_gw/$extractedPackDirName/repository/conf/deployment.toml
  sed -i '' "s/MYSQL_ROOT_PASSWORD/$MYSQL_ROOT_PASSWORD/gi" 1_tm/$extractedPackDirName/repository/conf/deployment.toml
  sed -i '' "s/MYSQL_ROOT_PASSWORD/$MYSQL_ROOT_PASSWORD/gi" 2_cp/$extractedPackDirName/repository/conf/deployment.toml

  LOG_STATEMENT="MySQL root username change is completed successfully files\n"
  printINFOLog

  LOG_STATEMENT="Starting to change [database.shared_db] database name configurations in deployment.toml files\n"
  printINFOLog

  sed -i '' "s/SHARED_DB_WSO2AM_4xx/$SHARED_DB_WSO2AM_4xx/gi" 0_gw/$extractedPackDirName/repository/conf/deployment.toml
  sed -i '' "s/SHARED_DB_WSO2AM_4xx/$SHARED_DB_WSO2AM_4xx/gi" 1_tm/$extractedPackDirName/repository/conf/deployment.toml
  sed -i '' "s/SHARED_DB_WSO2AM_4xx/$SHARED_DB_WSO2AM_4xx/gi" 2_cp/$extractedPackDirName/repository/conf/deployment.toml

  LOG_STATEMENT="[database.shared_db] database name configurations changes successfully completed\n"
  printINFOLog

  LOG_STATEMENT="Starting to change [database.apim_db] database name configurations in deployment.toml files\n"
  printINFOLog

  sed -i '' "s/APIM_DB_WSO2AM_4xx/$APIM_DB_WSO2AM_4xx/gi" 1_tm/$extractedPackDirName/repository/conf/deployment.toml
  sed -i '' "s/APIM_DB_WSO2AM_4xx/$APIM_DB_WSO2AM_4xx/gi" 2_cp/$extractedPackDirName/repository/conf/deployment.toml

  LOG_STATEMENT="[database.apim_db] database name configurations changes successfully completed\n"
  printINFOLog

  sleep 2

  LOG_STATEMENT="Distributed deployment is completed. Now you can start all nodes by executing the api-manager.sh file. (OFFSET value already available in the deployment.toml file.)\n"
  printINFOLog

  LOG_STATEMENT="\n\nNODE DETAILS \n\n----------- Control Plane -----------\n\n * Offset: 2\n * Carbon Console URL: https://localhost:9445/carbon\n * Publisher Access URL: https://localhost:9445/publisher\n * Dev Portal Access URL: https://localhost:9445/devportal\n\n----------- Traffic Manager -----------\n\n * Offset: 1\n * Carbon Console URL: https://localhost:9444/carbon\n\n----------- API Gateway -----------\n\n * Offset: 0\n * Carbon Console URL: https://localhost:9443/carbon\n * HTTP URL: https://localhost:8280\n * HTTPS URL: https://localhost:8243\n\n"
  printConfigDetail
}

installWget(){
  LOG_STATEMENT="Trying to install wget\n"
  printINFOLog
  
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
  brew install wget

  brew install gnu-getopt
  export PATH="/opt/homebrew/opt/gnu-getopt/bin:$PATH"
  
  LOG_STATEMENT="Installed wget\n"
  printINFOLog
}

extractTheBasePack(){
  LOG_STATEMENT="Extracting the ZIP file\n"
  printINFOLog
  
  base_dir="${zipFilename%.zip}"

  mkdir "$extractedPackDirName"
  
  unzip "$zipFilename" -d "$extractedPackDirName"

  LOG_STATEMENT="ZIP file extracted\n"
  printINFOLog
}

init(){
  LOG_STATEMENT="Starting the distributed deployment script of the WSO2 API Manager 4.x.x\n"
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

    if [ -z "$pathToBasePack" ]
      then
        LOG_STATEMENT="Base pack is not defined\n"
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

    if [ -z "$APIM_DB_WSO2AM_4xx" ]
      then
        LOG_STATEMENT="APIM database name is not defined\n"
        printERRLog
        exit 1
    fi

    if [ -z "$SHARED_DB_WSO2AM_4xx" ]
      then
        LOG_STATEMENT="SHARED database name is not defined\n"
        printERRLog
        exit 1
    fi

    LOG_STATEMENT="\n\nDEPLOYMENT DETAILS \n\n* Deployment Pattern: $deploymentPattern \n* Base Pack Path: $pathToBasePack\n* ZIP Name: $zipFilename\n* Update Level: $UPDATE_LEVEL\n* Directory Name Of The Extracted Content: $extractedPackDirName \n\n"
    printConfigDetail

    LOG_STATEMENT="\n\nDATABASE DETAILS \n\n* ROOT User Name: $MYSQL_ROOT_USERNAME\n* APIM Database Name: $APIM_DB_WSO2AM_4xx\n* Shared Database Name: $SHARED_DB_WSO2AM_4xx\n\n"
    printConfigDetail

    case "$deploymentPattern" in
      $DEPLOYMENT_GWCP) 
        GWCPDeployment
      ;;
      $DEPLOYMENT_ACTIVE_ACTIVE) 
        ActiveActiveDeployment
      ;;
      $DEPLOYMENT_FULL) 
        TMSeparatedDeployment
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
