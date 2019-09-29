#!/bin/ksh

#. "/scratch/Perf_engineering/Script/environ.sh"


if [ $# -ne 2 ]
then
        echo "Usage: $0 tart_snap_time end_snap_time"
        echo "$0 30 120"
        exit
fi


startId=$1;
endId=$2;

$ORACLE_HOME/bin/sqlplus $ORAUSRPASS @${ORACLE_HOME}/rdbms/admin/ashrpt.sql <<EOF1
text
$startId
$endId

quit
EOF1
