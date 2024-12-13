# Identifying Spring Dependencies
Use the following scripts to identify any custom Spring dependencies used in the WSO2 Identity Server.

**Linux**
1. **Download the Script**: [spring-dependencies.sh](spring-dependencies.sh)
2. **Execute the Script:**
    - Run the command:
      ```
      bash spring-dependencies.sh <IS_HOME>
      ```
    - Example:
      ```
      bash spring-dependencies.sh /opt/wso2/wso2is-5.11.0
      ```
3. **Review the Results:**
The output file, *results.txt*, will list the Spring dependencies present in your WSO2 IS deployment.

**Windows**
1. **Download the Script**: [spring-dependencies.ps1](spring-dependencies.ps1)
2. **Execute the Script:**
    - Run the command:
      ```
      .\spring-dependencies.ps1 <IS_HOME>
      ```
    - Example:
      ```
      .\spring-dependencies.ps1 D:\WSO2\wso2is-5.11.0
      ```
3. **Review the Results:**
The output file, *results.txt*, will list the Spring dependencies present in your WSO2 IS deployment.

**Docker**
1. **Execute the following grep command inside the pod running your Docker container, navigating to `<IS_HOME>`.**
     ```
      grep -r "org.springframework"  repository/deployment/server/webapps repository/components/dropins > results.txt
      ```
2. The output file, *results.txt*, will list the Spring dependencies present in your WSO2 IS deployment.
