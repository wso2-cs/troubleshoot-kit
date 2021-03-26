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

public class MonitoringToolsConstants {
    public static final String MESSAGE_COMMON_LOGGER = "URL : %s | Current status marked as : %s | Time to respond : %s | Status code received : %s | HTTP Response Status : %s | Message : ";
    public static final String SUCCESSFUL_RESPONSE_MESSAGE_LOGGER = MESSAGE_COMMON_LOGGER + "Successful response received with expected body.";
    public static final String ERROR_RESPONSE_MESSAGE_LOGGER = MESSAGE_COMMON_LOGGER +"Unsuccessful attempt, unexpected content in body.";
    public static final String ERROR_CODE_MESSAGE_LOGGER = MESSAGE_COMMON_LOGGER + "Unexpected error code received (expecting %s)";
    public static final String GENERAL_ERROR_MESSAGE_LOGGER = "Error occurred while making monitoring health";
    public static final String CLIENT_TRUST_STORE_LOCATION = "javax.net.ssl.trustStore";
    public static final String CLIENT_TRUST_STORE_PASSWORD = "javax.net.ssl.trustStorePassword";
}
