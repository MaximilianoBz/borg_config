#!/bin/sh
# Script para backups programados de borg
# Version modificada de borg-cron-helper https://github.com/rugk/borg-cron-helper

# enable zsh compatibility: in ZSH word splitting is disabled by default,
# but we need it
setopt shwordsplit 2>/dev/null

BORG_BIN="borg"
LAST_BACKUP_DIR="/var/log/borg/last"
LOG_FILE="/var/log/borg/borgbackup.log"
RUN_PID_DIR="/var/run/borg"

#Variables
# basic, required information
BACKUP_NAME='FULL' # name for this backup, avoid spaces
export BORG_RSH='ssh -oBatchMode=yes'
export BORG_REPO='ssh://borg@borg.lunix.com.ar:22/u/borgbackup/repo4-test'
export BORG_PASSPHRASE='eP&2yAdFg55o^jw8LWK9EnUc'
ARCHIVE_NAME="{hostname}-$BACKUP_NAME-{now:%Y-%m-%dT%H:%M}" # or %Y-%m-%d

#Directorios del backup
BACKUP_DIRS="/etc /var/spool/cron /usr/local" #DEFAULT LINUX

# default settings for backup
COMPRESSION="lz4"
ADD_BACKUP_PARAMS="--exclude-caches --exclude '/home/*/.cache/*' --exclude '/var/cache/*' --exclude '/var/tmp/*'"
SLEEP_TIME="5m"
RETRY_NUM="3"

# The prefix makes sure only backups from this backup config are pruned. It is
# recommend to leave it as it is. Otherwise comment it out to disable pruning
# or – if you really want to remove the prefix – set it to an empty string.
PRUNE_PREFIX="{hostname}-$BACKUP_NAME-"
PRUNE_PARAMS="--keep-daily=31 --keep-weekly=8 --keep-monthly=2 --keep-yearly=0"

# Tiempo max entre backups antes que envie alerta
CRITICAL_TIME=$(( 48*60*60 )) # 48h

# set placeholder/default value
#PRUNE_PREFIX="null"
exitcode=0
exitcode_create=0

# Keep track oh highest exit code.
#
# args:
# $1 – number of new exit code
track_exitcode() {
	if [ "$1" -gt "$exitcode" ]; then
		exitcode="$1"
	fi
}

# Evaluate exit code of a borg run.
#
# args: none
# may exit
evaluateExitCodes() {
	# see https://borgbackup.readthedocs.io/en/stable/usage.html?highlight=return%20code#return-codes
	case $1 in
		2 )
			error_log "Borg exited with fatal error." #(2)
			echo "0" > /etc/lunix/borg_status

			# ignore last try
			if [ "$i" -lt "$RETRY_NUM" ]; then
				# wait some time to recover from the error
				info_log "Wait $SLEEP_TIME…"
				sleep "$SLEEP_TIME"

				# break-lock if backup has not locked by another process in the meantime
				if is_lock; then
					error_log "Backup \"$BACKUP_NAME\" is locked locally by other process. Cancel."
					exit 1
				fi

				if [ "$RUN_PID_DIR" != "" ]; then
					info_log "Breaking lock…"
					$BORG_BIN break-lock "$REPOSITORY"
				fi
			fi
			;;
		1 )
			error_log "Borg had some WARNINGS, but everything else was okay."
			echo "1" > /etc/lunix/borg_status
			;;
		0 )
			info_log "Borg has been successful."
			echo "1" > /etc/lunix/borg_status
			;;
		* )
			error_log "Unknown error with code $1 happened."
			echo "0" > /etc/lunix/borg_status
			;;
	esac
}

# log system
log_line() {
	echo "[$( date +'%F %T' )]"
}
info_log() {
	echo "$( log_line ) $*" >> $LOG_FILE
	echo "$( log_line ) $*" >&1
}
empty_line_log() {
	echo >> $LOG_FILE
	echo >&1
}
error_log() {
	echo "$( log_line ) ERROR: $*" >> $LOG_FILE
	echo "$( log_line ) ERROR: $*" >&2
}

# Evaluate whether the backup is locked.
#
# args: none
# returns: bool
is_lock() {
	# check if locking system is disabled
	if [ "$RUN_PID_DIR" = "" ]; then
		return 1 # not locked
	fi

	# when file is not present -> unlocked
	if [ ! -f "$RUN_PID_DIR/BORG_$BACKUP_NAME.pid" ]; then
		return 1 # false
	fi
	# when PID listed in file is not running -> unlocked
	if ! pgrep -F "$RUN_PID_DIR/BORG_$BACKUP_NAME.pid" > /dev/null; then
		return 1 # false
	fi

	return 0 # true, locked
}

