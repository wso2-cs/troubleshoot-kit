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

import org.springframework.stereotype.Component;

import java.util.regex.Pattern;

@Component
public class MonitoringToolsUtils {
    /***
     * Evaluate the regex and identify whether the backend is sending an expected response.
     * @param response response of backend
     * @param regex regex to validate
     * @return either response matches with the RegEx
     */
    public static boolean checkContentContainsPattern(String response, String regex) {
        return Pattern.compile(regex).matcher(response).find();
    }

    /***
     * Calculate the time taken to respond
     * @param staring
     * @param ending
     * @return time difference
     */
    public static long calculateTimeDifference(long staring, long ending) {
        return (ending - staring);
    }

    /***
     * Calculate the average response time for a perticluar website
     * @param currentAverage
     * @param newTime
     * @return
     */
    public static long calculateAverageResponseTime(long currentAverage, long newTime) {
        return (currentAverage + newTime) / 2;
    }
}
