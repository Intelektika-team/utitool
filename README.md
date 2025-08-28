# Utitool

[![License](https://img.shields.io/badge/license-MIT.0-blue.svg)](LICENSE)

<img width="638" height="535" alt="Снимок экрана 2025-08-04 в 01 41 56" src="https://github.com/user-attachments/assets/c22993fd-4651-45c8-84a1-607b5dc0b521" />


# What is utitool -
This is a new utility for any user for any range of tasks -
From utitool you can open applications, sys admins can check the computer directly from it, any developer can write an additional script (for scripts you can download the template using *scri sample*) and easily integrate it into the utility.


# Why exactly she -
First, writing scripts. Thanks to them, you can optimize any task and add your own functionality that you need specifically. Scripts are written easily - according to a template. The pattern can be set using the command - scri sample
The template appears in the scripts folder of the program in the derrictory. With one command, you can install an official plugin, or download the plugin from the community and simply move it to the scripts folder, after which it will be immediately available for use.


# Installation -
- Download the zip archive of this derrictory and upload it to any free folder.
- The application is ready for use - run the utitool file (the only file without extensions) and start using it right away.


# First entry into the utility -
The first time you enter the program, it will automatically create a configuration file on the system that will assign you the *user* username and administrator password 1234. After the first access to the application, we advise you to follow the instructions -
Enter these commands to obtain administrator rights -
``` utitool
admin root
```
The message "Enter password:" appears and you must enter *1234*. If you did everything right, you will succeed as that-
```utitool
user ~ admin root
Enter password:
1234
Root access granted

user @
```
The character after the username should change from "~" to "@," which means that you have received administrator rights. Further We strongly advise you to change the password "1234" to some more reliable one. This is done as follows -
```utitool
user @ system change-password
Enter your old password:
1234
Enter new password:
123456
Confirm new password:
123456
Password changed successfully

user @
```
Instead of 123456, enter your password, preferably consisting of letters, numbers and symbols. Also, if you wish, you can change your username to your own, this is done as follows
```utitool
user @ setname utitool
Username set to utitool

utitool @
```
After that, the configuration of the utility can be completed, now it is completely ready to work.



# Script System
Write extensions in Python/Swift:
1. Set pattern: 'scri sample'
2. Edit 'scripts/script _ sample.py'
3. Run: 'scr sample'

Example script:
```python
def print_hello():
"""Example reusable function that prints a greeting."""
return "Hello, world!"

def main(*args):
"""
Main script function (required entry point).
Processes command line arguments and executes appropriate functions.
"""
if args[0] == "test":
return print_hello()
else:
print("No valid command provided.")
```
### All work with scripts takes place through 2 commands -
scri [name] - script installation
scr [name] [arguments] to run
