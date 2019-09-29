#!/bin/ksh

###################################################################################################
############ Script for gracefully stoping script, DBmeasLinux-Batch.ksh  #########################
############ Supported platforms - Linux, SunOS & HP-UX                   #########################
###################################################################################################


##################### Calling environ.sh for setting up basic envs          #######################
##################### Provide absolute path for environ.sh as per set up     ######################

#. "${ORACLE_HOME}/scripts/environ.sh" 2>/dev/null
. "/scratch/Perf_engineering/Script/environ.sh" 2>/dev/null

INSTANCE=`$ORACLE_HOME/bin/sqlplus $ORAUSRPASS @$DBSCRIPTDIR/instance.sql |grep -v '[A-Za-z]'|grep '[0-9]'|sed 's/\s//g'`


sysType=`uname -a|awk '{print $1}'` 
case "$sysType" in
Linux)
ps -ef|grep -e vmstat -e 'DBmeasLinux-Batch' -e 'monSocketFD-Linux.ksh' -e iostat -e netstat -e nmon -e sar -e  'top -b -s'|grep -v grep|awk '{print $2}'|xargs kill -9
;;

HP-UX)
ps -ef|grep -e 'vmstat' -e 'DBmeasLinux-Batch' -e 'iostat' -e 'top -s'|grep -v grep|awk '{print $2}'|xargs kill -9
;;

SunOS)
ps -ef|egrep 'vmstat|DBmeasLinux-Batch|monSocketFD-Linux.ksh|iostat|prstat'|grep -v grep|awk '{print $2}'|xargs kill -9
;;

esac


######################### Disabling Oracle Trace & Take Tkprof ##################################
if [ $TRACE_ENABLED -eq 1 ] 2>/dev/null
then
if [ -f $LDIR/traced_sessions.txt ]
then
        echo "Disabling Level 8 Session Tracing"
	pidList=`grep CISUSER ${LDIR}/traced_sessions.txt|grep ${CLNT_HOST_NM}|awk '{print $3}'`
	for u in $pidList; do
		$DBSCRIPTDIR/tstop $u
	done
else	 
	echo "Disabling Level 8 Tracing System wide"
	$ORACLE_HOME/bin/sqlplus $ORAUSRPASS @$DBSCRIPTDIR/disableSystemTrace.sql
fi

if [ -f $LDIR/cumulativeOraTrace.tkp ]
then
	echo "Trace & Tkprof already completed..."
else
	mv $ORATRACEDIR/*ora*.trc $LDIR/
	cat $LDIR/*.trc > $LDIR/cumulativeOraTrace.trc
	$ORACLE_HOME/bin/tkprof $LDIR/cumulativeOraTrace.trc $LDIR/cumulativeOraTrace-CNT.tkp sys=no SORT=EXECNT
	$ORACLE_HOME/bin/tkprof $LDIR/cumulativeOraTrace.trc $LDIR/cumulativeOraTrace-CPU.tkp sys=no SORT=EXECPU
	rm $LDIR/cumulativeOraTrace.trc	
	rm $LDIR/*.trc
fi
fi
##############################################################################################

gzip $LDIR/*.trc 2>/dev/null


case "$sysType" in
Linux)
cat $LDIR/vmstat-*.log|grep '[0-9]'|awk '{print $15, $16}'|awk -f $DBSCRIPTDIR/calcAvg.awk > $LDIR/vmstat-Avg.log 2>/dev/null
perl $DBSCRIPTDIR/gatherLogStats.perl $LDIR/nonLocalConnectionMemStat_*.log > $LDIR/parsed-nonLocalConnectionMemStat.txt
;;

HP-UX)
cat $LDIR/vmstat-*.log|egrep -v 'memory|free'|awk '{print $18,0}'|awk -f $DBSCRIPTDIR/calcAvg.awk > $LDIR/vmstat-Avg.log 2>/dev/null
;;

SunOS)
cat $LDIR/vmstat-*.log|egrep -v 'memory|swap'|awk '{print $22,0}'|awk -f $DBSCRIPTDIR/calcAvg.awk > $LDIR/vmstat-Avg.log 2>/dev/null
;;

esac

chmod -R 777 $PWD/

echo ""


######################################  ASH Timestamp #####################################
startsnaptime=`cat ashtime.out`
endsanptime=`date +"%m/%d/%y %H:%M:%S`
echo "$endsanptime" >> $LDIR/ashtime.out


####################################### Take snapshot ######################################
startsnapid=`cat snapId.txt`
if [ $INSTANCE -eq 1 ]
then
	$ORACLE_HOME/bin/sqlplus ${ORAUSRPASS} @$DBSCRIPTDIR/snap.sql
fi
endsnapid=`$ORACLE_HOME/bin/sqlplus ${ORAUSRPASS} @$DBSCRIPTDIR/maxsnapid.sql|grep -v '[A-Za-z]'|grep '[0-9]'|sed 's/\s//g'`
echo "$endsnapid" >> $LDIR/snapId.txt
ksh ${DBSCRIPTDIR}/rptawrloop.ksh $startsnapid $endsnapid
ksh ${DBSCRIPTDIR}/rptaddmloop.ksh $startsnapid $endsnapid
ksh ${DBSCRIPTDIR}/awrParser.ksh

ksh ${DBSCRIPTDIR}/rptashloop.ksh "$startsnaptime" "$endsanptime"

echo ""
echo "DONE !!!"
echo ""
