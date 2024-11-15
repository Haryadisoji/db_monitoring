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
$ cat tablespace.sql
set lines 125 pages 1000 ver off
col status format a7
col tablespace_name form a20
col file_name for a50
col "TS_size(MB)" form 99g999g999
col used form 999g999g999
col free form 999g999g999
break on report
compute sum of bytes on report
compute sum of "TS_size(MB)" on report
compute sum of used on report
compute sum of free on report
 
accept tbs_name char default 'ALL' prompt 'Please enter tablespace_name (ALL) : '
 
SELECT status, NAME TABLESPACE_NAME, TYPE, extent_mgt, "TS_size(MB)", used, "TS_size(MB)" - used free, pct_used
FROM (SELECT d.status status, d.tablespace_name NAME, d.CONTENTS TYPE,
d.extent_management extent_mgt,
  d.segment_space_management segment_mgt,
   NVL (a.BYTES / 1024 / 1024, 0) "TS_size(MB)",
    NVL (a.BYTES / 1024 / 1024 - NVL (f.BYTES / 1024 / 1024, 0), 0) used,
     NVL (FLOOR (((a.BYTES - NVL (f.BYTES, 0)) / a.BYTES * 100)), 0) pct_used
      FROM SYS.dba_tablespaces d,
       (SELECT tablespace_name, SUM (BYTES) BYTES
FROM dba_data_files
GROUP BY tablespace_name) a,
  (SELECT tablespace_name, SUM (BYTES) BYTES
   FROM dba_free_space
    GROUP BY tablespace_name) f
     WHERE d.tablespace_name = a.tablespace_name(+)
      AND d.tablespace_name = f.tablespace_name(+)
      AND NOT (d.extent_management LIKE 'LOCAL'
       AND (d.CONTENTS LIKE 'TEMPORARY' or d.CONTENTS = 'UNDO')
)
UNION ALL
  SELECT d.status status, d.tablespace_name NAME, d.CONTENTS TYPE,
   d.extent_management extent_mgt,
    d.segment_space_management segment_mgt,
     NVL (a.BYTES / 1024 / 1024, 0) "TS_size(MB)",
      NVL (t.BYTES / 1024 / 1024, 0) used,
       NVL (FLOOR ((t.BYTES / a.BYTES * 100)), 0) pct_used
FROM SYS.dba_tablespaces d,
(SELECT tablespace_name, SUM (BYTES) BYTES
  FROM dba_temp_files
   GROUP BY tablespace_name) a,
    (SELECT tablespace tablespace_name, SUM (blocks*8192) BYTES
     FROM v$sort_usage
      GROUP BY tablespace) t
       WHERE d.tablespace_name = a.tablespace_name(+)
AND d.tablespace_name = t.tablespace_name(+)
AND d.extent_management LIKE 'LOCAL'
  AND d.CONTENTS LIKE 'TEMPORARY'
   UNION ALL
    (select d.status status,d.tablespace_name NAME,d.contents TYPE,
    d.extent_management extent_mgt,
     d.segment_space_management segment_mgt,
      NVL (a.BYTES / 1024 / 1024, 0) "TS_size(MB)",
       NVL (t.BYTES / 1024 / 1024, 0) used,
NVL (FLOOR ((t.BYTES / a.BYTES * 100)), 0) pct_used
from SYS.dba_tablespaces d,
  (select tablespace_name, SUM (BYTES) BYTES
   FROM dba_data_files
    GROUP BY tablespace_name) a,
     (
      select tablespace_name,sum(bytes) BYTES from dba_undo_extents where status in ('ACTIVE') group by tablespace_name
       ) t
where d.tablespace_name=a.tablespace_name(+)
AND d.tablespace_name=t.tablespace_name(+)
  AND d.extent_management LIKE 'LOCAL'
   AND d.CONTENTS ='UNDO'
    )
     )
where name like '%'||decode('&&tbs_name','ALL',name,'&&tbs_name')||'%' order by pct_used desc, name
/
set ver on
