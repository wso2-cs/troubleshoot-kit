package org.wso2.diagnose.databaseresponsetiming.configdto;

import org.springframework.boot.context.properties.ConfigurationProperties;
import org.springframework.context.annotation.Configuration;

@Configuration
@ConfigurationProperties(prefix = "testconfig")
public class TestConfig {
    private int iterationsPerConnection = 100;
    private int totalIterations = 100;
    private int sleepTime = 0;
    private boolean LogResultSet = false;
    private String query = "SELECT 1";

    public int getIterationsPerConnection() {
        return iterationsPerConnection;
    }

    public void setIterationsPerConnection(int iterationsPerConnection) {
        this.iterationsPerConnection = iterationsPerConnection;
    }

    public int getTotalIterations() {
        return totalIterations;
    }

    public void setTotalIterations(int totalIterations) {
        this.totalIterations = totalIterations;
    }

    public int getSleepTime() {
        return sleepTime;
    }

    public void setSleepTime(int sleepTime) {
        this.sleepTime = sleepTime;
    }

    public String getQuery() {
        return query;
    }

    public void setQuery(String query) {
        this.query = query;
    }

    public boolean getLogResultSet() {
        return LogResultSet;
    }

    public void setLogResultSet(boolean logResultSet) {
        this.LogResultSet = logResultSet;
    }
}
