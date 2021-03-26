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


import org.wso2.diagnose.httpresponsetiming.dto.WebsiteStatus;
import org.wso2.diagnose.httpresponsetiming.utils.MonitoringToolsUtils;
import org.springframework.stereotype.Component;

import java.util.Collection;
import java.util.HashMap;
import java.util.Map;

/***
 * In memory data store of website health
 */
@Component
public class HealthCheckDataHolder {
    private static Map<String, WebsiteStatus> latestWebsiteStatus = new HashMap<>();
    private static HealthCheckDataHolder healthCheckDataHolder = null;

    private HealthCheckDataHolder() {
    }

    /***
     * Singleton of HealthCheckDataHolder
     * @return single object of HealthCheckDataHolder
     */
    public static HealthCheckDataHolder getHealthCheckDataHolder() {
        if (healthCheckDataHolder == null) {
            healthCheckDataHolder = new HealthCheckDataHolder();
        }
        return healthCheckDataHolder;
    }

    public WebsiteStatus getWebsiteStatus(String url) {
        return latestWebsiteStatus.get(url);
    }

    /***
     * Set the latest website status
     * @param url
     * @param status
     */
    public void setLatestWebsiteStatus(String url, WebsiteStatus status) {
        WebsiteStatus temp = latestWebsiteStatus.get(url.trim());

        if (temp != null && temp.getAverageResponseTime() == 0L) {
            status.setAverageResponseTime(status.getLastResponseTime());
        } else if (temp != null) {
            status.setAverageResponseTime(MonitoringToolsUtils
                    .calculateAverageResponseTime(temp.getAverageResponseTime(), status.getLastResponseTime()));
        }
        latestWebsiteStatus.put(url, status);
    }

    /***
     * Get all the website status
     * @return List of website health information
     */
    public Collection<WebsiteStatus> getAllWebsiteStatus() {
        return latestWebsiteStatus.values();
    }
}

