#!/bin/bash

LOG=$1
ITRE=$2
DIR=$(dirname $0)/myscript

####### Full Workload #######
echo
echo "Full Workload Start"
$DIR/full_workload.sh $LOG $ITRE
echo "Full Workload Finish"

exit 0 
