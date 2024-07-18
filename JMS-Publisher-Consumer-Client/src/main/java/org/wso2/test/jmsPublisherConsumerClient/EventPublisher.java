package org.wso2.test.jmsPublisherConsumerClient;

import org.json.JSONObject;

import javax.jms.*;
import javax.naming.NamingException;
import java.util.Base64;

public class EventPublisher extends JMSBase {

    public static void main(String[] args) throws NamingException, JMSException {
        EventPublisher eventPublisher = new EventPublisher();
        eventPublisher.start();
    }

    private static JSONObject buildingTheMessagePayload() {
        ReadConfigFile config = new ReadConfigFile();
        String eventType= config.getProperty("eventType");
        String event= config.getProperty("event");
        String encodedEvent = Base64.getEncoder().encodeToString(event.getBytes());


        JSONObject eventPayloadData = new JSONObject();
        eventPayloadData.put("eventType", eventType);
        eventPayloadData.put("timestamp", System.currentTimeMillis());
        eventPayloadData.put("event", encodedEvent); // your event data

        JSONObject payloadData = new JSONObject();
        payloadData.put("payloadData", eventPayloadData);

        JSONObject eventObject = new JSONObject();
        eventObject.put("event", payloadData);

        return eventObject;
    }


    public void start() throws NamingException, JMSException {
        setupConnection();
        Topic topic = topicSession.createTopic(topicName);
        MessageProducer producer = topicSession.createProducer(topic);
        try {

            TextMessage message = topicSession.createTextMessage(buildingTheMessagePayload().toString());
            producer.send(message);
        } catch (JMSException e) {
            System.out.println("! Event was not published to the broker !");
            e.printStackTrace();
        }
        System.out.println("! Event was successfully published to the broker !");
    }
}
