# JMS Consumer/Publisher Client

This JMS client is useful in a situation where JMS events haven't been consumed correctly by the gateway, as indicated by the gateway listener debug logs. Even though the event publisher log adaptor is configured for the relevant stream, shows that the message was received in the event stream. It doesn’t imply that the event was properly published to the broker through the JMSeventPublisher. So that the source of the issue between the JMS publisher flow and the consumption flow remains unidentified. To address this, the tool allows manual listening to the broker to verify if an event was published. Also, this tool enables the manual publishing of an event to the broker. This process helps ascertain whether the gateway server appropriately consumed the event, as observed through the gateway listener debug logs.

## Building the Tool

Follow these steps to build the tool:

1. Clone the repository and navigate to the project's root folder (JMS-Publisher-Consumer-Client).
2. Build the project using Maven:

   ```sh
   mvn clean install
   ```

3. Once the build is successful, find the `JMS-Publisher-Consumer-Client-1.0.0.zip` in the `target` directory.

## Usage

1. Copy the `JMSPublisherConsumerClient-1.0.0.zip` to your preferred location and extract it:

   ```sh
   unzip ./JMS-Publisher-Consumer-Client-1.0.0.zip -d .
   ```

2. Configure the `config.properties` file with your broker settings.

3. To consume events from the broker, run:

   ```sh
   java -jar JMS-Publisher-Consumer-Client-1.0.0.jar
   ```

4. To manually publish an event to the broker, execute:

   ```sh
   java -cp JMS-Publisher-Consumer-Client-1.0.0.jar org.wso2.test.jmsPublisherConsumerClient.EventPublisher
   ```

## Sample Output

Successful event consumption:

```
-------- EVENT RECEIVED -------------
EVENT RECEIVED :{"eventType":"DEPLOY_API_IN_GATEWAY","timestamp":1693323252994,"event":...}
DECRYPTED PAYLOAD :{"apiId":0,"uuid":"732e4a17-5767-443d-bf24-319c52948877","name":"asa",...}
----------------------------
```

Successful event publication:

```
! Event was successfully published to the broker !
```

Absolutely, here's a template for describing the configuration parameters in your README:

## Configuration

Before you start using the JMS Consumer/Publisher Client, you'll need to configure the `config.properties` file with the necessary settings. Here's what each parameter in the configuration file means:

### Broker Configuration

- **`brokerUrl`**: The URL of the JMS broker where events are published and consumed. Replace `localhost` and `5672` with the actual hostname and port of your broker.

- **`username`**: Your username for authenticating with the JMS broker.

- **`password`**: The password associated with the provided username (please add a url encoded value for the password if there is any special characters in your broker password ).

- **`topicName`**: The name of the topic to which events are published and consumed.

### Event Publisher Configuration

If you intend to use the Event Publisher flow, consider the following additional parameter:

- **`eventType`**: The type of the event being published. In the example, it's set to `"DEPLOY_API_IN_GATEWAY"`. Customize this to match your event type.

- **`event`**: A JSON-formatted event payload that you want to publish. Modify the content within the double quotes to match your event's structure and data.

Here's an example configuration:

```properties
# Broker Configuration
brokerUrl=tcp://localhost:5672
username=admin
password=admin
topicName=notification

# Event Publisher Configuration
eventType=DEPLOY_API_IN_GATEWAY
event={"apiId":0,"uuid":"732e4a17-5767-443d-bf24-319c52948877","name":"asa","version":"v1","provider":"admin","apiType":"HTTP","gatewayLabels":["production and sandbox"],"associatedApis":[],"context":"/asd/v1","eventId":"d1b1dcd6-b387-4fa8-8d3d-9bc4a76dd72b","timeStamp":1693289608077,"type":"DEPLOY_API_IN_GATEWAY","tenantId":0,"tenantDomain":"carbon.super"}
```

Make sure to modify the values in the `config.properties` file to match your setup and the specific events you're working with.
