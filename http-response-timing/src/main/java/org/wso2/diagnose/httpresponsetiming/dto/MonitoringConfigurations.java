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

package org.wso2.diagnose.httpresponsetiming.dto;

import org.springframework.boot.context.properties.ConfigurationProperties;
import org.springframework.boot.context.properties.NestedConfigurationProperty;
import org.springframework.context.annotation.Configuration;

import java.util.List;

/***
 * Hold the config map of YAML
 */
@Configuration
@ConfigurationProperties
public class MonitoringConfigurations {
    private int monitoringFrequency;
    private int globalTimeout;
    private String httpClientImpl = "org.wso2.diagnose.httpresponsetiming.impl.HttpClientHealthCheck";
    private String trustStoreLocation;
    private String trustStorePassword;
    @NestedConfigurationProperty
    private List<WebsiteMonitoringMetadata> websiteMonitoringMetadata;

    public String getHttpClientImpl() {
        return httpClientImpl;
    }

    public void setHttpClientImpl(String httpClientImpl) {
        this.httpClientImpl = httpClientImpl;
    }

    public int getMonitoringFrequency() {
        return monitoringFrequency;
    }

    public void setMonitoringFrequency(int monitoringFrequency) {
        this.monitoringFrequency = monitoringFrequency;
    }

    public int getGlobalTimeout() {
        return globalTimeout;
    }

    public void setGlobalTimeout(int globalTimeout) {
        this.globalTimeout = globalTimeout;
    }

    public String getTrustStoreLocation() {
        return trustStoreLocation;
    }

    public void setTrustStoreLocation(String trustStoreLocation) {
        this.trustStoreLocation = trustStoreLocation;
    }

    public String getTrustStorePassword() {
        return trustStorePassword;
    }

    public void setTrustStorePassword(String trustStorePassword) {
        this.trustStorePassword = trustStorePassword;
    }

    public List<WebsiteMonitoringMetadata> getWebsiteMonitoringMetadata() {
        return websiteMonitoringMetadata;
    }

    public void setWebsiteMonitoringMetadata(List<WebsiteMonitoringMetadata> websiteMonitoringMetadata) {
        this.websiteMonitoringMetadata = websiteMonitoringMetadata;
    }
}
