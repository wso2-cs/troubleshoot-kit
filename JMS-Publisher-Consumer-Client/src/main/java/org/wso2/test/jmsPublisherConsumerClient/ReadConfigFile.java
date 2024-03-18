package org.wso2.test.jmsPublisherConsumerClient;

import java.io.FileInputStream;
import java.io.IOException;
import java.io.InputStream;
import java.util.Properties;

/**
 * Read configurations from config.xml file.
 */
public class ReadConfigFile {
    private Properties properties = new Properties();

    /**
     * Read config.file.
     */
    public ReadConfigFile() {

        // Load properties from external file if it exists
        try {
            InputStream externalInput = new FileInputStream("config.properties");
            properties.load(externalInput);
            externalInput.close();
        } catch (IOException e) {
            System.out.println("External Config file not found.");
            e.printStackTrace();
            // External file doesn't exist or couldn't be read
        }

        // Load default properties from JAR if not overridden externally
        if (properties.isEmpty()) {
            System.out.println("Reading  internal config file");
            try {
                InputStream internalInput = ReadConfigFile.class.getClassLoader().getResourceAsStream("config.properties");
                if (internalInput != null) {
                    properties.load(internalInput);
                    internalInput.close();
                } else {
                    System.err.println("config.properties file not found.");
                }
            } catch (IOException e) {
                e.printStackTrace();
            }
        }
    }

    /**
     * get the value related to a property.
     * @param key key of a property.
     * @return value of property.
     */
    public String getProperty(String key) {
        return properties.getProperty(key);
    }
}
