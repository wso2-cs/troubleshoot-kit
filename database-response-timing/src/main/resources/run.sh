#!/bin/sh
java -cp database-response-timing-1.0.0.jar -Dloader.path="./lib" -Dloader.main=org.wso2.diagnose.databaseresponsetiming.DatabaseResponseTimingApplication org.springframework.boot.loader.PropertiesLauncher

