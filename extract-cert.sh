#!/bin/bash

#------- CONFIGURATION -------
PATH="."
STOREPASS=changeit
GIT_PATH="/usr/bin/" #This is a mac path. e.g for Windows would be "C:/Program Files/Git/usr/bin/"
#JAVA_HOME="" to be set here, if not already set in the environment.

#Check for input argument
if [ ! $# -eq 1 ]; then
    echo "Please pass the keystore name without the extension (.jks). Example usage: $0 myjkskeystorefile"
    exit 1
fi
KEYSTORE=$1

#------- NEEDED TOOLS ---------
# Assigning tool paths/commands to a viariable is especially useful in windows env where these tools/commands 
# may not be universally available; and may be available only as part of Java SDK (keytool) or as part of git/gitbash (unix tools)
KEYTOOL=$JAVA_HOME/bin/keytool
TPUT="$GIT_PATH"tput
OPENSSL="$GIT_PATH"openssl
RM=/bin/rm # For windows - "$GIT_PATH"rm
LS=/bin/ls # For windows - "$GIT_PATH"ls

# This function checks if the file/directory exists. Usage: checkIfExists f/d file/directory_name
checkIfExists(){
    if [ ! -$1 "$2" ]; then
        echo "$2 does not exist. Exiting"
        exit 5
    fi
}

# Checking all necessary dependencies
checkIfExists d "$GIT_PATH"
checkIfExists f "$KEYTOOL"
checkIfExists f "$PATH"/"$KEYSTORE".jks

# ------- Constants for colored output ---------
RED=`"$TPUT" setaf 1`
GREEN=`"$TPUT" setaf 2`
YELLOW=`"$TPUT" setaf 3`
BLUE=`"$TPUT" setaf 4`
RESET=`"$TPUT" sgr0`
#UTF-8 hex codes for symbols
CHECK_MARK="\xE2\x9C\x94"
ERROR_MARK="\xE2\x9D\x8C"

echo
echo JAVA_HOME :: $JAVA_HOME
echo -e "Keystore Path :: " ${BLUE}$PATH${RESET}". And Keystore file :: " ${BLUE}$KEYSTORE".jks"${RESET}
echo

# This fuction checks if the last executed command returned any error code. If so, it exits after echo-ing the
# first argument passed (which is the error msg). Otherwise echo-s the second arg (success msg)
# usage: checkCmdExecution <Error Msg> <Success Msg>
checkCmdExecution(){
    #Get the return code of the last executed command
    returnCode=$?
    if [ $returnCode -ne 0 ]; then
        echo -e ${RED} $ERROR_MARK $1. Exiting.${RESET}
        exit $returnCode
    fi
    echo -e ${GREEN} $CHECK_MARK $2 ${RESET}
}

# -------------- CERT EXTRACTION -------------------------
"$KEYTOOL" -importkeystore -srckeystore "$PATH"/$KEYSTORE.jks -destkeystore keystore.p12 -deststoretype PKCS12 -srcstorepass $STOREPASS -storepass $STOREPASS
checkCmdExecution "An error occurred while running keytool." "(1/4) Extraction to PKCS12 format using keytool completed."

"$OPENSSL" pkcs12 -in keystore.p12 -nokeys -passin pass:$STOREPASS -out $KEYSTORE.crt
checkCmdExecution "An error occurred while running openssl to generate .crt file." "(2/4) Creating .crt file using OpenSSL completed."

"$OPENSSL" pkcs12 -in keystore.p12 -passin pass:$STOREPASS -nocerts -nodes -out $KEYSTORE.key
checkCmdExecution "An error occurred while running openssl to generate .key file." "(3/4) Creating .key file using OpenSSL completed." 

# --------------- Cleaning up -----------------------
"$RM" -f keystore.p12
checkCmdExecution "An error occurred while deleting the temp file keystore.p12." "(4/4) Cleanup completed."

echo -e "Generated files are present in the current directory : ${BLUE}${PWD}"${YELLOW}
echo
"$LS" -l $KEYSTORE.crt $KEYSTORE.key
echo
echo ${GREEN}"SCRIPT EXECUTION COMPLETED SUCCESSFULLY."${RESET}
