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

import org.springframework.context.annotation.Configuration;

/***
 * Current status of the website
 */
@Configuration
public class WebsiteStatus {
    private String website;
    private long lastUpdatedTime;
    private long lastResponseTime = 0;
    private long averageResponseTime = 0;
    private STATUS currentStatus;

    public enum STATUS {
        ACTIVE,
        INACTIVE,
        RESPONSE_DOSE_NOT_MATCH
    }

    public WebsiteStatus() {
    }

    public WebsiteStatus(String website, long lastUpdatedTime, long lastResponseTime, STATUS currentStatus) {
        this.website = website;
        this.lastUpdatedTime = lastUpdatedTime;
        this.lastResponseTime = lastResponseTime;
        this.currentStatus = currentStatus;
    }

    public String getWebsite() {
        return website;
    }

    public void setWebsite(String website) {
        this.website = website;
    }

    public STATUS getCurrentStatus() {
        return currentStatus;
    }

    public void setCurrentStatus(STATUS currentStatus) {
        this.currentStatus = currentStatus;
    }

    public long getLastUpdatedTime() {
        return lastUpdatedTime;
    }

    public void setLastUpdatedTime(long lastUpdatedTime) {
        this.lastUpdatedTime = lastUpdatedTime;
    }

    public long getLastResponseTime() {
        return lastResponseTime;
    }

    public void setLastResponseTime(long lastResponseTime) {
        this.lastResponseTime = lastResponseTime;
    }

    public long getAverageResponseTime() {
        return averageResponseTime;
    }

    public void setAverageResponseTime(long averageResponseTime) {
        this.averageResponseTime = averageResponseTime;
    }
}
