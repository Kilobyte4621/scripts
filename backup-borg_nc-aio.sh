#!/bin/bash
# Duplicate Borg backups from nc-aio to a folder whith different permissions so Syncthing can access it. You can also use it to copy files back to an external folder in Nextcloud and apply the correct permissions so you can view it. The tool will yhen create logs about it. 
# Options: script bypass, script name, source directory, checking of destination directory's mountpoint on/off (tries to mount it), mountpoint of destination directory, chown after copy on/off, chown new owner user, destination directory, csv log filename, unmount destination mountpoint after copy, safe button for logs in the same location as the backup, logs custom location, rsync logs in different location from csv optional.
# To call the script as root you'll need to change its permissions with: "sudo chown root:root /root/backup-script.sh" and "sudo chmod 700 /root/backup-script.sh" (it doesn't need to be saved in /root , it is just an example).
# After that just add it as a cronjob with: "sudo crontab -u root -e" and add the line "*/15 * * * * /root/backup-script.sh" to run it every 15 minutes, for example.

# Run Script? (YES/NO)
RUN_SCRIPT="YES"
if [ "$RUN_SCRIPT" = "YES" ]; then

# Get current timestamp for CSV log file (beginning)
TIMESTAMP_CSV=$(date +"%Y-%m-%d %H:%M:%S")

############################################
## Change environment variables from here ##
############################################

# Define script name
SCRIPT_NAME="borg-nc_aio"

# Define source directory
SOURCE_DIR="/home/user/ncbkp"

# Do you need to check if the mountpoint is connected? (YES/NO)
MOUNTPOINT_CHECK="NO"

# Specify Mountpoint
DRIVE_MOUNTPOINT="/home/user/wd12"

# Define whether to transfer ownership of files (e.g. to use with Syncthing) (YES/NO)
CHOWN_STATUS="YES"

# Define the username of the target user who will own the copied files
## "user" if it's going to syncthing,"33" if it's going to an external folder in nextcloud 
TARGET_USER="user"

# Define the group name of the target user who will own the copied files
## Same as username if it's going to syncthing,"0" if it's going to an external folder in nextcloud 
TARGET_GROUP="user"

# Define whether to change permission of files (e.g. to transfer back to Nextcloud) (YES/NO)
CHMOD_STATUS="YES"

# Define permissions you want to the new files.
## 750 means the current user can read, write, and execute, the group cannot write, and others cannot read, write, or execute. It is the requirement to transfer files back into a Nextcloud external folder (u+rwx,g+rx,o-rwx).
## 744 is a typical default permission. It allows read, write, and execute permissions for the owner, read permissions for the group, and read permissions for “other” users (u+rwx,g+r,o+r).
CHMOD_PERM="744"

# Define destination directory
DEST_DIR="/home/user/wd12/borg-nc"

# Should the mountpoint be unmounted? (YES/NO)
UNMOUNT="NO"

# Will the CSV file be saved in the same mountpoint as the backup? (YES/NO)
## If YES, it disables the customization fo the following options: LOG_DIR, CSV_LOG_LOCATION
UNMOUNT_CSV="NO"

# Will the logs be saved into an external forlder in nextcloud? (YES/NO)
## if YES CSV and rsync logs will always go to the same folder defined in LOG_DIR
LOG_IN_NC="YES"

# Define directory to store rsync logs
LOG_DIR="/mnt/data/bashs/logs"

# CSV log filename (without extension):
LOG_FILENAME="logfile"

# Do you want the log to be saved in .csv or .txt (don't put the dot)
LOGFILE_FORMAT="txt"

# Choose if you want CSV logs in the same directory as the rsync logs (YES/NO)
RSYNC_CSV_DIR="YES"

# Define directory to store CSV log separate than rsync logs
CSV_LOG_LOCATION="/home/user/wd12/borg-nc/log"

# Do you wish to notify your Nextcloud server about completion? (YES/NO)
## It needs to be a Nextcloud AIO docker container running in the same host. Only admins will be notified.
NOTIFY_NC="YES" 


############################################


