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

import java.util.Map;

/***
 * Monitoring configurations
 */
@Configuration
public class WebsiteMonitoringMetadata {
    private String url;
    private int expectedStatusCode = 200;
    private String expectedResponseRegEx = "[\\s\\S]";
    private Map<String, String> optionalHeaders;

    public String getUrl() {
        return url;
    }

    public void setUrl(String url) {
        this.url = url;
    }

    public int getExpectedStatusCode() {
        return expectedStatusCode;
    }

    public void setExpectedStatusCode(int expectedStatusCode) {
        this.expectedStatusCode = expectedStatusCode;
    }

    public String getExpectedResponseRegEx() {
        return expectedResponseRegEx;
    }

    public void setExpectedResponseRegEx(String expectedResponseRegEx) {
        this.expectedResponseRegEx = expectedResponseRegEx;
    }

    public Map<String, String> getOptionalHeaders() {
        return optionalHeaders;
    }

    public void setOptionalHeaders(Map<String, String> optionalHeaders) {
        this.optionalHeaders = optionalHeaders;
    }
}
