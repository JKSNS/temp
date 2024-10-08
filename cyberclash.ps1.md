# Educational Walkthrough: Using the Privilege Escalation Script

## Overview
This script is intended for educational purposes only. It demonstrates various techniques commonly used in penetration testing and red team exercises, such as privilege escalation, persistence, and evasion techniques. Below, we provide a walkthrough to help you understand and use the script in a safe, controlled environment.

### **Step-by-Step Guide**

#### **Prerequisites**
1. **Administrative Privileges**: You need administrative access to the Windows machine where you will run this script.
2. **PowerShell Execution Policy**: Make sure the PowerShell execution policy allows the running of scripts. You can set it with the following command:
   ```powershell
   Set-ExecutionPolicy -ExecutionPolicy Unrestricted -Scope CurrentUser
   ```
3. **Controlled Environment**: Only run this script in a virtual machine or a testing environment that you own and have explicit permission to use.

#### **Step 1: Escalate Privileges**
The `Escalate-Privileges` function attempts to open a new PowerShell session with administrative privileges. This is necessary to perform many of the subsequent actions.

- Run the script using a PowerShell terminal.
- The function will prompt for administrative privileges.

#### **Step 2: Create an Immutable User Profile**
The `Create-Immutable-User` function creates a new local user with administrative privileges and sets the user's profile to be immutable (read-only).

- Provide a username and password for the new user in the script.
- This step helps demonstrate how attackers might create a persistent user account for future access.

#### **Step 3: Switch to the Newly Created User Account**
The `Switch-User` function switches to the newly created user account.

- This step simulates how attackers might switch to a new user profile to avoid detection.
- The credentials are used to create a new PowerShell session under the secure user account.

#### **Step 4: Set up a Reverse Shell for Persistent Access**
The `Open-Reverse-Shell` function establishes a reverse shell connection to a specified IP and port.

- Update the `$reverseShellIP` and `$reverseShellPort` variables with the attacker's IP address and listening port.
- This step demonstrates how attackers might establish remote access to a compromised system.

#### **Step 5: Add Registry Persistence**
The `Add-Registry-Persistence` function adds a registry entry to execute the reverse shell script on startup.

- This ensures that the reverse shell will run each time the user logs in, providing persistence.
- The script path is specified in the `$scriptPath` variable.

#### **Step 6: Add WMI Persistence**
The `Add-WMI-Persistence` function registers a WMI event that triggers the reverse shell script upon system changes.

- This demonstrates another persistence mechanism that attackers might use to maintain access.

#### **Step 7: Hide Script in Alternate Data Stream (ADS)**
The `Hide-Script-ADS` function hides the reverse shell script in an Alternate Data Stream (ADS).

- ADS is a feature of NTFS that allows hiding data within existing files.
- The script content is moved to an ADS attached to `notepad.exe`.

#### **Step 8: Add Randomized Scheduled Task for Persistence**
The `Add-Randomized-ScheduledTask` function creates a scheduled task with a randomized name that runs the reverse shell script at startup.

- This demonstrates how attackers might use scheduled tasks to maintain persistence without drawing attention.

#### **Step 9: Bypass AV/EDR by Disabling Security Processes**
The `Bypass-AV-EDR` function attempts to stop well-known antivirus and endpoint detection response (EDR) processes.

- This is an example of how attackers might try to disable security software to avoid detection.
- The list of AV processes can be modified to target specific solutions.

#### **Step 10: Delete PowerShell History and Logs**
The `Delete-PowerShell-History` function clears the PowerShell history and deletes key event logs to cover the attacker's tracks.

- This is an example of anti-forensic techniques that attackers might use to avoid detection and analysis.

#### **Step 11: Timestomping to Hide Changes**
The `TimeStomp` function changes the timestamps of the reverse shell script to make it look like it has existed on the system for a long time.

- This is another anti-forensic technique used to hide the presence of malicious files.
- The timestamp can be customized as needed.

### **Running the Script**
To execute the script, run it in an elevated PowerShell session:
1. Open PowerShell as an administrator.
2. Execute the script using the following command:
   ```powershell
   .\EducationalPrivilegeEscalation.ps1
   ```
3. Observe the output and behavior of each function, ensuring you understand what each step does and its implications.

### **Important Notes**
- **Educational Use Only**: This script is for educational purposes to understand common techniques used in attacks. Do not use it for unauthorized access or on systems you do not own.
- **Potential Risks**: Running this script can cause significant changes to the system, including creating new users, disabling security software, and modifying persistence settings. Only use it in a disposable virtual environment.
- **Cleanup**: After running the script, it is recommended to restore the system from a snapshot or rebuild the virtual machine to ensure all changes are reverted.

### **Conclusion**
This walkthrough provides an overview of how to use the privilege escalation script for educational purposes. By studying each step, you can gain insight into how attackers achieve privilege escalation, persistence, and anti-forensics. Always use such scripts ethically and responsibly in controlled environments.
