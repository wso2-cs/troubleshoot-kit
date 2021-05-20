package org.wso2.diagnose.databaseresponsetiming;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.InitializingBean;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.scheduling.annotation.Async;
import org.springframework.scheduling.annotation.EnableAsync;
import org.springframework.stereotype.Component;
import org.wso2.diagnose.databaseresponsetiming.configdto.TestConfig;

import javax.sql.DataSource;
import java.sql.Connection;
import java.sql.ResultSet;
import java.sql.ResultSetMetaData;
import java.sql.Statement;

@Component
@EnableAsync
public class DBTester implements InitializingBean {
    Logger log = LoggerFactory.getLogger(DBTester.class);

    @Autowired
    private TestConfig testConfig;

    @Autowired
    private DataSource dataSourceConfig;

    @Override
    @Async
    public void afterPropertiesSet() throws Exception {
        Connection connection = null;
        long sumTimesGetConnection = 0;
        try {
            int j = 1;
            if (testConfig.getTotalIterations() < 0) {
                log.info("Running till interrupting.....!");
            }
            while (testConfig.getTotalIterations() < 0 || j <= testConfig.getTotalIterations()) {
                log.info("Staring test round : " + j);
                long start = System.currentTimeMillis();
                connection = dataSourceConfig.getConnection();
                log.info("Connection : " + connection.getMetaData().getURL() + " | Time to (ms) getConnection : "
                        + (System.currentTimeMillis() - start));
                sumTimesGetConnection += (System.currentTimeMillis() - start);
                log.info("Starting to iterate test round " + j + " for : "
                        + testConfig.getIterationsPerConnection() + " times | Query : " + testConfig.getQuery());
                long avaRespTim = 0;
                long avaRSTim = 0;
                for (int i = 1; i <= testConfig.getIterationsPerConnection(); i++) {
                    Statement st = connection.createStatement();
                    start = System.currentTimeMillis();
                    ResultSet rs = st.executeQuery(testConfig.getQuery());
                    log.info("Test round " + j + " iteration : " + i + " | Time to execute query (ms) : "
                            + (System.currentTimeMillis() - start));
                    avaRespTim += (System.currentTimeMillis() - start);
                    start = System.currentTimeMillis();
                    int count = 0;
                    ResultSetMetaData rsmd = rs.getMetaData();
                    int columnsNumber = rsmd.getColumnCount();
                    while (rs.next()) {
                        count++;
                        log.debug("Getting result.....");
                        if (testConfig.getLogResultSet()){
                            for (int n = 1; n <= columnsNumber; n++) {
                                try {
                                    String columnValue = rs.getString(n);
                                    log.info( rsmd.getColumnName(n) + " - " +  columnValue);
                                }catch (ClassCastException e){
                                    log.error( "Error while casting java.sql.Type: " + rsmd.getColumnType(n)+ " to string", e);
                                }
                            }
                        }
                    }
                    log.info("Test round " + j + " iteration : " + i + " | Time to iterate through "
                            + count + " items in result set in (ms) : " + (System.currentTimeMillis() - start));
                    avaRSTim = (System.currentTimeMillis() - start);
                }
                log.info("Average time to executeQuery (ms) : " + (avaRespTim / testConfig.getIterationsPerConnection()));
                log.info("Average time to rs.next() (ms) : " + (avaRSTim / testConfig.getIterationsPerConnection()));
                log.debug("Sleeping for : " + testConfig.getSleepTime());
                Thread.sleep(testConfig.getSleepTime());
                connection.close();
                j++;
            }
            log.info("Average time to get connection (ms) : " + (sumTimesGetConnection / testConfig.getTotalIterations()));
        } catch (Exception e) {
            log.error(e.getMessage());
        }
    }
}
