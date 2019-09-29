#!/usr/bin/ksh
########################################################################################
############ Script for Performance monitoring of Batch jobs on DB server ##############
############ Supported platforms - Linux, SunOS & HP-UX                   ##############
########################################################################################CE_SYSTEM



if [ $# -ne 2 ]
then
	echo "OK12"
        echo "Usage: $0 interval_in_secs count "
        echo "$0 30 120"
        exit
fi

################ Calling environ.sh for setting up basic envs       ###################
################ Provide absolute path for environ.sh as per set up ###################

. "/scratch/Perf_engineering/Script/environ.sh"
echo "+++ Message : From DBMsFile ORACLE_HOME"$ORACLE_HOME

echo "+++ Message : SYSTEM_TRACE_VARIABLE:"$TRACE_SYSTEM
echo "+++ Message : TRACE_BY_SESS_VARIABLE:"$TRACE_BY_SESS

if [ ! -d "$LDIR" ]
then
 echo "+++ Message : Creating Directory for storing the logs, LOCATION:"$LDIR
 mkdir -p $LDIR
fi
echo "+++ Message : Instance Setup started..."
INSTANCE=`$ORACLE_HOME/bin/sqlplus $ORAUSRPASS @$DBSCRIPTDIR/instance.sql |grep -v '[A-Za-z]'|grep '[0-9]'|sed 's/\s//g'`
echo "+++ Message : INSTANCE: $INSTANCE"

if [ $TRACE_SYSTEM -eq 1 ]
then
      echo "+++ Message : Setting TRACE_BY_SESS as 0"
      TRACE_BY_SESS=0
      echo "+++ Message : TRACE_BY_SES_VARIABLE:"$TRACE_BY_SES
fi

echo "+++ Message : ORATRACEDIR:"$ORATRACEDIR
rm ${ORATRACEDIR}/*.trc 2>/dev/null
rm ${ORATRACEDIR}/*.trm 2>/dev/null


############################## Trace Individual Sessions #############################
if [ $TRACE_BY_SESS -eq 1 ]
then
	echo "+++ Message : Capturing the SessionInformaiton"
	$ORACLE_HOME/bin/sqlplus $ORAUSRPASS @$DBSCRIPTDIR/getsessions.sql > ${LDIR}/traced_sessions.txt
	pidList=`grep CISUSER ${LDIR}/traced_sessions.txt|grep ${CLNT_HOST_NM}|awk '{print $3}'`
	for u in $pidList; do
		$DBSCRIPTDIR/tstart $u 8
	done

	sleep $TRACE_DUR

	for u in $pidList; do
		$DBSCRIPTDIR/tstop $u
		mv $ORATRACEDIR/${ORACLE_SID}_ora_${u}.trc $LDIR/
	done

	cat $LDIR/*.trc > $LDIR/cumulativeOraTrace.trc
	$ORACLE_HOME/bin/tkprof $LDIR/cumulativeOraTrace.trc $LDIR/cumulativeOraTrace-CNT.tkp sys=no SORT=EXECNT
	
	rm $LDIR/cumulativeOraTrace.trc
fi 

################# Enabling Oracle Trace system wide  ################################
if [ $TRACE_SYSTEM -eq 1 ]
then
	echo "+++ Message : Enabling Level 8 Tracing System wide"
	$ORACLE_HOME/bin/sqlplus $ORAUSRPASS @$DBSCRIPTDIR/enableSystemTrace.sql
fi


################ Collect cpu, io,  mem and kernel parameters  #######################
sysType=`uname -a |awk '{print $1}'`

case "$sysType" in

SunOS)
vmstat $INT $CNT > $LDIR/vmstat-$MYDT.log &
prstat $INT $CNT > $LDIR/prstat-$MYDT.log &
iostat -xn $INT $CNT > $LDIR/iostat-disk-$MYDT.log &
/usr/sbin/sysdef -i > $LDIR/kernelParams.log
;;

HP-UX)
vmstat $INT $CNT > $LDIR/vmstat-$MYDT.log &
iostat $INT $CNT > $LDIR/iostat-$MYDT.log &
top -s${INT} -d${CNT} -f top-$MYDT.log &
/usr/sbin/sysdef  >  $LDIR/kernelParams.log
;;


Linux)
#nmon -f -t -s$INT -c$CNT > $LDIR/ &
iostat -d $INT $CNT > $LDIR/iostat-disk-$MYDT.log &
top -b -d $INT -n $CNT > $LDIR/top-$MYDT.log &
echo "Date, PID, size, resident,shared, text, lib, data, dirty -- In pages, pg size 4096 bytes" >> $LDIR/cobjrunMemStat_$MYDT.log
/sbin/sysctl -a > $LDIR/kernelParams.log

# Commenting the below part as running the script only for Database part
#${APPSCRIPTDIR}/monSocketFD-Linux.ksh $NWINT $CNT &
vmstat $INT $CNT > $LDIR/vmstat-$MYDT.log &
${DBSCRIPTDIR}/nmon -f -s${INT} -c $CNT &
sar -P ALL $INT $CNT > $LDIR/sar-$MYDT.log &

;;

esac


################################## Take awr  snapshot ###################################
if [ $INSTANCE -eq 1 ]
then
 echo "+++ Message : Capturing the snapshot for the INSTANCE:$INSTANCE"
 $ORACLE_HOME/bin/sqlplus $ORAUSRPASS @$DBSCRIPTDIR/snap.sql
fi
startsnapid=`$ORACLE_HOME/bin/sqlplus $ORAUSRPASS @$DBSCRIPTDIR/maxsnapid.sql | grep -v '[A-Za-z]'|grep '[0-9]'|sed 's/\s//g'`
echo "$startsnapid" > $LDIR/snapId.txt

###########################   For ASH Report ###########################################
if [ -f "${LDIR}/ashtime.out" ]
then
 echo "!!! Waring  : ASH file is present, removing it"
 rm ${LDIR}/ashtime.out
 echo "+++ Message : Removed the file now creating with the time stamp"
 echo `date +"%m/%d/%y %H:%M:%s"` >> ${LDIR}/ashtime.out
else
 echo "+++ Message : ASH File is not present "
 echo `date +"%m/%d/%y %H:%M:%S"` >> $LDIR/ashtime.out
 echo "+++ Message : Created ASHTIME file"
fi


############################  Taknig DB Storage Stats ###################################
echo ""
echo "+++ Message : Gathering Database Storage statistics"
$ORACLE_HOME/bin/sqlplus $ORAUSRPASS @$DBSCRIPTDIR/gather_storage_stats.sql > $LDIR/DB_Storage_Stats-$MYDT.txt


DUR=`expr $INT \* $CNT`

while [ $DUR -ge 0 ]
do

############# Disabling Oracle System Trace & Take Tkprof ################################
if [ $TRACE_SYSTEM -eq 1 ]
then
	if [ $TRACE_DUR -le 0 ]
	then
		echo "Disabling Level 8 Tracing System wide"
		$ORACLE_HOME/bin/sqlplus $ORAUSRPASS @$DBSCRIPTDIR/disableSystemTrace.sql
		mv $ORATRACEDIR/*ora*.trc $LDIR
       		cat $LDIR/*.trc > $LDIR/cumulativeOraTrace.trc
	    	$ORACLE_HOME/bin/tkprof $LDIR/cumulativeOraTrace.trc $LDIR/cumulativeOraTrace-CNT.tkp sys=no SORT=EXECNT
		$ORACLE_HOME/bin/tkprof $LDIR/cumulativeOraTrace.trc $LDIR/cumulativeOraTrace-CPU.tkp sys=no SORT=EXECPU
	        rm $LDIR/cumulativeOraTrace.trc
		rm $LDIR/*.trc
	fi
fi

        DT=`date +%b-%d-%H-%M-%S`
        if test "$sysType" = "Linux" 
        then
		u=`ps -efly|grep LOCAL=NO|grep -v grep|awk '{print $3}'`;for i in $u; do echo $DT $i `cat /proc/$i/statm` >> $LDIR/nonLocalConnectionMemStat_$MYDT.log; done;
        fi
        echo $DT >> $LDIR/sessions_$MYDT.log
	$ORACLE_HOME/bin/sqlplus $ORAUSRPASS @$DBSCRIPTDIR/getsessions >> $LDIR/sessions_$MYDT.log
	echo $DT >> $LDIR/exec_$MYDT.log
	$ORACLE_HOME/bin/sqlplus $ORAUSRPASS @$DBSCRIPTDIR/getuserexec >> $LDIR/exec_$MYDT.log
        DUR=`expr $DUR - $SESS_INT`
	TRACE_DUR=`expr $TRACE_DUR - $SESS_INT`
        netstat -i -w >> $LDIR/netstat_Packets-$MYDT.log
        echo $DT >>  $LDIR/netstat_Packets-$MYDT.log
	/sbin/ifconfig -a >> $LDIR/ifconfig_Packets-$MYDT.log
	echo $DT >>  $LDIR/ifconfig_Packets-$MYDT.log
        sleep $SESS_INT
	echo "${DT} \t Remaining Seconds for completion:${DUR}, Ora Trace Completion:$TRACE_DUR" >> $LDIR/scriptStatus.log
done

if [ $INSTANCE -eq 1 ]
then
 $ORACLE_HOME/bin/sqlplus $ORAUSRPASS @$DBSCRIPTDIR/snap.sql
fi
endsnapid=`$ORACLE_HOME/bin/sqlplus $ORAUSRPASS @$DBSCRIPTDIR/maxsnapid.sql|grep -v '[A-Za-z]'|grep '[0-9]'|sed 's/\s//g'`
CDIR=`pwd`
${DBSCRIPTDIR}/rptawrloop.ksh $startsnapid $endsnapid
#Adding the part to move the script to the Logs directory
for files in `ls $CDIR/awrrpt*.txt`
do
 if [ -f "$files" ];
 then
   echo "+++ Message : AWWR Report files are present at Location:"$CDIR
   echo "+++ Message : Moving the AWR report files to Location:"$LDIR
   mv $files $LDIR/
   echo "+++ Message : Files are moved"
 else
   echo "+++ Warning : No AWR Report files are present at the Location:"$CDIR
 fi
done
${DBSCRIPTDIR}/rptaddmloop.ksh $startsnapid $endsnapid
for files2 in `ls $CDIR/addmrpt*.txt`
do
 if [ -f "$files2" ];
 then
   echo "+++ Message : ADDM Report files are present at Location:"$CDIR
   echo "+++ Message : Moving the ADDM report files to Location:"$LDIR
   mv $files2 $LDIR/
   echo "+++ Message : Files are moved"
 else
   echo "+++ Warning : No ADDM Report files are present at the Location:"$CDIR
 fi
done

echo "End snap id is:$endsnapid start id is: $startsnapid" >> $LDIR/snapIDs.txt
${DBSCRIPTDIR}/awrParser.ksh

##################### for ASH repot #################
startsnaptime=`cat $LDIR/ashtime.out`
endsnaptime=`date +"%m/%d/%y %H:%M:%S"`
echo "$endsnaptime" >> $LDIR/ashtime.out
${DBSCRIPTDIR}/rptashloop.ksh "$startsnaptime" "$endsnaptime"
for files3 in `ls $CDIR/ashrpt*.txt`
do
 if [ -f "$files3" ];
 then
   echo "+++ Message : ASH Report files are present at Location:"$CDIR
   echo "+++ Message : Moving the ASH report files to Location:"$LDIR
   mv $files3 $LDIR/
   echo "+++ Message : Files are moved"
 else
   echo "+++ Warning : No ASH Report files are present at the Location:"$CDIR
 fi
done

echo "+++ Message : Working Directory for Logs writing:"$LDIR

case "$sysType" in
Linux)
cat $LDIR/vmstat-*.log|grep '[0-9]'|awk '{print $15, $16}'|awk -f $DBSCRIPTDIR/calcAvg.awk > $LDIR/vmstat-Avg.log 2>/dev/null

;;

HP-UX)
cat $LDIR/vmstat-*.log|egrep -v 'memory|free'|awk '{print $18,0}'|awk -f $DBSCRIPTDIR/calcAvg.awk > $LDIR/vmstat-Avg.log 2>/dev/null
;;

SunOS)
cat $LDIR/vmstat-*.log|egrep -v 'memory|swap'|awk '{print $22,0}'|awk -f $DBSCRIPTDIR/calcAvg.awk > $LDIR/vmstat-Avg.log 2>/dev/null
;;

esac

chmod -R 777 $LDIR/
gzip $LDIR/*.trc

echo ""
echo "DONE !!!"