# Locks the current backup.
#
# args: none
do_lock() {
	# check if locking system is disabled
	if [ "$RUN_PID_DIR" = "" ]; then
		return
	fi

	if [ ! -d "$RUN_PID_DIR" ]; then
		mkdir -p "$RUN_PID_DIR" || exit 2
	fi

	# write PID into file
	echo $$ > "$RUN_PID_DIR/BORG_$BACKUP_NAME.pid" || exit 2

	if ! is_lock; then
		error_log "Locking was not successful. Cancel."
		exit 2
	fi
}

# Removes the lock of the current backup.
#
# args: none
rm_lock() {
	# check if locking system is disabled
	if [ "$RUN_PID_DIR" = "" ]; then
		return
	fi

	rm "$RUN_PID_DIR/BORG_$BACKUP_NAME.pid"
}

# Checks in a loop whether we need to stop the loop or not and log messages.
#
# args:
# $1 – The number of the executed try.
# may exit
backupIterationLockCheck() {
	# if locked, stop backup
	if is_lock; then
		error_log "Backup $BACKUP_NAME is locked. Cancel."
		exit 1
	fi

	# otherwise log try (if useful)
	if [ "$1" -gt 1 ]; then
		info_log "$1. try…"
	fi
}

# Prettifies the time display so it looks good for user.
#
# Adopted from https://unix.stackexchange.com/questions/27013/displaying-seconds-as-days-hours-mins-seconds/170299#170299
# Edited.
#
# args:
# $1 – Time in seconds.
# returns: string
prettifyTimeDisplay()
{
    t=$1

    d=$((t/60/60/24))
    h=$((t/60/60%24))
    m=$((t/60%60))
    s=$((t%60))

	# only show seconds if < 1 minute
    if [ $d = 0 ] && [ $h = 0 ] && [ $m = 0 ]; then
    	[ $s = 1 ] && printf "%d second" $s || printf "%d seconds" $s

		# can skip other if clauses
		return
    fi

	# round up minutes if needed
	if [ $s -ge 30 ]; then
		m=$(( m+1 ))
	fi

    if [ $d -gt 0 ]; then
        [ $d = 1 ] && printf "%d day " $d || printf "%d days " $d
    fi
    if [ $h -gt 0 ]; then
        [ $h = 1 ] && printf "%d hour " $h || printf "%d hours " $h
    fi
    if [ $m -gt 0 ]; then
        [ $m = 1 ] && printf "%d minute " $m || printf "%d minutes " $m
    fi
}
# Return backup info from borg.
#
# The output is returned in several variables.
#
# args:
# $1 – Archive name
getBackupInfo() {
	# get output of borg info
	borginfo=$( $BORG_BIN info "::$1" )

	# get start/end time from output
	timeStart=$( echo "$borginfo"|grep 'Time (start):'|sed -E 's/Time \(start\): (.*)/\1/g' )
	timeEnd=$( echo "$borginfo"|grep 'Time (end):'|sed -E 's/Time \(end\): (.*)/\1/g' )

	timeStartSec=$( date --date="$timeStart" +"%s" )
	timeEndSec=$( date --date="$timeEnd" +"%s" )

	# calculate the difference, i.e. the duration of backup
	durationSec=$(( timeEndSec-timeStartSec ))
	duration=$( prettifyTimeDisplay "$durationSec" | xargs ) # trim sourounding spaces

	# extract the "deduplicated/compressed" value for each size
	size=$( echo "$borginfo"|grep 'This archive:'|sed -E 's/\s{2,}/|/g'|cut -d '|' -f 4 )
	sizeTotal=$( echo "$borginfo"|grep 'All archives:'|sed -E 's/\s{2,}/|/g'|cut -d '|' -f 4 )
}
# Return backup info from the last backup..
#
# The output is returned in several variables. (see getBackupInfo())
#
# args: None
getInfoAboutLastBackup() {
	# get last archive name of new backup
	lastArchive=$( $BORG_BIN list --short ::|tail -n 1 )
	# and get info about it
	getBackupInfo "$lastArchive"
}

# add trap to catch backup interruptions
trapterm() {
	rm_lock 2> /dev/null
	echo "0" > /etc/lunix/borg_status
	error_log "Backup $BACKUP_NAME (PID: $$) interrupted by $1."
	exit 2
}
trap 'trapterm INT' INT
trap 'trapterm TERM' TERM

# Agregamos bandera para zabbix
echo "0" > /etc/lunix/borg_status

# Crear directorio si no existe
if [ ! -d $LAST_BACKUP_DIR ]; then
	mkdir -p $LAST_BACKUP_DIR
