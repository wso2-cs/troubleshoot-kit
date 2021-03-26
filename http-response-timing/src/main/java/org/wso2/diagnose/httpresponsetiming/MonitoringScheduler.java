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
import org.wso2.diagnose.httpresponsetiming.repositories.HealthCheckRepository;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.context.annotation.Configuration;
import org.springframework.scheduling.annotation.Async;
import org.springframework.scheduling.annotation.EnableAsync;
import org.springframework.scheduling.annotation.EnableScheduling;
import org.springframework.scheduling.annotation.Scheduled;

@Configuration
@EnableScheduling
@EnableAsync
public class MonitoringScheduler {

    Logger log = LoggerFactory.getLogger(MonitoringScheduler.class);

    @Autowired
    private MonitoringConfigurations monitoringConfigurations;

    /***
     * Initiate the scheduled monitoring task
     */
    @Scheduled(fixedRateString = "${monitoringFrequency}")
    @Async
    public void scheduleFixedDelayMonitorTask() {
        if ((monitoringConfigurations.getWebsiteMonitoringMetadata() != null)
                && !monitoringConfigurations.getWebsiteMonitoringMetadata().isEmpty()) {
            monitoringConfigurations.getWebsiteMonitoringMetadata().parallelStream().forEach(site -> {
                try {
                    HealthCheckRepository httpClientHealthCheck = (HealthCheckRepository) Class.
                            forName(monitoringConfigurations.getHttpClientImpl()).newInstance();
                    httpClientHealthCheck.setWebsiteMonitoringMetadata(site);
                    httpClientHealthCheck.executeCheck();
                } catch (MonitoringToolsException e) {
                    log.error(e.getMessage(), e);
                } catch (IllegalAccessException e) {
                    log.error(e.getMessage(), e);
                } catch (InstantiationException e) {
                    log.error(e.getMessage(), e);
                } catch (ClassNotFoundException e) {
                    log.error(e.getMessage(), e);
                }
            });
        }
    }
}