########################################
# Please do NOT modify anything below! #
########################################

# Assign the value of LOG_DIR to CSV_LOG_LOCATION if they're going to the same folder or to Nextcloud
if [[ "$RSYNC_CSV_DIR" = "YES" || "$LOG_IN_NC" = "YES" ]]; then
    CSV_LOG_LOCATION="$LOG_DIR"
fi


# Ensure csv and verbose files are same destination as backup in case they are in the same drive
if [[ "$UNMOUNT_CSV" = "YES" ]]; then
		LOG_DIR="$DEST_DIR/rsync_script_log"
		CSV_LOG_LOCATION="$DEST_DIR/rsync_script_log"
fi

# Define CSV log file path
CSV_LOG_FILE="$CSV_LOG_LOCATION/$LOG_FILENAME.$LOGFILE_FORMAT"

# Start with success_status="Success" and failure_reason=""
success_status="Success"
failure_reason=""

# Capture output of commands inside if statements
capture_output=""


############################################
# Functions

# Calculate rsync file name
rsyncfilename() 
{
TIMESTAMP=$(date +"%Y-%m-%d_%H%M%S") # Get current end timestamps for verbose filenames
RSYNC_FILENAME="rsync_log_${SCRIPT_NAME}_${TIMESTAMP}" # Define rsync verbose file name synthax
RSYNC_VERB_FILE="$LOG_DIR/$RSYNC_FILENAME.txt" # Define rsync verbose file path
}

# Create verbose log to file (with timestamp and script name as filename)
rsyncfilewrite() 
{
rsyncfilename
{
		echo -e "$capture_output\n" # Output captured from if statements
		echo -e "Rsync details:\n\n$rsync_output"   # Output captured from rsync command
} > "$RSYNC_VERB_FILE"
} # Ended defining rsyncfilewrite function

# Write CSV file or append to last line
csvfilewrite()
{
rsyncfilename # get filename for the rsync file
TIMESTAMP_CSV_E=$(date +"%Y-%m-%d %H:%M:%S") # Get current timestamp for CSV log file (end)
# Create CSV file with headers if it doesn't exist
if ! [ -e "$CSV_LOG_FILE" ]; then
incremented_char="001"
{
		echo -e "backup_number;backup_name;start_timestamp;end_timestamp;success_status;failure_reason;rsync_log_filename" # Adding headers to the file in case it doesn't exist
} > "$CSV_LOG_FILE" ## Create CSV file with headers
else # Get the number of the last backup
User
# Get the last line of the file
		last_line=$(tail -n 1 "$CSV_LOG_FILE")
# Extract the first character of the last line
    first_char=$(echo "$last_line" | cut -c1-3)
# Check if the first character is a digit
				if [[ "$first_char" =~ [0-9] ]]; then
# Increment the first character
        incremented_char=$((first_char + 1))
				fi
fi #End of else in the case it exists
echo "$incremented_char;$SCRIPT_NAME;$TIMESTAMP_CSV;$TIMESTAMP_CSV_E;$success_status;$failure_reason;$RSYNC_FILENAME" >> "$CSV_LOG_FILE" ## Append data to log CSV file

} # Ended defining csvfilewrite function


# Create log file
fx_error_no_exit() 
{
csvfilewrite # Append log to CSV file
rsyncfilewrite # Save verbose output to log file with timestamp and script name as filename
echo "Rsync process logged to $CSV_LOG_FILE and $RSYNC_VERB_FILE."
}

# Exit after creating log file
fx_error_exit() 
{
fx_error_no_exit
exit 1
}

############################################


###########################################
#Checks & Errors#
###########################################


# Check if it's running as root
if [[ "$RUN_ROOT" = "YES" ]]; then
if [ "$EUID" -ne 0 ]; then 
		failure_reason="Please run as root"
		success_status="Failure"
		capture_output+="\n$failure_reason"
		fx_error_exit
fi
failure_reason="Script being run as root successful"
capture_output+="\n- $failure_reason"
fi