fi

# check lock
if is_lock; then
	error_log "Backup $BACKUP_NAME is locked. Prevent start."
	exit 1
fi

# check that variables are set
if [ "$BACKUP_NAME" = "" ] ||
   [ "$BORG_REPO" = "" ] ||
   [ "$ARCHIVE_NAME" = "" ] ||
   [ "$BACKUP_DIRS" = "" ]; then
	error_log 'Some required variables may not be set in the config file. Cancel backup.'
	exit 2
fi
if ! export|grep -q "BORG_REPO"; then
	error_log 'The BORG_REPO variable is not exported in the config file. Cancel backup.'
	exit 2
fi


# log
empty_line_log
info_log "Backup $BACKUP_NAME started with $( $BORG_BIN -V ), helper PID: $$."

for i in $( seq "$(( RETRY_NUM+1 ))" ); do
	backupIterationLockCheck "$i"

	# add local lock
	do_lock

	# backup dir (some variables intentionally not quoted)
	# shellcheck disable=SC2086
	$BORG_BIN create -v --stats \
		--compression "$COMPRESSION" \
		$ADD_BACKUP_PARAMS \
		"::$ARCHIVE_NAME" \
		$BACKUP_DIRS 2>> $LOG_FILE

	# check return code
	exitcode_create=$?

	# remove local lock
	rm_lock

	# show output
	evaluateExitCodes "$exitcode_create" "create"

	# exit loop on non-critical errors (ignore 1 = warnings)
	if [ $exitcode_create -le 1 ]; then
		# save/update last backup time
		if [ -d $LAST_BACKUP_DIR ]; then
			date +'%s' > "$LAST_BACKUP_DIR/$BACKUP_NAME.time"
		fi
		# get out of loop
		break;
	fi
done

# only track latest exit code of execution, i.e. when backups fail but can be
# recovered through retrying, the last code is still 0
track_exitcode $exitcode_create

# The (optional) prefix makes sure only backups from this machine with this
# backup-type are touched.
# ($PRUNE_PARAMS intentionally not quoted)

if [ "$PRUNE_PARAMS" ] && [ "$PRUNE_PREFIX" != "null" ] && [ "$exitcode" -lt 2 ]; then
	info_log "Running prune for \"$BACKUP_NAME\"…"

	# if RETRY_NUM_PRUNE is not set, fall back to RETRY_NUM
	[ "$RETRY_NUM_PRUNE" = "" ] && RETRY_NUM_PRUNE=$RETRY_NUM

	for i in $( seq "$(( RETRY_NUM_PRUNE+1 ))" ); do
		backupIterationLockCheck "$i"

		# add local lock
		do_lock

		# run prune
		# shellcheck disable=SC2086
		$BORG_BIN prune -v --stats --list --prefix "$PRUNE_PREFIX" $PRUNE_PARAMS 2>> $LOG_FILE

		# check return code
		exitcode_prune=$?

		# remove local lock
		rm_lock

		# show output
		evaluateExitCodes "$exitcode_prune" "prune"

		# exit loop on non-critical errors (ignore 1 = warnings)
		if [ $exitcode_prune -le 1 ]; then
			# get out of loop
			break;
		fi
	done

	track_exitcode "$exitcode_prune"
fi

# log
if [ "$exitcode" -ne 0 ]; then
	error_log "Backup \"$BACKUP_NAME\" ended, but it seems something went wrong."
else
	info_log "Backup \"$BACKUP_NAME\" ended successfully."
fi

#Check last backup
dir_contains_files() {
	ls -A "$1"
}

# check for borg backup notes
if [ -d "$LAST_BACKUP_DIR" ] && [ "$( dir_contains_files $LAST_BACKUP_DIR )" ]; then
	for file in "$LAST_BACKUP_DIR"/*; do
		name=$( basename "$file" .time )
		time=$( cat "$file" )
		relvtime=$(( $(date +%s) - time ))

		if [ "$relvtime" -ge "$CRITICAL_TIME" ]; then
            mail -s "Backup desactualizado en {hostname}" ingenieria@lunix.com.ar < echo "WARNING: The borg backup named \"$name\" is outdated. Last successful execution: $( date --date=@"$time" +'%A, %F %T' )"
            error_log "WARNING: The borg backup named \"$name\" is outdated."
			error_log "         Last successful execution: $( date --date=@"$time" +'%A, %F %T' )"
		fi
	done
else
	error_log "ERROR: No borg backup 'last' dir…"
	echo "0" > /etc/lunix/borg_status
fi

exit "$exitcode"
