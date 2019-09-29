set linesize 150
set pagesize 50000

select segment_type, round(sum(blocks)*8192/(1024*1024*1024),2) as SEGMENT_SIZE_GB 
from dba_segments group by segment_type order by SEGMENT_SIZE_GB desc;

select 
  round(sum(bytes)/(1024*1024*1024),2) as DATAFILE_SIZE_GB 
  from dba_data_files;
  
select 
  segment_name, segment_type, blocks*8192/(1024*1024*1024) as SEGMENT_SIZE_GB 
 from dba_segments where tablespace_name='CISTS_01' order by SEGMENT_SIZE_GB desc;

select round(sum(blocks)*8192/(1024*1024*1024),2) as TABLE_SZ_BY_BLKS_GB, round((sum(num_rows* avg_row_len)/(1024*1024*1024)),2) as TABLE_SZ_BY_ROWS_GB
  from dba_tables where owner='CISADM' ;

select 
  table_name, round((num_rows* avg_row_len/(1024*1024*1024)),2) as TABLE_SZ_BY_ROWS_GB,  round(blocks*8192/(1024*1024*1024),2) as TABLE_SZ_BY_BLKS_GB,
  num_rows, avg_row_len, compression, compress_for, last_analyzed 
    from dba_tables 
    where  owner ='CISADM' and num_rows is not null order by TABLE_SZ_BY_ROWS_GB desc;

quit;
