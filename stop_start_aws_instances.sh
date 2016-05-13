#!/bin/bash
#
# DESCRIPTION:
#   This script is a wrapper to aws cli and help to stop and start aws instances automatically
#
# OUTPUT:
#   plain text
#
# PLATFORMS:
#   Linux
#
# DEPENDENCIES:
#   Install and configure aws cli: http://docs.aws.amazon.com/cli/latest/userguide/installing.html
#
# NOTES:
#
# LICENSE:
#   Copyright 2016 Yossi Nachum. 
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
function usage
{
	echo "${SCRIPT_NAME} -p aws_profile -f ec2_instance_filter -a ec2_action -r aws_region"
	echo "  aws_profile - The profile you configure for aws tools. can be default. To list configured profiles: cat ~/.aws/config"
	echo "  ec2_action - Can be any from 'aws ec2 help' but design only for stop-instances and start-instances."
	echo "  ec2_instance_filter - Filter ec2 instances that the action will run on."
	echo "  aws_region - AWS region that run your ec2 instances. To list aws regions: aws ec2 describe-regions"
	echo ""
	echo ""
	echo "Example:"
	echo "  To stop all instances that contain the tag 'daily-stop' with value 'true' in us-east-1 region:"
	echo "  ${SCRIPT_NAME} -p default -a stop-instances -f 'Name=tag:daily-stop,Values=true' -r us-east-1"
	echo ""
	echo "  Crontab example to stop ec2 instances that contain the tag 'daily-stop' with value 'true' in us-east-1 region every day at 19:00"
	echo "  0 19 * * * ${SCRIPT_NAME} -p default -a stop-instances -f 'Name=tag:daily-stop,Values=true' -r us-east-1"
	exit 2
}
################################################################
#
# Main
#
################################################################
while getopts ":p:f:a:r:" OPT
do
	case ${OPT} in
		p)
			PROFILE=${OPTARG}
			;;
		f)
			FILTERS=${OPTARG}
			;;
		a)
			ACTION=${OPTARG}
			;;
		r)
			REGION=${OPTARG}
			;;
	esac
done

if [ "x${PROFILE}" = "x" ] || [ "x${FILTERS}" = "x" ] || [ "x${ACTION}" = "x" ] || [ "x${REGION}" = "x" ]
then
	usage
fi
INSTANCE_IDS=$(aws --profile ${PROFILE} --region ${REGION} ec2 describe-instances --filters ${FILTERS} --output text --query 'Reservations[*].Instances[*].{MachineID:InstanceId}')
if [ "x${INSTANCE_IDS}" = "x" ]
then
	echo "0 instances selected, please check your filter"
	exit 2
fi
echo "Apply action (${ACTION}) on the following instances: $(echo ${INSTANCE_IDS} | tr '\n' ' ')"
aws --profile ${PROFILE} --region ${REGION} ec2 ${ACTION} --instance-ids ${INSTANCE_IDS} > /dev/null