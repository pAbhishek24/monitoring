exec dbms_workload_repository.create_snapshot ;
SELECT max(snap_id) FROM dba_hist_snapshot;
quit
