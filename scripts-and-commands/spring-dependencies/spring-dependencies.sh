#!/bin/bash
# Check if IS_HOME is provided as a command-line argument
if [ -z "$1" ]; then
    echo "Usage: $0 <IS_HOME>"
    exit 1
fi

IS_HOME="$1"
WEBAPP_DIR="${IS_HOME}/repository/deployment/server/webapps"

# Define the search pattern
search_pattern="org.springframework"

# Define an array of directories to grep
include_dirs=(
    "${WEBAPP_DIR}"
    "${IS_HOME}/repository/components/dropins"
)

# Define an array of directories to exclude from grep
exclude_dirs=(
    "${WEBAPP_DIR}/api#users#v1"
    "${WEBAPP_DIR}/api#users#v1#recovery"
    "${WEBAPP_DIR}/forgetme#v1.0"
    "${WEBAPP_DIR}/wso2"
    "${WEBAPP_DIR}/api#identity#oauth2#dcr#v1.1"
    "${WEBAPP_DIR}/api#identity#oauth2#v1.0"
    "${WEBAPP_DIR}/api#identity#config-mgt#v1.0"
    "${WEBAPP_DIR}/api#identity#oauth2#uma#permission#v1.0"
    "${WEBAPP_DIR}/scim2"
    "${WEBAPP_DIR}/oauth2"
    "${WEBAPP_DIR}/api#identity#entitlement"
    "${WEBAPP_DIR}/api#identity#consent-mgt#v1.0"
    "${WEBAPP_DIR}/api#identity#recovery#v0.9"
    "${WEBAPP_DIR}/mexut"
    "${WEBAPP_DIR}/api#identity#auth#v1.1"
    "${WEBAPP_DIR}/api#health-check#v1.0"
    "${WEBAPP_DIR}/api#users#v2#me#webauthn"
    "${WEBAPP_DIR}/api"
    "${WEBAPP_DIR}/api#identity#oauth2#uma#resourceregistration#v1.0"
    "${WEBAPP_DIR}/api#identity#user#v1.0"
    "${WEBAPP_DIR}/api#identity#template#mgt#v1.0.0"
)

# Build the --exclude-dir argument
exclude_args=()
for dir in "${exclude_dirs[@]}"; do
    exclude_args+=("--exclude-dir=$dir")
done

# Capture the grep output
output=$(grep -r "$search_pattern" "${exclude_args[@]}" "${include_dirs[@]}" 2>/dev/null)

# Check if the output is empty
if [[ -z "$output" ]]; then
    echo "There are no Spring dependencies." | tee results.txt
else
    echo "List of Spring dependencies found:" | tee results.txt
    echo "$output"
fi