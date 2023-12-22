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
    ct = datetime.now()    
    file = open(cwd + "/mau_analysis_log.txt", "w")
    message = "[" + ct.strftime("%m/%d/%Y, %H:%M:%S") + "]" + " - Log file created." + "\n"
    file.write(message)
    print_stdout(message)
    file.close()

# This function will log the message to a file and std output
def log(message):
    # ct stores current time
    ct = datetime.now()    
    file = open(cwd + "/mau_analysis_log.txt", "a")
    message = "[" + ct.strftime("%m/%d/%Y, %H:%M:%S") + "]" + " - " + message + "\n"
    file.write(message)
    print_stdout(message)
    file.close()

# This function will log the message to a file and std output if the verbos is enabled
def debug_log(message):
    if (debug):
        log(message)

# This function will delete the log file if it exists
def delete_log_file():
    if os.path.exists("mau_analysis_log.txt"):
        os.remove("mau_analysis_log.txt")

# This function will print the message to std output
def print_stdout(message):    
    print(message)

# This function will parse the audit log line and return the initiator, action and result
def parse_audit_log_entry(log_line):
    if (re.search('\[\d{4}-\d{2}-\d{2} \d{2}:\d{2}:\d{2},\d{3}\]', log_line) is not None):
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
    else: 
        return None, None, None, None

# Process a single audit log file for the given time period
def process_single_file(filename, timePeriod):
    global all_logins
    users = set()
    debug_log("Scanning audit log file: " + filename + " ........")
    file = open(filename, 'r')
    lines = file.readlines()
    debug_log(f"Total log lines for the file: " + filename + " is: " + str(len(lines)))
    for log_line in lines:
        timeStamp, initiator, action, result = parse_audit_log_entry(log_line)
        # If the log line is not in the expected format we will skip it
        if (timeStamp is None):
            continue
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
    global uniqueUsers
    # If the audit log file paths are provided current working directories will be changed and process the files
    if (auditLogFilePath is not None):
        if ("|" in auditLogFilePath):
            for path in auditLogFilePath.split("|"):
                os.chdir(path)
                for filename in os.listdir():
                    if filename.startswith("audit"):
                        temp_uniqueUsers = process_single_file(filename, timePeriod)
                        uniqueUsers = uniqueUsers.union(temp_uniqueUsers)
        # If the audit log file path is not present current directory will be used
        else:
            os.chdir(auditLogFilePath)
            for filename in os.listdir():
                if filename.startswith("audit"):
                    temp_uniqueUsers = process_single_file(filename, timePeriod)
                    uniqueUsers = uniqueUsers.union(temp_uniqueUsers)

# This function will return directory key for MAU count for given year and month
def get_mau_count_key(year, month):
    return str(year) + "-" + str(month) + "MAU"

# This function will return directory key for total count for given year and month
def get_total_count_key(year, month):
    return str(year) + "-" + str(month) + "TC"

# This function will initialize the MAU count holder
def initialize_mau_count_holder():
    global mau_count_holder
    global startYear
    global endYear
    global startMonth
    global endMonth
    global currentYear
    global currentMonth
    if (startYear == endYear):
        for logYear in range (int(startYear), int(endYear) + 1):
            for logMonth in range(startMonth, endMonth):
                mau_count_key = get_mau_count_key(logYear, logMonth)
                mau_count_holder[mau_count_key] = 0
                total_count_key = get_total_count_key(logYear, logMonth)
                mau_count_holder[total_count_key] = 0
    if (startYear < endYear):
        for logYear in range (int(startYear), int(endYear) + 1):
            if (logYear == startYear):
                for logMonth in range(startMonth, 13):
                    mau_count_key = get_mau_count_key(logYear, logMonth)
                    mau_count_holder[mau_count_key] = 0
                    total_count_key = get_total_count_key(logYear, logMonth)
                    mau_count_holder[total_count_key] = 0
            elif (logYear <= endYear):
                for logMonth in range(1, endMonth):
                    mau_count_key = get_mau_count_key(logYear, logMonth)
                    mau_count_holder[mau_count_key] = 0
                    total_count_key = get_total_count_key(logYear, logMonth)
                    mau_count_holder[total_count_key] = 0

# This function will calculate the MAU count for the given time period
def calculate_mau_count(year, month):
    global uniqueUsers
    global all_logins
    mau_count = 0
    monthString = f"{month:02}"
    mau_count = len(uniqueUsers)
    uniqueUsers.clear()
    loginCount = len(all_logins)
    all_logins.clear()
    log(f"MAUs calculated for {year}-{monthString} is: " + str(mau_count))
    log(f"Total Logins for {year}-{monthString} is: " + str(loginCount))

