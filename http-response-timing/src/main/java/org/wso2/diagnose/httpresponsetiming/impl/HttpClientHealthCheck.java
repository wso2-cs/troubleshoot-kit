/*
 * Copyright (c) 2021
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *    http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

package org.wso2.diagnose.httpresponsetiming.impl;


import org.wso2.diagnose.httpresponsetiming.HealthCheckDataHolder;
import org.wso2.diagnose.httpresponsetiming.LogInfo;
import org.wso2.diagnose.httpresponsetiming.MonitoringToolsException;
import org.wso2.diagnose.httpresponsetiming.dto.WebsiteMonitoringMetadata;
import org.wso2.diagnose.httpresponsetiming.dto.WebsiteStatus;
import org.wso2.diagnose.httpresponsetiming.repositories.HealthCheckRepository;
import org.wso2.diagnose.httpresponsetiming.utils.LoggingUtils;
import org.wso2.diagnose.httpresponsetiming.utils.MonitoringToolsUtils;
import org.apache.http.HttpEntity;
import org.apache.http.HttpResponse;
import org.apache.http.client.methods.HttpGet;
import org.apache.http.impl.client.CloseableHttpClient;
import org.apache.http.impl.client.HttpClients;
import org.apache.http.util.EntityUtils;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.scheduling.annotation.Async;
import org.springframework.stereotype.Component;

import java.io.IOException;

@Component
public class HttpClientHealthCheck implements HealthCheckRepository {

    private static Logger log = LoggerFactory.getLogger(HttpClientHealthCheck.class);
    private CloseableHttpClient client;
    private HttpGet httpGet;
    private WebsiteMonitoringMetadata metadata;

    public HttpClientHealthCheck() {
    }


    /***
     * Execute the check and calculate the time for the round trip
     * @throws MonitoringToolsException
     */
    @Override
    @Async
    @LogInfo
    public void executeCheck() throws MonitoringToolsException {
        long start = System.currentTimeMillis();
        HttpResponse response = (HttpResponse) getHTTPResponse();
        Long executionTime = MonitoringToolsUtils.calculateTimeDifference(start, System.currentTimeMillis());
        if (response.getStatusLine().getStatusCode() == metadata.getExpectedStatusCode()) {
            HttpEntity responseEntity = response.getEntity();
            String responseBody;
            try {
                responseBody = EntityUtils.toString(responseEntity);
            } catch (IOException e) {
                throw new MonitoringToolsException("IO Exception while reading the response.", e);
            } finally {
                try {
                    client.close();
                } catch (IOException e) {
                    throw new MonitoringToolsException("IO Exception while closing the connection", e);
                }
            }
            if (MonitoringToolsUtils.checkContentContainsPattern(responseBody, metadata.getExpectedResponseRegEx())) {

                WebsiteStatus websiteStatus = new WebsiteStatus(metadata.getUrl().trim(), System.currentTimeMillis(),
                        executionTime, WebsiteStatus.STATUS.ACTIVE);
                HealthCheckDataHolder.getHealthCheckDataHolder().setLatestWebsiteStatus(metadata.getUrl().trim(),
                        websiteStatus);
                LoggingUtils.logResponse(websiteStatus, response.getStatusLine().getStatusCode(),
                        response.getStatusLine().toString(), metadata.getExpectedStatusCode());
            } else {
                WebsiteStatus websiteStatus = new WebsiteStatus(metadata.getUrl().trim(), System.currentTimeMillis(),
                        executionTime, WebsiteStatus.STATUS.RESPONSE_DOSE_NOT_MATCH);
                HealthCheckDataHolder.getHealthCheckDataHolder().setLatestWebsiteStatus(metadata.getUrl().trim(),
                        websiteStatus);
                LoggingUtils.logResponse(websiteStatus, response.getStatusLine().getStatusCode(),
                        response.getStatusLine().toString(), metadata.getExpectedStatusCode());
            }
        } else {

            WebsiteStatus websiteStatus = new WebsiteStatus(metadata.getUrl().trim(), System.currentTimeMillis(),
                    executionTime, WebsiteStatus.STATUS.INACTIVE);
            HealthCheckDataHolder.getHealthCheckDataHolder().setLatestWebsiteStatus(metadata.getUrl().trim(),
                    websiteStatus);
            LoggingUtils.logResponse(websiteStatus, response.getStatusLine().getStatusCode(),
                    response.getStatusLine().toString(), metadata.getExpectedStatusCode());
        }

    }

    /***
     * Set the website metadata to check
     * @param metadata Metadata specified in YAML config
     */
    @Override
    public void setWebsiteMonitoringMetadata(WebsiteMonitoringMetadata metadata) {
        this.metadata = metadata;
        client = HttpClients.createSystem();
        httpGet = new HttpGet(metadata.getUrl());
        if (metadata.getOptionalHeaders() != null) {
            metadata.getOptionalHeaders().forEach((key, val) -> {
                httpGet.setHeader(key, val);
            });
        }
    }

    /***
     * Invoke the website and get response.
     * @return response of the HTTP Call
     * @throws MonitoringToolsException
     */
    @Override
    public Object getHTTPResponse() throws MonitoringToolsException {
        try {
            return client.execute(httpGet);
        } catch (IOException e) {
            throw new MonitoringToolsException("IO Exception while making the request", e);
        }
    }
}