# Create CSV log directory if it doesn't exist
mkdir -p "$CSV_LOG_LOCATION"
# Check if CSV log could be created
if ! [ -d "$CSV_LOG_LOCATION" ]; then
		failure_reason="Could not create CSV log directory"
		success_status="Failure"
		capture_output+="\n$failure_reason"
		fx_error_exit
fi
failure_reason="CSV directory creation/access successful"
capture_output+="\n- $failure_reason"

# Check if the source directory exists
if [[ ! -d "$SOURCE_DIR" ]]; then
		failure_reason="Source directory does not exist."
		success_status="Failure"
		capture_output+="\n$failure_reason"
		fx_error_exit
fi
failure_reason="Source directory existing successful"
capture_output+="\n- $failure_reason"

# Check if source directory if empty
if [ -z "$(ls -A "$SOURCE_DIR/")" ]; then
		failure_reason="The source directory is empty which is not allowed."
		success_status="Failure"
		capture_output+="\n$failure_reason"
		fx_error_exit
fi
failure_reason="Source directory not empty check successful"
capture_output+="\n- $failure_reason"

# Enable mountpoint check
if [ "$MOUNTPOINT_CHECK" = "YES" ]; then

########################################
# Mountpoint Check Start #
########################################
failure_reason="Mountpoint Check Start successful"
capture_output+="\n- $failure_reason"

if ! [ -d "$DRIVE_MOUNTPOINT" ]; then
		failure_reason="The drive mountpoint must be an existing directory"
		success_status="Failure"
		capture_output+="\n$failure_reason"
		fx_error_exit
fi
failure_reason="Mountpoint is an existing directory successful"
capture_output+="\n- $failure_reason"

if ! grep -q "$DRIVE_MOUNTPOINT" /etc/fstab; then
		failure_reason="Could not find the drive mountpoint in the fstab file. Did you add it there?"
		success_status="Failure"
		capture_output+="\n$failure_reason"
		fx_error_exit
fi
failure_reason="Mountpoint is in the fstab file successful"
capture_output+="\n- $failure_reason"

if ! mountpoint -q "$DRIVE_MOUNTPOINT"; then
		mount "$DRIVE_MOUNTPOINT"
		if ! mountpoint -q "$DRIVE_MOUNTPOINT"; then
		failure_reason="Could not mount the drive. Is it connected?"
				success_status="Failure"
				capture_output+="\n$failure_reason"
				fx_error_exit
		fi
fi
failure_reason="Mountpoint is connected successful"
capture_output+="\n- $failure_reason"

########################################
# Mountpoint Check End #
########################################
failure_reason="Mountpoint Check End successful"
capture_output+="\n- $failure_reason"

fi # Disable if statement for variable [ "$MOUNTPOINT_CHECK" = "YES" ]

# Check if the source archives are being used by another process
if [ -f "$SOURCE_DIR/lock.roster" ]; then
		failure_reason="Cannot run the script as the backup archive is currently changed. Please try again later."
		success_status="Failure"
		capture_output+="\n$failure_reason"
		fx_error_exit
fi
failure_reason="No changes in backup archive being made successful"
capture_output+="\n- $failure_reason"

# Create destination directory if it doesn't exist
mkdir -p "$DEST_DIR"
if ! [ -d "$DEST_DIR" ]; then
		failure_reason="Could not create target directory"
		success_status="Failure"
		capture_output+="\n$failure_reason"
		fx_error_exit
fi
failure_reason="Destination directory creation successful"
capture_output+="\n- $failure_reason"

# Check if lock file already exists in source
if [ -f "$SOURCE_DIR/aio-lockfile" ]; then
		failure_reason="Not continuing because aio-lockfile already exists."
		success_status="Failure"
		capture_output+="\n$failure_reason"
		fx_error_exit
fi
failure_reason="No lock file in source directory successful"
capture_output+="\n- $failure_reason"

# Create lock file to start rsync
touch "$SOURCE_DIR/aio-lockfile"
failure_reason="Lock file creation successful"
capture_output+="\n- $failure_reason"

# Define whether to use --chown flag
if [ "$CHOWN_STATUS" = "YES" ]; then
		chown_flag="--chown=$TARGET_USER:$TARGET_GROUP"
