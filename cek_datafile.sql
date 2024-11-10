set lines 125 pages 1000 ver off
col file_name form a50
col alloc_mb form 999G999
col free_mb form 999G999
col status form a11
col AUTOEXTENSIBLE for a14
break on report
compute sum of alloc_mb free_mb on report
 
select d.tablespace_name, d.file_id, d.file_name, d.bytes/1024/1024 alloc_mb, sum(nvl(f.bytes,0))/1024/1024 free_mb, d.autoextensible, d.status
from dba_data_files d, dba_free_space f
where d.tablespace_name = nvl('&tablespace_name',d.tablespace_name)
and   d.tablespace_name = f.tablespace_name(+)
and   d.file_id = f.file_id(+)
group by d.tablespace_name, d.file_id, d.file_name, d.bytes/1024/1024, d.autoextensible, d.status
order by d.file_id
/
 
set ver on
