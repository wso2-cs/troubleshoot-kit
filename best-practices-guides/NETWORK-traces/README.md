# Best Practices for Sharing Network Traces from Web Browsers

## Introduction

Sharing network traces with the WSO2 customer success team is a valuable step in troubleshooting web-related issues.
To make the process easier and more secure, you may use the [SAML tracer plugin](/SAML-trace-capture/README.md) in your web browser. 
This tool simplifies the capture of network traces and automatically masks sensitive information.
In cases where the SAML tracer is not possible to use, we provide guidelines for capturing and sanitizing 
[HTTP archives (HAR)](/HAR-capture/README.md). This guide outlines best practices for both methods.

### What is a Network Trace?

A network trace, also known as an HTTP trace, is a log of network activity in a web browser or application. 
It can include sensitive information like cookies, authorization headers, and more.
While these details are crucial for diagnosing issues, they should be sanitized before sharing the trace.

### Why Sanitize a Network Trace?

If not removed, sensitive information can pose security risks when sharing network traces. This data may include:
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

- Ensure you use a test user account with low privileges to reproduce the test case and reset the password.
- If a test user account cannot be used, utilize the [HAR Sanitizer Tool](https://wso2-cs.github.io/har-sanitizer-tool).
- This tool sanitizes sensitive data, providing the capability to hash or remove it entirely from your network traces. It ensures your session cookies, authorization headers, and other sensitive information remain private.
- The tool employs client-side logic to sanitize HAR files, allowing you to share troubleshooting data without compromising security.
- Upload the sanitized network trace to your support request, specifying that the file has been sanitized to protect sensitive information.
