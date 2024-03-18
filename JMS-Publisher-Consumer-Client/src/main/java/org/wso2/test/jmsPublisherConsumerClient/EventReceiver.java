package org.wso2.test.jmsPublisherConsumerClient;

import javax.jms.*;
import javax.naming.NamingException;

import wiremock.com.fasterxml.jackson.core.JsonProcessingException;
import wiremock.com.fasterxml.jackson.databind.JsonNode;
import wiremock.com.fasterxml.jackson.databind.ObjectMapper;

import java.io.IOException;
import java.util.Base64;

public class EventReceiver extends JMSBase implements MessageListener {

    public static void main(String[] args) throws NamingException, JMSException {
        EventReceiver eventReceiver = new EventReceiver();
        eventReceiver.start();
    }

    public void start() throws NamingException, JMSException {
        setupConnection();
        Topic topic = topicSession.createTopic(topicName);
        MessageConsumer consumer = topicSession.createConsumer(topic);
        consumer.setMessageListener(this);
        System.out.println("\n\nEvent receiver started and Listening to " + brokerUrl);
    }

    public static String decodeBase64(String base64EncodedString) {
        byte[] decodedBytes = Base64.getDecoder().decode(base64EncodedString);
        return new String(decodedBytes);
    }

    @Override
    public void onMessage(Message message) {
        try {
            Topic jmsDestination = (Topic) message.getJMSDestination();
            if (message instanceof TextMessage) {
                String textMessage = ((TextMessage) message).getText();
                JsonNode payloadData = new ObjectMapper().readTree(textMessage).path("event").path("payloadData");
                    System.out.println("-------- EVENT RECEIVED -------------");
                    System.out.println("EVENT RECEIVED :" + payloadData);
                String event = payloadData.get("event").asText();
                if (event != null && !event.isEmpty()){
                    System.out.println("DECRYPTED PAYLOAD :" +decodeBase64(event));
                }

                System.out.println("----------------------------");

            }
        } catch (JMSException e) {
            System.out.print("Error While Reading The JMS Message " + e.getMessage());
        } catch (JsonProcessingException e) {
            throw new RuntimeException(e);
        } catch (IOException e) {
            throw new RuntimeException(e);
        }
    }

}