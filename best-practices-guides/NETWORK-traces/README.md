# Best Practices for Sharing Network Traces

## Introduction

Sharing network traces with the WSO2 customer success team is a valuable step in troubleshooting web-related issues. 
To make the process easier and more secure, you may use the SAML tracer plugin in your web browser. 
This tool simplifies the capture of network traces and automatically masks sensitive information. 
In cases where the SAML tracer is not possible to use, we provide guidelines for capturing and sanitizing 
[HTTP archives (HAR)](/HAR-capture/README.md). This guide outlines best practices for both methods.

### What is a Network Trace?

A network trace, also known as an HTTP trace, is a log of network activity in a web browser or application. 
It can include sensitive information like cookies, authorization headers, and more. 
While these details are crucial for diagnosing issues, they should be sanitized before sharing the trace

### Why Sanitize a Network Trace?

Sensitive information, if not removed, can pose security risks when sharing network traces. This data may include:
- Cookies with session information
- Authorization headers
- Passwords
- Tokens and API keys

### How to Use SAML Tracer

1. You may utilize the SAML tracer to share HTTP traces when necessary, as it comes with built-in masking capabilities. 
For detailed information on how to obtain the SAML trace, please refer to
[SAML Trace Capture](/SAML-trace-capture/README.md).

2. Most importantly, ensure that you select the 'Mask values' option when exporting the SAML tracer file.

### Precautions with HAR file

It is possible to obtain HTTP Traces using browser-inbuilt tools in cases where the SAML tracer is not available. 
You can refer to [HAR Capture](/HAR-capture/README.md) for more information on obtaining the Browser trace.

- Make sure to use a test user account with low privileges to reproduce the test-case.
- If a test user cannot be used, you must review the network trace and carefully inspect the contents for 
sensitive information.
- If you’re manually editing the sensitive information, you must ensure consistency in the structure and timing of 
network requests. 
- Save the sanitized trace with a different name to distinguish it from the original (e.g., add "`_sanitized.har`"
to the filename). 
- Import the sanitized HAR file into a credible browser to validate that the changes were successful and that 
no issues have arisen. 
- Upload the sanitized network trace to your support request, mentioning that the file has been sanitized to 
protect sensitive information.

Moreover, you have the option to use Unix/Linux commands to search for and replace sensitive data.
The provided command serves as an example for replacing/masking sensitive information within a HAR file.
```
sed -i -e ':a' -e 'N' -e '$!ba' -e 's/\n/ /g' -e 's/password=[^&]*/password=MASKED/g' -e "s/\(\"name\":.\"password[^:]*:.\"\)\([^\"]*\)/\1\MASKED/g" -e "s/\(commonAuthId=\)\([^;]*;\)/\1md5{$(echo -n \2 | md5sum | sed 's/ .*$//')};/g" -e "s/\(JSESSIONID=\)\([^\";]*\)/\1md5{$(echo -n \2 | md5sum | sed 's/ .*$//')}/g" -e "s/\(\"name\":*[^:]*:.\"Bearer.\)\([^\"]*\)/\1md5-$(echo -n \2 | md5sum)/g" -e "s/\(\"name\":.\"id_token_hint[^:]*:.\"\)\([^\"]*\)/\1md5{$(echo -n \2 | md5sum | sed 's/ .*$//')}/g" -e "s/\(id_token_hint=\)\([^&]*\)/\1md5{$(echo -n \2 | md5sum | sed 's/ .*$//')}/g"  -e "s/\(samlssoTokenId=\)\([^\";]*\)/\1md5{$(echo -n \2 | md5sum | sed 's/ .*$//')}/g" -e 's/\"cookies\":\s*[^]]*/\"cookies\": [/g' network-trace.har```
