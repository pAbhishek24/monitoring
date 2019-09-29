set serveroutput on size 100000
set verify off
set linesize 200
set pagesize 1000

col machine  heading 'Hostname' format a25
col username  heading 'Username' format a15
col spid  heading 'Unix_PID' format 9999999
col sid heading 'SID'  format 9999999
col serial# heading 'serial#' format 9999999
col logon_time heading 'logon_time' format a20
col status format a10
col module heading 'MODULE' format a20

select  a.machine, a.username, b.spid, a.sid, a.serial#, a.logon_time, a.status, a.state, a.last_call_et, a.module, a.sql_id   from v$session a, v$process b   where b.addr = a.paddr order by a.machine, a.username, a.last_call_et;

quit
