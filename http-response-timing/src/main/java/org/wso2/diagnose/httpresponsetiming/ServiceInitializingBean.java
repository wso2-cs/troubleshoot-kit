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

package org.wso2.diagnose.httpresponsetiming;

import org.wso2.diagnose.httpresponsetiming.dto.MonitoringConfigurations;
import org.wso2.diagnose.httpresponsetiming.dto.WebsiteStatus;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.InitializingBean;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Component;

@Component
public class ServiceInitializingBean implements InitializingBean {

    private static Logger log = LoggerFactory.getLogger(ServiceInitializingBean.class);

    @Autowired
    private MonitoringConfigurations monitoringConfigurations;

    /***
     * Initialize the Monitoring application
     */
    private void init() {
        log.info("Starting The Monitoring Service.......!");
        log.info("Monitoring Frequency : " + monitoringConfigurations.getMonitoringFrequency() + "s");
        log.info("Global Timeout : " + monitoringConfigurations.getGlobalTimeout() + "s");
        if (monitoringConfigurations.getTrustStoreLocation() != null
                && monitoringConfigurations.getTrustStorePassword() != null) {
            System.setProperty(MonitoringToolsConstants.CLIENT_TRUST_STORE_LOCATION, monitoringConfigurations
                    .getTrustStoreLocation());
            System.setProperty(MonitoringToolsConstants.CLIENT_TRUST_STORE_PASSWORD, monitoringConfigurations
                    .getTrustStorePassword());
            log.info("Trusted certificate location : " + monitoringConfigurations.getTrustStoreLocation());
        }
        if ((monitoringConfigurations.getWebsiteMonitoringMetadata() != null)
                && !monitoringConfigurations.getWebsiteMonitoringMetadata().isEmpty()) {
            org.wso2.diagnose.httpresponsetiming.HealthCheckDataHolder holder = org.wso2.diagnose.httpresponsetiming.HealthCheckDataHolder.getHealthCheckDataHolder();
            monitoringConfigurations.getWebsiteMonitoringMetadata().forEach(item -> {
                holder.setLatestWebsiteStatus(item.getUrl().trim(), new WebsiteStatus());
                log.info("Monitoring data initialized for : " + item.getUrl());
            });
        }

        log.info("Monitoring service started .......!");

    }

    @Override
    public void afterPropertiesSet() throws Exception {
        init();
    }
}
