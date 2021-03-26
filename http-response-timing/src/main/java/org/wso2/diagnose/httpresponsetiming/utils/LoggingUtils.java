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

package org.wso2.diagnose.httpresponsetiming.utils;

import org.wso2.diagnose.httpresponsetiming.MonitoringToolsConstants;
import org.wso2.diagnose.httpresponsetiming.dto.WebsiteStatus;
import org.aspectj.lang.annotation.Aspect;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.stereotype.Component;

@Aspect
@Component
public class LoggingUtils {

    private static Logger log = LoggerFactory.getLogger(LoggingUtils.class);

    /***
     * Log the result based on the response.
     * @param websiteStatus Current status of the website
     * @param statusCode latest status code received
     * @param statusDescription latest status code description received
     * @param expectedStatusCode Expected status code
     */
    public static void logResponse(WebsiteStatus websiteStatus, int statusCode, String statusDescription,
                                   int expectedStatusCode) {
        String message = "";
        switch (websiteStatus.getCurrentStatus()) {
            case ACTIVE:
                message = String.format(
                        MonitoringToolsConstants.SUCCESSFUL_RESPONSE_MESSAGE_LOGGER,
                        websiteStatus.getWebsite(),
                        WebsiteStatus.STATUS.ACTIVE,
                        websiteStatus.getLastResponseTime(),
                        statusCode,
                        statusDescription
                );
                log.info(message);
                break;
            case RESPONSE_DOSE_NOT_MATCH:
                message = String.format(
                        MonitoringToolsConstants.ERROR_RESPONSE_MESSAGE_LOGGER,
                        websiteStatus.getWebsite(),
                        WebsiteStatus.STATUS.RESPONSE_DOSE_NOT_MATCH,
                        websiteStatus.getLastResponseTime(),
                        statusCode,
                        statusDescription
                );
                log.error(message);
                break;
            case INACTIVE:
                message = String.format(
                        MonitoringToolsConstants.ERROR_CODE_MESSAGE_LOGGER,
                        websiteStatus.getWebsite(),
                        WebsiteStatus.STATUS.INACTIVE,
                        websiteStatus.getLastResponseTime(),
                        statusCode,
                        statusDescription,
                        expectedStatusCode
                );
                log.error(message);
                break;
        }

    }
}