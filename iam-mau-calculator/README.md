# Monthly Active User Count Calculator

This script can be used to calculate the MAU count processing the audit log files.

When using this script all the audit log files from all the nodes of the cluster should be copied to an appropriate server directories. You can use the below available options when executing this.

```
Usage: python3 mau-analysis.py [options]
Options:
  -h, --help            Show the help message and exit.
  -v, --version         Show version information.
  -st, --start-year     Start year for the analysis. Default value is 1970.
  -et, --end-year       End year for the analysis. Default value is current year.
  -p, --path            Audit log file directory path. If required to pass multiple directories use '|' separated values.
 Example: -p /home/user1/audit-logs|/home/user2/audit-logs
 Note: If the path is not provided the script will use the current working directory.
The use of multiple directories is helpful when you have audit logs in multiple nodes.
  -m, --months          Time duration in months. Default value is 3 months. This is not available yet.
  -d                    Enable debug mode. By default debug mode is disabled.
```
