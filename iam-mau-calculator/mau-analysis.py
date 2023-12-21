import re
import os
import sys
from datetime import datetime

# This function will remove the special characters from the string
def sanatizeString(string):
    return string.replace("|", "").replace(":", "").replace("=", "").strip()

# This function will return the initiator from the log line
def getInitiator(string):
    sanatizedString = sanatizeString(string.replace("Initiator", "").replace("Action", ""))
    initiatorWithDomain = (sanatizedString.split("@carbon.super", 1))[0]
    if ("/" in initiatorWithDomain):
        domainAwareInitiator = (initiatorWithDomain.split("/", 1))[1]

        return domainAwareInitiator
    return initiatorWithDomain

# This function will return the action from the log line
def getAction(string):
    return sanatizeString(string.replace("Action", "").replace("Target", ""))

# This function will return the result from the log line
def getResult(string):
    return sanatizeString(string.replace("Result", "").replace("Outcome", ""))

# This function will create a log file
def create_log_file():
    # ct stores current time
    ct = datetime.datetime.now()    
    file = open("mau_analysis_log.txt", "w")
    file.write("[" + ct + "]" + " - Log file created.")
    print("[" + ct + "]" + " - Log file created.")
    file.close()

# This function will delete the log file if it exists
def delete_log_file():
    if os.path.exists("mau_analysis_log.txt"):
        os.remove("mau_analysis_log.txt")
        print("Log file deleted.")
    else:
        print("The file does not exist")

# This function will log the message to a file and std output
def log(message):
    # ct stores current time
    ct = datetime.datetime.now()    
    file = open("mau_analysis_log.txt", "a")
    message = "[" + ct + "]" + " - " + message
    file.write(message)
    print_stdout(message)
    file.close()

# This function will log the message to a file and std output if the verbos is enabled
def debug_log(message):
    if (debug):
        log(message)

# This function will print the message to std output
def print_stdout(message):    
    print(message)

# This function will parse the audit log line and return the initiator, action and result
def parse_audit_log_entry(log_line):
    timeStamp = datetime.strptime(re.search('\[\d{4}-\d{2}-\d{2} \d{2}:\d{2}:\d{2},\d{3}\]', log_line).group(), '[%Y-%m-%d %H:%M:%S,%f]')
    initiator = "null"
    tempInitiator = re.search('Initiator(.*)Action', log_line)
    if (tempInitiator is not None):
        initiator = getInitiator(tempInitiator.group())        

    action = "Invalid"
    tempAction = re.search('Action(.*)Target', log_line)
    if (tempAction is not None):
        action = getAction(tempAction.group())
        
    result = "Invalid"
    temResult = re.search('Result(.*)', log_line)
    if (temResult is None):
        temResult = re.search('Outcome(.*)', log_line)
    if (temResult is not None):
        result = getResult(temResult.group())
            
    return timeStamp, initiator, action, result 

# Process a single audit log file for the given time period
def process_single_file(filename, timePeriod):
    users = set()
    debug_log("Scanning audit log file: " + filename + " ........")
    file = open(filename, 'r')
    lines = file.readlines()
    debug_log("Total log lines for the file: " + filename + " is: " + len(lines))
    for log_line in lines:
        timeStamp, initiator, action, result = parse_audit_log_entry(log_line)
        if (initiator != "null" and initiator != "wso2.system.user"):
             debug_log("Initiator - " + initiator + " Action - " + action + " Result - " 
                               + result + " TimeStamp - " + str(timeStamp) + " TimePeriod - " + str(timePeriod))
        if (timeStamp.year == timePeriod.year and timeStamp.month == timePeriod.month and initiator is not None 
            and initiator != "null" and initiator != "wso2.system.user" and result.lower() == "success" and 
             action != "Invalid" and result != "Invalid" and (action == "Login" or action == "PostTokenIssue")):
            users.add(initiator)
            all_logins.append(initiator)
    return users

# Process all audit log files in the current directory for the given time period
def process_all_audit_log_files(timePeriod):
    for filename in os.listdir():
        if filename.startswith("audit"):
            uniqueUsers = uniqueUsers.union(process_single_file(filename, timePeriod))

def main():
    # Enable debug mode
    global debug
    debug = False

    # Set to store unique users
    global uniqueUsers 
    uniqueUsers = set()

    # Set to store total login attempts
    global all_logins 
    all_logins = []

    # total arguments
    n = len(sys.argv)

    # Default start year
    startYear = 1970

    # Default end year
    currentYear = datetime.datetime.now().year

    # Current Month
    currentMonth = datetime.datetime.now().month

    # If the log file exisits we needs to delte
    delete_log_file()

    # Processing passed arguments
    for i in range(1, n):
        if (sys.argv[i] == "-h" or sys.argv[i] == "--help"):
            print("Usage: python3 mau-analysis.py [-d] [-h]")
            print("-h: Help")
            exit()
        if (sys.argv[i] == "-v" or sys.argv[i] == "--version"):
            print("Version: 1.0.0")
            exit()
        if (sys.argv[i] == "-st" or sys.argv[i] == "--start-year"):
            if (i + 1 < n):
                startYear = sys.argv[i + 1]
                log("Start Year: " + startYear)
            else:
                print("Start Year is missing. Please provide a valid start year. Use -h or --help for more information.")
                exit()
        if (sys.argv[i] == "-et" or sys.argv[i] == "--end-year"):
            if (i + 1 < n):
                endYear = sys.argv[i + 1]
                log("End Year: " + endYear)
            else:
                print("End Year is missing. Please provide a valid end year. Use -h or --help for more information.")
                exit()
        if (sys.argv[i] == "-d"):
            debug = True
            log("Debug mode enabled.")
        
    # If End Year is not provided we will use the current year
    endYear = currentYear

    log("Monthly Active User Calculation script started.")
    
    for logYear in range (startYear, endYear + 1):
        for logMonth in range(1, 13):
            if (logYear == currentYear and logMonth == currentMonth):
                # We are not processing the current month as there is no point of doing that
                break
            mau_count = 0
            logMonthString = f"{logMonth:02}"
            timePeriod = datetime(year = logYear, month = logMonth, day = 1)
            # Processing all audit log files for the given year and month
            process_all_audit_log_files(timePeriod)
            # Calculating the MAU count
            mau_count = len(uniqueUsers)
            loginCount = len(all_logins)
            log(f"MAUs calculated for {logYear}-{logMonthString} is: " + str(mau_count))
            log(f"Total Logins for {logYear}-{logMonthString} is: " + str(loginCount) + "\n")

    log("Monthly Active User Calculation script ended.")    

if __name__ == '__main__':
    main()