# Welcome to HTTP/HTTPS response timeing tool!

HTTP/HTTPS response timeing tool is a monitoring tool supports to check and monitor the health of the HTTP ot HTTPS endpoint.

## Building from the source

1.  JDK version - 1.8
2.  Maven version
3.  Build the source  `mvn clean install`
4.  Copy zip built artifact  `cp /http-response-timing
    /target/http-response-timing-0.0.1-bundle.zip ~/workspace`
5.  Extract the zip file  `unzip ./http-response-timing-0.0.1-bundle.zip -d .`


## Contents of zip

1. README.md - Brief description of this tool.
2. http-response-timing-0.0.1.jar - This will be executable file.
3. web-health.log - This is the default log file.
4. application.yaml - Contains all the configurations.

## Instruction to run

**Pre required to install Java 8 and JAVA_HOME should be properly configured.**
- Go to the ~/workspace
- Run ```java -jar http-response-timing-0.0.1.jar```

## Sample output
- On a successful response
```
2021-03-08 13:57:05.914  INFO 10171 --- c.s.w.utils.LoggingUtils                 : URL : https://run.mocky.io/v3/d9176ed0-f286-4293-b078-9f1d4cea4ff8 | Current status marked as : ACTIVE | Time to respond : 1126 | Status code received : 200 | HTTP Response Status : HTTP/1.1 200 OK | Message : Successful response received with expected body.
```
- On a invalid response with invalid response body
```
2021-03-08 13:52:11.686 ERROR 10075 --- c.s.w.utils.LoggingUtils                 : URL : https://run.mocky.io/v3/d9176ed0-f286-4293-b078-9f1d4cea4ff8 | Current status marked as : RESPONSE_DOSE_NOT_MATCH | Time to respond : 960 | Status code received : 200 | HTTP Response Status : HTTP/1.1 200 OK | Message : Unsuccessful attempt, unexpected content in body.
```
- On a invalid response
```
2021-03-08 13:57:38.574 ERROR 10177 --- c.s.w.utils.LoggingUtils                 : URL : https://run.mocky.io/v3/d9176ed0-f286-4293-b078-9f1d4cea4ff8 | Current status marked as : INACTIVE | Time to respond : 1020 | Status code received : 200 | HTTP Response Status : HTTP/1.1 200 OK | Message : Unexpected error code received (expecting 400)
```

## application.yaml

This file contains all the configurations to run the application

* monitoringFrequency - Monitoring frequency by millisecond.
*  globalTimeout - HTTP Connection global timeout (Recommended to use value >= monitoringFrequency).
* httpClientImpl - Custom implementation of the HTTP Call, This can be extend according to the HTTP library used.
* trustStoreLocation - jks file location contains trusted SSL certificates
* trustStorePassword - Password of the trusted store
* WebsiteMonitoringMetadata - Specify in a **List** of websites to monitor
    * url - Website URL
    * expectedStatusCode - Status code expecting to return
    * expectedResponseRegEx - Regular expression to match the response content.
    * optionalHeaders - Key value pare of headers if needed

### sample application.yaml
```
---
monitoringFrequency: 5000
workerPoolSize: 15
globalTimeout: 30
httpClientImpl: com.shagihan.webhealthcheckmonitor.impl.HttpClientHealthCheck
WebsiteMonitoringMetadata :
  - url: https://run.mocky.io/v3/d9176ed0-f286-4293-b078-9f1d4cea4ff8
    expectedStatusCode: 200
    expectedResponseRegEx: "[A-Z]"
  - url: https://google.com
    expectedStatusCode: 200
    expectedResponseRegEx: "[A-Za-Z]"  
  - url: https://abc.com
    expectedStatusCode: 202
    expectedResponseRegEx: "[A-Za-Z]"  
spring:
logging:
  pattern:
    file: "%d{HH:mm:ss.SSS} %-5level %logger{36} - %msg%n"
  level:
    com.shagihan.webhealthcheckmonitor: DEBUG
  file:
    path: ./
    name: ./web-health.log
```

## RESTFull API to get health details

* Get the list of health-check information
```
HTTP: /health
Sample response -
[{"website":"https://run.mocky.io/v3/d9176ed0-f286-4293-b078-9f1d4cea4ff8","lastUpdatedTime":1615192748165,"lastResponseTime":796,"averageResponseTime":827,"currentStatus":"INACTIVE"}]
```
* Get details of a specific website
```
HTTP: /health-of-website?url=<URL_TO_QUERY>
Sample response -
{"website":"https://run.mocky.io/v3/d9176ed0-f286-4293-b078-9f1d4cea4ff8","lastUpdatedTime":1615192838176,"lastResponseTime":805,"averageResponseTime":836,"currentStatus":"INACTIVE"}
```
