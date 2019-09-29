spool gatherStats.log
select sysdate from dual;
exec dbms_stats.gather_table_stats(ownname => 'CISADM', tabname => 'D1_MSRMT', estimate_percent => 5, block_sample => FALSE, degree => 16, cascade => TRUE);
quit;

