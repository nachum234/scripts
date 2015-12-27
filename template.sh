#!/bin/bash
#
################################################################
#
# Global Variables
#
################################################################
SCRIPT_NAME=`basename $0`
################################################################
#
# Functions
#
################################################################
function write_log
{
	logger -p local1.info -t ${SCRIPT_NAME} "$*"
}
################################################################
function check_if_already_run
{
	PID=$$
        TMP=`pgrep -f ${SCRIPT_NAME}`
        if [ "${TMP}" != "${PID}" ] 
		then
		write_log "${SCRIPT_NAME} is already running"
                exit 0;
        fi
}
################################################################
function err_handle
{
	ERR=$1
	COMMAND=$2
	if [ ${ERR} = 0 ]
	then
		write_log "command ${COMMAND} completed successfully"
	else
		write_log "Error: command ${COMMAND} failed with error code=${ERR}"
		exit 2
	fi
}
################################################################
#
# Main
#
################################################################

