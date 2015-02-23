#!/bin/bash
# $1 = Source Perfstat Log file

DIR=$(dirname $0)/myscript
LOG=./full_workload.log
SRC=$1
ITR=$2

IS=`echo $ITR | awk -F- '{print $1}'`
IE=`echo $ITR | awk -F- '{print $2}'`

echo $IS
echo $IE
echo "Type,RR,RW,SR,SW,RRp,RWp,SRp,SWp,Iteration" | tee -a $LOG

for i in `seq $IS $IE`
do
	#echo "Itertation $i" | tee -a $LOG
	for x in nfsv3 fcp iscsi cifs
	do
		#echo "Workload $x Start" | tee -a $LOG
		echo -n "$x," | tee -a $LOG
		$DIR/run_workload.pl $SRC $x $i-$i >> $LOG
		printf "Iteration-%03d\n" $i | tee -a $LOG
	done

done

exit 0