else
		chown_flag=""
fi

# Define whether to use --chmod flag
if [ "$CHMOD_STATUS" = "YES" ]; then
		chmod_flag="--chmod=$CHMOD_PERM"
else
		chmod_flag=""
fi

# Perform rsync and capture output
if ! rsync_output=$(rsync --stats -avhd $chown_flag $chmod_flag "$SOURCE_DIR/" "$DEST_DIR/" 2>&1); then
		failure_reason="Failed to sync the backup repository to the target directory."
		success_status="Failure"
		capture_output+="\n$failure_reason"
		fx_error_exit
fi
failure_reason="Rsync successful"
capture_output+="\n- $failure_reason"

# Remove created lock files
rm "$SOURCE_DIR/aio-lockfile"
rm "$DEST_DIR/aio-lockfile"
failure_reason="Removal of lock files successful"
capture_output+="\n- $failure_reason"

# Bypass notification at this stage (YES/NO)
## nextcloud notification after unmount_bypass
NNAU_B="YES"
if [ "$NNAU_B" = "NO" ]; then 
# Notify Nextcloud about completion.
if [ "$NOTIFY_NC" = "YES" ]; then
if docker ps --format "{{.Names}}" | grep "^nextcloud-aio-nextcloud$"; then
docker exec -it nextcloud-aio-nextcloud bash /notify.sh "Rsync backup successful!" "Synced the backup repository successfully."
else
echo "Synced the backup repository successfully."
fi
fi
failure_reason="Nextcloud notified successful"
capture_output+="\n- $failure_reason"
fi

# Define rsync verbose file path
rsyncfilename
failure_reason="Verbose filename update successful"
capture_output+="\n- $failure_reason"


# Unmount if backup drive is in a different mountpoint than the log files
if [ "$UNMOUNT" = "YES" ] && [ "$UNMOUNT_CSV" = "NO" ]; then
		failure_reason="Unmount backup mountpoint successful"
		capture_output+="\n- $failure_reason"
		failure_reason="Backup successful"
		capture_output+="\n- $failure_reason"
		fx_error_no_exit
		umount "$DRIVE_MOUNTPOINT"
		exit 1    
fi

# Update failure_reason to Successful
failure_reason="Backup successful"
capture_output+="\n- $failure_reason"

# Create and/or append data to CSV log file
csvfilewrite
failure_reason="CSV file update successful"
capture_output+="\n- $failure_reason"

# Save verbose output to log file with timestamp and script name as filename 
## no more need to capture_output+
rsyncfilewrite

# Modify permissions of log files if they are being saved to a Nextcloud external folder
if [ "$LOG_IN_NC" = "YES" ]; then
	chown -R 33:0 $LOG_DIR
	chmod -R 750 $LOG_DIR
fi

# Unmount mountpoint if it needs to be disconected 
if [ "$UNMOUNT" = "YES" ]; then
		umount "$DRIVE_MOUNTPOINT"
		echo "$DRIVE_MOUNTPOINT successfully unmounted."
fi

# Bypass notification at this stage (YES/NO)
## nextcloud notification after unmount_bypass
NNAU_BB="NO"
if [ "$NNAU_BB" = "NO" ]; then 
# Notify Nextcloud about completion.
if [ "$NOTIFY_NC" = "YES" ]; then
    if docker ps --format "{{.Names}}" | grep "^nextcloud-aio-nextcloud$"; then
        docker exec -it nextcloud-aio-nextcloud bash /notify.sh "Rsync backup and logging successful!" "Synced the backup repository and created log files successfully."
    else
        echo "Synced the backup repository successfully."
    fi
fi
fi # End "$NNAU_B" = "NO"
failure_reason="Nextcloud notified successful"
capture_output+="\n- $failure_reason"


# Notify user about completion 
echo "Rsync process logged to $CSV_LOG_FILE and $RSYNC_VERB_FILE."
else # if script bypass is on
		echo "Script not set to be run."
fi # End Run Script (script bypass)
