#!/bin/bash

LOG=$1
ITRE=$2
DIR=$(dirname $0)/myscript

####### SystemInfo #######
echo 
echo "SystemInfo Start"
$DIR/systeminfo_current.pl $LOG 
echo "SystemInfo Finish"
sleep 3

####### Stats #######
echo 
echo "Stats Start"
$DIR/all_current.pl $LOG $ITRE
echo "Stats Finish"
sleep 3

####### Latency #######
echo
echo "Latency Start"
$DIR/latency_parse_beta.pl $LOG $ITRE
echo "Latency Finish"
sleep 3

####### Throughput #######
echo
echo "Throughput Start"
$DIR/throughput_parse_beta.pl $LOG $ITRE
echo "Throughput Finish"
sleep 3

####### Disk List #######
echo
echo "Disk List Start"
$DIR/disk_parse_beta.pl $LOG $ITRE
echo "Disk List Finish"
sleep 3

####### Workload #######
echo
for i in nfsv3 cifs fcp iscsi
do
	echo -n "Workload $i Start ..." | tee -a ./workload.log
	$DIR/workload_parse_my_current.pl $LOG $i $ITRE >> ./workload.log
	echo " Finish" | tee -a ./workload.log
done
sleep 3

####### CIFS List #######
echo
echo "CIFS Stat Start"
$DIR/cifs_stat_beta.pl $LOG $ITRE
echo "CIFS Stat Finish"
sleep 3

####### LU List #######
echo
echo "LU List Start"
$DIR/lun_parse_beta.pl $LOG $ITRE
echo "LU List Finish"

####### Full Workload #######
echo
echo "Full Workload Start"
$DIR/full_workload.sh $LOG $ITRE
echo "Full Workload Finish"

exit 0 