def main():
    #TODO: Need to get months as arguments too
    #TODO: Need to improve for generate MAU reports and Total login reports.
    #TODO: Need to improve for faster log processing with single iteration

    # Current working directory
    global cwd
    cwd = os.getcwd()

    # Enable debug mode
    global debug
    debug = False

    # Set to store unique users
    global uniqueUsers 
    uniqueUsers = set()

    # Set to store total login attempts
    global all_logins 
    all_logins = []

    # Audit log file path
    global auditLogFilePath
    auditLogFilePath = cwd

    # Total arguments
    n = len(sys.argv)

    # Default start year
    global startYear
    startYear = 1970

    # Default start month
    global startMonth
    startMonth = 1

    # Default end year
    global endYear

    # Default end month
    global endMonth
    endMonth = 12

    # Default current Year
    global currentYear
    currentYear = datetime.now().year

    # Current Month
    global currentMonth
    currentMonth = datetime.now().month

    # Selected Time Period. Default value is last three months
    global timePeriod
    # TODO: Need to change the default value to 3
    timePeriod = None

    # Data structure to hold the MAU count for each month
    global mau_count_holder
    mau_count_holder = {}

    # If the log file exisits we needs to delte
    delete_log_file()

    # Creating the log file
    create_log_file()

    # Processing passed arguments
    for i in range(1, n):
        if (sys.argv[i] == "-h" or sys.argv[i] == "--help"):
            print("Usage: python3 mau-analysis.py [options]")
            print("Options:")
            print("  -h, --help            Show the help message and exit.")
            print("  -v, --version         Show version information.")
            print("  -st, --start-year     Start year for the analysis. Default value is 1970.")
            print("  -et, --end-year       End year for the analysis. Default value is current year.")
            print("  -p, --path            Audit log file directory path. If required to pass multiple directories use '|' separated values.\n Example: -p /home/user1/audit-logs|/home/user2/audit-logs \n Note: If the path is not provided the script will use the current working directory. \nThe use of multiple directories is helpful when you have audit logs in multiple nodes.")
            print("  -m, --months          Time duration in months. Default value is 3 months.")
            print("  -d                    Enable debug mode. By default debug mode is disabled.")
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
        if (sys.argv[i] == "-p" or sys.argv[i] == "--path"):
            if (i + 1 < n):
                auditLogFilePath = sys.argv[i + 1]
                log("Audit Log File Path: " + auditLogFilePath)
            else:
                print("Audit Log File Path is missing. Please provide a valid path. Use -h or --help for more information.")
                exit()
        if (sys.argv[i] == "-m" or sys.argv[i] == "--months"):
            if (i + 1 < n):
                timePeriod = int(sys.argv[i + 1])
                log("Time Duration selected: " + timePeriod + " months.")
            else:
                print("Time Duration(months) is invalid. Please set a integer value to define required no of months. Use -h or --help for more information.")
                exit()
        if (sys.argv[i] == "-d"):
            debug = True
            log("Debug mode enabled.")
        
    # If End Year is not provided we will use the current year
    endYear = currentYear

    # If the time period is set we will calculate the start and end year and month
    if (timePeriod is not None):
        if (currentMonth - timePeriod <= 0):
            startYear = currentYear - 1
            startMonth = 12 - (timePeriod - currentMonth)
        else:
            startYear = currentYear
            startMonth = currentMonth - timePeriod
        endMonth = currentMonth

    # Initializing the MAU count holder
    # TODO: Need to use mau_count_holder to generate MAU reports and Total login reports.
    # initialize_mau_count_holder()

    log("Monthly Active User Calculation script started.")

    # Converting the start and end year to int
    startYear = int(startYear)
    endYear = int(endYear)

    for logYear in range (int(startYear), int(endYear) + 1):
        if (startYear == endYear):
            for logMonth in range(startMonth, endMonth):
                # Time period for the given year and month
                timePeriod = datetime(year = logYear, month = logMonth, day = 1)
                # Processing all audit log files for the given year and month
                process_all_audit_log_files(timePeriod)
                # Calculating the MAU count
                calculate_mau_count(logYear, logMonth)
        elif (startYear < endYear):
            if (logYear < endYear + 1):
                for logMonth in range(startMonth, 13):
                    # Time period for the given year and month
                    timePeriod = datetime(year = logYear, month = logMonth, day = 1)
                    # Processing all audit log files for the given year and month
                    process_all_audit_log_files(timePeriod)
                    # Calculating the MAU count
                    calculate_mau_count(logYear, logMonth)
            elif (logYear == endYear + 1):              
                for logMonth in range(1, endMonth):
                    # Time period for the given year and month
                    timePeriod = datetime(year = logYear, month = logMonth, day = 1)
                    # Processing all audit log files for the given year and month
                    process_all_audit_log_files(timePeriod)
                    # Calculating the MAU count
                    calculate_mau_count(logYear, logMonth)

    log("Monthly Active User Calculation script ended.")    

if __name__ == '__main__':
    main()
