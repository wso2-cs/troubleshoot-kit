## Database Response Timing Tool

###Introduction

Purpose of this DBClient is to isolate whether DB becoming a performance bottleneck in production deployment.
(It's not possible to enable JDBC spy logs in production systems, since it need some config file changes and server
restarts)

What this client do is, execute a given SQL query for given number of iterations, and log the query execution time
taken in each iteration.

This client will help to identify scenarios such as;
- Database itself has some tuning/network issues. eg: You see high fluctuation in the query execution times
- Database query execution time is too high. eg: Number of records in the Db has grown. Not having proper indexes etc.

Note:
You need to have idea on the issue that you are going to isolate and define the SQL query as relevant for that.
eg: Token generation, Registry, JDBC user store issues need to pick the query as relevant for each.

###How to build ?

1. Checkout the source and execute following command from the project home folder (database-response-timing)
   
    ```mvn clean install```

2. Build zip (database-response-timing-1.0.0-bundle.zip) will available in project target directory, once build is success.

###How to execute the client ?
1. Copy *database-response-timing-1.0.0-bundle.zip* to intended location and unzip the file ```unzip ./database-response-timing-1.0.0-bundle.zip -d .```

2. Update the [application.yaml](#application.yaml) file with correct configs.

3. Copy the relevant JDBC driver (jar) to the ```/lib``` folder.

3. Execute following command to run the client and get query execution times. <br />
   ```sh run.sh```or ```run.bat``` if windows.
5. On a successful execution of client, you will see result similar to following, & also response will be logged into ```response.log``` 

```aidl
2021-03-16 11:10:43 [main] INFO  o.w.d.d.DBTester - Staring test round : 1
2021-03-16 11:10:44 [main] INFO  o.w.d.d.DBTester - Connection : jdbc:mysql://localhost:3306/test | Time to (ms) getConnection : 1057
2021-03-16 11:10:44 [main] INFO  o.w.d.d.DBTester - Starting to iterate test round 1 for : 1 times | Query : SELECT 1
2021-03-16 11:10:44 [main] INFO  o.w.d.d.DBTester - Test round 1 iteration : 1 | Time to execute query (ms) : 19
2021-03-16 11:10:44 [main] INFO  o.w.d.d.DBTester - Test round 1 iteration : 1 | Time to iterate through 1 items in result set in (ms) : 1
2021-03-16 11:10:44 [main] INFO  o.w.d.d.DBTester - Average time to executeQuery (ms) : 19
2021-03-16 11:10:44 [main] INFO  o.w.d.d.DBTester - Average time to rs.next() (ms) : 1
2021-03-16 11:10:44 [main] INFO  o.w.d.d.DBTester - Staring test round : 2
2021-03-16 11:10:44 [main] INFO  o.w.d.d.DBTester - Connection : jdbc:mysql://localhost:3306/test | Time to (ms) getConnection : 0
2021-03-16 11:10:44 [main] INFO  o.w.d.d.DBTester - Starting to iterate test round 2 for : 1 times | Query : SELECT 1
2021-03-16 11:10:44 [main] INFO  o.w.d.d.DBTester - Test round 2 iteration : 1 | Time to execute query (ms) : 3
2021-03-16 11:10:44 [main] INFO  o.w.d.d.DBTester - Test round 2 iteration : 1 | Time to iterate through 1 items in result set in (ms) : 0
2021-03-16 11:10:44 [main] INFO  o.w.d.d.DBTester - Average time to executeQuery (ms) : 3
2021-03-16 11:10:44 [main] INFO  o.w.d.d.DBTester - Average time to rs.next() (ms) : 0
2021-03-16 11:10:44 [main] INFO  o.w.d.d.DBTester - Average time to get connection (ms) : 528
2021-03-16 11:10:44 [main] INFO  o.w.d.d.DatabaseResponseTimingApplication - Started DatabaseResponseTimingApplication in 3.03 seconds (JVM running for 3.733)
```

###application.yaml

This file contains all the configurations needed to be made in order to run the tool timing tool. Following is a sample configuration file, Which configured to connect mysql database.

```aidl
---
spring:
  datasource:
    #Sample mysql connection More information : https://docs.spring.io/spring-boot/docs/current/reference/html/appendix-application-properties.html#common-application-properties-data
    url: "jdbc:mysql://localhost:3306/test"
    username: "root"
    password: "strongpassword"
    driver-class-name: "com.mysql.jdbc.Driver"
    type: "org.apache.tomcat.jdbc.pool.DataSource"
    #Configs can found in https://docs.spring.io/spring-boot/docs/current/reference/html/appendix-application-properties.html#spring.datasource.tomcat
    tomcat:
      initial-size: 1
      max-active: 2
      min-idle: 1

testconfig:
  totalIterations: 2
  iterationsPerConnection: 1
  sleepTime: 10000
  query: "SELECT * FROM abc"

#Logging configuration more information : https://docs.spring.io/spring-boot/docs/current/reference/html/appendix-application-properties.html#logging.charset.console
logging:
  file:
    name: ./response.log
    path: ./
  pattern:
    console: "%d{yyyy-MM-dd HH:mm:ss} - %msg%n"
    file: "%d{yyyy-MM-dd HH:mm:ss} [%thread] %-5level %logger{36} - %msg%n"
  level:
    org.wso2.diagnose.databaseresponsetiming: INFO
```

####Datasource 

Configurations related to the database connection, [Please refer](https://docs.spring.io/spring-boot/docs/current/reference/html/appendix-application-properties.html#common-application-properties-data) for all database related configs.

And we can specify the Tomcat JDBC configurations under *tomcat* tag, Refer [Please refer](https://docs.spring.io/spring-boot/docs/current/reference/html/appendix-application-properties.html#spring.datasource.tomcat) for all JDBC configs.

####testconfig
- totalIterations - Number of total iterations' database connection runs.
- iterationsPerConnection - Number of total iterations' runs with a single db connection.
- sleepTime - Sleep after complete one iteration (Default 0)
- query - SQL Query to execute.

####logging
Logging related configs, [Please refer](https://docs.spring.io/spring-boot/docs/current/reference/html/appendix-application-properties.html#logging.charset.console) for more information.


