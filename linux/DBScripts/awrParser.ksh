#!/bin/ksh
sysType=`uname -a |awk '{print $1}'`
. "/scratch/Perf_engineering/Script/environ.sh"
echo "+++ Message : Location to strore parsed-awr report:"$LDIR
for awrFile in `ls $LDIR/awr*.txt`
do
case "$sysType" in
Linux)
cat ${awrFile}|grep -e 'user calls' -e 'physical read total IO requests' -e 'physical write total IO requests' -e 'physical read total bytes' -e  'physical write total bytes' -e 'bytes received via SQL' -e 'bytes sent via SQL\*Net to client' -e 'SQL\*Net roundtrips' >${awrFile}_parsed
;;
SunOS)
cat ${awrFile}|egrep 'user calls|physical read total IO requests|physical write total IO requests|physical read total|physical write total |received via SQL|sent via SQL\*Net to client|SQL\*Net roundtrips'|grep -v 'multi block' >${awrFile}_parsed
;;
esac
done

