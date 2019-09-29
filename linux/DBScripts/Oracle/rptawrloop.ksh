#!/bin/ksh

#. "/scratch/Perf_engineering/Script/environ.sh"


if [ $# -ne 2 ]
then
        echo "Usage: $0 tart_snap_id end_snap_id"
        echo "$0 30 120"
        exit
fi


startId=$1;
endId=$2;

$ORACLE_HOME/bin/sqlplus $ORAUSRPASS @${ORACLE_HOME}/rdbms/admin/awrrpt.sql <<EOF1
text
2
$startId
$endId

quit
EOF1

let stopId=$startId+1


while [ $stopId -le $endId ]; do

$ORACLE_HOME/bin/sqlplus $ORAUSRPASS @${ORACLE_HOME}/rdbms/admin/awrrpt.sql <<EOF
text
2
$startId
$stopId

quit
EOF

let startId=$startId+1
let stopId=$startId+1

done

