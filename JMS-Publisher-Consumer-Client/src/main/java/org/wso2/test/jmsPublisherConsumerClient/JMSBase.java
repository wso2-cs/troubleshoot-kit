package org.wso2.test.jmsPublisherConsumerClient;

import javax.jms.*;
import javax.naming.InitialContext;
import javax.naming.NamingException;
import java.util.Properties;
public class JMSBase {
    protected TopicConnection topicConnection;
    protected TopicSession topicSession;

    protected String brokerUrl = "tcp://0.0.0.0:5672";
    protected String username = "admin";
    protected String password = "admin";
    protected String topicName = "notification";

    private void readProperties(){
        ReadConfigFile config = new ReadConfigFile();
        brokerUrl = config.getProperty("brokerUrl");
        username = config.getProperty("username");
        password = config.getProperty("password");
        topicName = config.getProperty("topicName");
    }
    protected void setupConnection() throws NamingException, JMSException {
        readProperties();
        Properties properties = new Properties();
        properties.put("java.naming.factory.initial", "org.wso2.andes.jndi.PropertiesFileInitialContextFactory");
        properties.put("transport.jms.DestinationType", "topic");
        properties.put("connectionfactory.TopicConnectionFactory",
                "amqp://" + username + ":" + password + "@clientid/carbon?brokerlist='" + brokerUrl + "'");
        properties.put("transport.jms.ConnectionFactoryJNDIName", "TopicConnectionFactory");

        InitialContext ctx = new InitialContext(properties);
        TopicConnectionFactory connFactory = (TopicConnectionFactory) ctx.lookup("TopicConnectionFactory");

        topicConnection = connFactory.createTopicConnection();
        topicConnection.start();
        topicSession = topicConnection.createTopicSession(false, TopicSession.AUTO_ACKNOWLEDGE);
    }

    protected void closeConnection() throws JMSException {
        topicConnection.close();
    }
}
