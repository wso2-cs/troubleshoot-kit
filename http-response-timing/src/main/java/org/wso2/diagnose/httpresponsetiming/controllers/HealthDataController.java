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

package org.wso2.diagnose.httpresponsetiming.controllers;

import org.wso2.diagnose.httpresponsetiming.HealthCheckDataHolder;
import org.wso2.diagnose.httpresponsetiming.LogInfo;
import org.wso2.diagnose.httpresponsetiming.dto.MonitoringConfigurations;
import org.wso2.diagnose.httpresponsetiming.dto.WebsiteStatus;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

import java.util.Collection;

/***
 *
 */
@RestController
public class HealthDataController {

    private static Logger log = LoggerFactory.getLogger(HealthDataController.class);

    @Autowired
    private MonitoringConfigurations monitoringConfigurations;

    /***
     * This method returns the all health check current data
     * @return List of health check data
     */
    @GetMapping("/health")
    @LogInfo
    public Collection<WebsiteStatus> getAllWebsiteStatus() {
        return HealthCheckDataHolder.getHealthCheckDataHolder().getAllWebsiteStatus();
    }

    /***
     * Health check current status of a an applicaiton.
     * @param url URL of the website need to check
     * @return Status of the provided param
     */
    @GetMapping("/health-of-website")
    @LogInfo
    public ResponseEntity getWebsiteStatus(@RequestParam(required = false) String url) {
        if (url != null && !url.isEmpty()) {
            WebsiteStatus status = HealthCheckDataHolder.getHealthCheckDataHolder().getWebsiteStatus(url);
            if (status != null)
                return ResponseEntity.ok(status);
            else
                return ResponseEntity.notFound().build();
        }
        return ResponseEntity.badRequest().build();
    }
}
