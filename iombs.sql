-- iombs.sql
-- AWR IO Workload Report
-- Karl Arao, Oracle ACE (bit.ly/karlarao), OCP-DBA, RHCE
-- http://karlarao.wordpress.com
--
-- NOTE:
--
-- Changes:
--


COLUMN blocksize NEW_VALUE _blocksize NOPRINT
select distinct block_size blocksize from v$datafile;

COLUMN dbid NEW_VALUE _dbid NOPRINT
select dbid from v$database;

COLUMN name NEW_VALUE _instname NOPRINT
select lower(instance_name) name from v$instance;

COLUMN name NEW_VALUE _hostname NOPRINT
select lower(host_name) name from v$instance;

COLUMN instancenumber NEW_VALUE _instancenumber NOPRINT
select instance_number instancenumber from v$instance;

-- ttitle center 'AWR IO Workload Report' skip 2
set pagesize 50000
set linesize 550

col id          format 99999
col inst        format 90
col cpu         format 990
col load        format 9990
col dur         format 990
col oscpupct    format 990
col oscpuio     format 990
col txs         format 9990.00


SELECT * FROM
(
  SELECT substr('&_instname',1,8) instname, substr('&_hostname',1,8) hostname,
         s0.snap_id id,
         TO_CHAR(s0.END_INTERVAL_TIME,'MM/DD/YY HH24:MI:SS') tm,
  round(EXTRACT(DAY FROM s1.END_INTERVAL_TIME - s0.END_INTERVAL_TIME) * 1440
                                  + EXTRACT(HOUR FROM s1.END_INTERVAL_TIME - s0.END_INTERVAL_TIME) * 60
                                  + EXTRACT(MINUTE FROM s1.END_INTERVAL_TIME - s0.END_INTERVAL_TIME)
                                  + EXTRACT(SECOND FROM s1.END_INTERVAL_TIME - s0.END_INTERVAL_TIME) / 60, 2) dur,
  s3t1.value AS cpu,
  round(s2t1.value,2) AS load,
  (((s1t1.value - s1t0.value)/100) / ((round(EXTRACT(DAY FROM s1.END_INTERVAL_TIME - s0.END_INTERVAL_TIME) * 1440 
                                                                                              + EXTRACT(HOUR FROM s1.END_INTERVAL_TIME - s0.END_INTERVAL_TIME) * 60 
                                                                                              + EXTRACT(MINUTE FROM s1.END_INTERVAL_TIME - s0.END_INTERVAL_TIME) 
                                                                                              + EXTRACT(SECOND FROM s1.END_INTERVAL_TIME - s0.END_INTERVAL_TIME) / 60, 2)*60)*s3t1.value))*100 as oscpupct,
  (((s19t1.value - s19t0.value)/100) / ((round(EXTRACT(DAY FROM s1.END_INTERVAL_TIME - s0.END_INTERVAL_TIME) * 1440 
                                                                                              + EXTRACT(HOUR FROM s1.END_INTERVAL_TIME - s0.END_INTERVAL_TIME) * 60 
                                                                                              + EXTRACT(MINUTE FROM s1.END_INTERVAL_TIME - s0.END_INTERVAL_TIME) 
                                                                                              + EXTRACT(SECOND FROM s1.END_INTERVAL_TIME - s0.END_INTERVAL_TIME) / 60, 2)*60)*s3t1.value))*100 as oscpuio,
   round((((s34t1.value - s34t0.value) + (s35t1.value - s35t0.value))  / ((round(EXTRACT(DAY FROM s1.END_INTERVAL_TIME - s0.END_INTERVAL_TIME) * 1440 
                                  + EXTRACT(HOUR FROM s1.END_INTERVAL_TIME - s0.END_INTERVAL_TIME) * 60 
                                  + EXTRACT(MINUTE FROM s1.END_INTERVAL_TIME - s0.END_INTERVAL_TIME) 
                                  + EXTRACT(SECOND FROM s1.END_INTERVAL_TIME - s0.END_INTERVAL_TIME) / 60, 2))*60)
    ),3) as txs,
   round((((s20t1.value - s20t0.value) - (s21t1.value - s21t0.value)) / ((round(EXTRACT(DAY FROM s1.END_INTERVAL_TIME - s0.END_INTERVAL_TIME) * 1440
                                  + EXTRACT(HOUR FROM s1.END_INTERVAL_TIME - s0.END_INTERVAL_TIME) * 60
                                  + EXTRACT(MINUTE FROM s1.END_INTERVAL_TIME - s0.END_INTERVAL_TIME)
                                  + EXTRACT(SECOND FROM s1.END_INTERVAL_TIME - s0.END_INTERVAL_TIME) / 60, 2))*60)
    ),2) as SIORs,
   round(((s21t1.value - s21t0.value) / ((round(EXTRACT(DAY FROM s1.END_INTERVAL_TIME - s0.END_INTERVAL_TIME) * 1440
                                  + EXTRACT(HOUR FROM s1.END_INTERVAL_TIME - s0.END_INTERVAL_TIME) * 60
                                  + EXTRACT(MINUTE FROM s1.END_INTERVAL_TIME - s0.END_INTERVAL_TIME)
                                  + EXTRACT(SECOND FROM s1.END_INTERVAL_TIME - s0.END_INTERVAL_TIME) / 60, 2))*60)
    ),2) as MIORs,
    round(( ((((s20t1.value - s20t0.value) - (s21t1.value - s21t0.value)) + (s21t1.value - s21t0.value)) + (((s23t1.value - s23t0.value) - (s24t1.value - s24t0.value)) + (s24t1.value - s24t0.value) + (s13t1.value - s13t0.value))) / ((round(EXTRACT(DAY FROM s1.END_INTERVAL_TIME - s0.END_INTERVAL_TIME) * 1440 
                                  + EXTRACT(HOUR FROM s1.END_INTERVAL_TIME - s0.END_INTERVAL_TIME) * 60 
                                  + EXTRACT(MINUTE FROM s1.END_INTERVAL_TIME - s0.END_INTERVAL_TIME) 
                                  + EXTRACT(SECOND FROM s1.END_INTERVAL_TIME - s0.END_INTERVAL_TIME) / 60, 2))*60)
    ),2) as TIOALL,  
   round(((((s22t1.value - s22t0.value)/1024/1024) + ((s25t1.value - s25t0.value)/1024/1024) + ((s14t1.value - s14t0.value)/1024/1024)) / ((round(EXTRACT(DAY FROM s1.END_INTERVAL_TIME - s0.END_INTERVAL_TIME) * 1440
                                  + EXTRACT(HOUR FROM s1.END_INTERVAL_TIME - s0.END_INTERVAL_TIME) * 60
                                  + EXTRACT(MINUTE FROM s1.END_INTERVAL_TIME - s0.END_INTERVAL_TIME)
                                  + EXTRACT(SECOND FROM s1.END_INTERVAL_TIME - s0.END_INTERVAL_TIME) / 60, 2))*60)
    ),2) as GRANDmbs,
   round((((s29t1.value - s29t0.value)/1024/1024) / ((round(EXTRACT(DAY FROM s1.END_INTERVAL_TIME - s0.END_INTERVAL_TIME) * 1440
                                  + EXTRACT(HOUR FROM s1.END_INTERVAL_TIME - s0.END_INTERVAL_TIME) * 60
                                  + EXTRACT(MINUTE FROM s1.END_INTERVAL_TIME - s0.END_INTERVAL_TIME)
                                  + EXTRACT(SECOND FROM s1.END_INTERVAL_TIME - s0.END_INTERVAL_TIME) / 60, 2))*60)
    ),2) as offloadmbs
FROM dba_hist_snapshot s0,
  dba_hist_snapshot s1,
  dba_hist_osstat s2t1,         -- osstat just get the end value
  dba_hist_osstat s3t1,         -- osstat just get the end value
  dba_hist_osstat s1t0,         -- BUSY_TIME
  dba_hist_osstat s1t1,
  dba_hist_osstat s19t0,        -- IOWAIT_TIME
  dba_hist_osstat s19t1,
  dba_hist_sysstat s34t0,       -- user commits, diffed
  dba_hist_sysstat s34t1,
  dba_hist_sysstat s35t0,       -- user rollbacks, diffed
  dba_hist_sysstat s35t1,
  dba_hist_sysstat s14t0,       -- redo size, diffed
  dba_hist_sysstat s14t1,
  dba_hist_sysstat s20t0,       -- physical read total IO requests, diffed
  dba_hist_sysstat s20t1,
  dba_hist_sysstat s21t0,       -- physical read total multi block requests, diffed
  dba_hist_sysstat s21t1,
  dba_hist_sysstat s22t0,       -- physical read total bytes, diffed
  dba_hist_sysstat s22t1,
  dba_hist_sysstat s25t0,       -- physical write total bytes, diffed
  dba_hist_sysstat s25t1,
  dba_hist_sysstat s29t0,       -- cell physical IO bytes eligible for predicate offload, diffed, cellpiobpreoff
  dba_hist_sysstat s29t1,
  dba_hist_sysstat s23t0,       -- physical write total IO requests, diffed
  dba_hist_sysstat s23t1,
  dba_hist_sysstat s24t0,       -- physical write total multi block requests, diffed
  dba_hist_sysstat s24t1,
  dba_hist_sysstat s13t0,       -- redo writes, diffed
  dba_hist_sysstat s13t1
WHERE s0.dbid            = &_dbid    -- CHANGE THE DBID HERE!
AND s1.dbid              = s0.dbid
AND s1t0.dbid            = s0.dbid
AND s1t1.dbid            = s0.dbid
AND s19t0.dbid            = s0.dbid
AND s19t1.dbid            = s0.dbid
AND s2t1.dbid            = s0.dbid
AND s3t1.dbid            = s0.dbid
AND s34t0.dbid            = s0.dbid
AND s34t1.dbid            = s0.dbid
AND s35t0.dbid            = s0.dbid
AND s35t1.dbid            = s0.dbid
AND s14t0.dbid            = s0.dbid
AND s14t1.dbid            = s0.dbid
AND s20t0.dbid            = s0.dbid
AND s20t1.dbid            = s0.dbid
AND s21t0.dbid            = s0.dbid
AND s21t1.dbid            = s0.dbid
AND s22t0.dbid            = s0.dbid
AND s22t1.dbid            = s0.dbid
AND s25t0.dbid            = s0.dbid
AND s25t1.dbid            = s0.dbid
AND s29t0.dbid            = s0.dbid
AND s29t1.dbid            = s0.dbid
AND s23t0.dbid            = s0.dbid
AND s23t1.dbid            = s0.dbid
AND s24t0.dbid            = s0.dbid
AND s24t1.dbid            = s0.dbid
AND s13t0.dbid            = s0.dbid
AND s13t1.dbid            = s0.dbid
AND s0.instance_number    = &_instancenumber   -- CHANGE THE INSTANCE_NUMBER HERE!
AND s1.instance_number    = s0.instance_number
AND s2t1.instance_number  = s0.instance_number
AND s3t1.instance_number  = s0.instance_number
AND s1t0.instance_number  = s0.instance_number
AND s1t1.instance_number  = s0.instance_number
AND s19t0.instance_number = s0.instance_number
AND s19t1.instance_number = s0.instance_number
AND s34t0.instance_number = s0.instance_number
AND s34t1.instance_number = s0.instance_number
AND s35t0.instance_number = s0.instance_number
AND s35t1.instance_number = s0.instance_number
AND s14t0.instance_number = s0.instance_number
AND s14t1.instance_number = s0.instance_number
AND s20t0.instance_number = s0.instance_number
AND s20t1.instance_number = s0.instance_number
AND s21t0.instance_number = s0.instance_number
AND s21t1.instance_number = s0.instance_number
AND s22t0.instance_number = s0.instance_number
AND s22t1.instance_number = s0.instance_number
AND s25t0.instance_number = s0.instance_number
AND s25t1.instance_number = s0.instance_number
AND s29t0.instance_number = s0.instance_number
AND s29t1.instance_number = s0.instance_number
AND s23t0.instance_number = s0.instance_number
AND s23t1.instance_number = s0.instance_number
AND s24t0.instance_number = s0.instance_number
AND s24t1.instance_number = s0.instance_number
AND s13t0.instance_number = s0.instance_number
AND s13t1.instance_number = s0.instance_number
AND s1.snap_id            = s0.snap_id + 1
AND s2t1.snap_id          = s0.snap_id + 1
AND s3t1.snap_id          = s0.snap_id + 1
AND s1t0.snap_id          = s0.snap_id
AND s1t1.snap_id          = s0.snap_id + 1
AND s19t0.snap_id         = s0.snap_id
AND s19t1.snap_id         = s0.snap_id + 1
AND s34t0.snap_id         = s0.snap_id
AND s34t1.snap_id         = s0.snap_id + 1
AND s35t0.snap_id         = s0.snap_id
AND s35t1.snap_id         = s0.snap_id + 1
AND s14t0.snap_id         = s0.snap_id
AND s14t1.snap_id         = s0.snap_id + 1
AND s20t0.snap_id         = s0.snap_id
AND s20t1.snap_id         = s0.snap_id + 1
AND s21t0.snap_id         = s0.snap_id
AND s21t1.snap_id         = s0.snap_id + 1
AND s22t0.snap_id         = s0.snap_id
AND s22t1.snap_id         = s0.snap_id + 1
AND s25t0.snap_id         = s0.snap_id
AND s25t1.snap_id         = s0.snap_id + 1
AND s29t0.snap_id         = s0.snap_id
AND s29t1.snap_id         = s0.snap_id + 1
AND s23t0.snap_id         = s0.snap_id
AND s23t1.snap_id         = s0.snap_id + 1
AND s24t0.snap_id         = s0.snap_id
AND s24t1.snap_id         = s0.snap_id + 1
AND s13t0.snap_id         = s0.snap_id
AND s13t1.snap_id         = s0.snap_id + 1
AND s2t1.stat_name        = 'LOAD'
AND s3t1.stat_name        = 'NUM_CPUS'
AND s1t0.stat_name        = 'BUSY_TIME'
AND s1t1.stat_name        = s1t0.stat_name
AND s19t0.stat_name       = 'IOWAIT_TIME'
AND s19t1.stat_name       = s19t0.stat_name
AND s34t0.stat_name       = 'user commits'
AND s34t1.stat_name       = s34t0.stat_name
AND s35t0.stat_name       = 'user rollbacks'
AND s35t1.stat_name       = s35t0.stat_name
AND s14t0.stat_name       = 'redo size'
AND s14t1.stat_name       = s14t0.stat_name
AND s20t0.stat_name       = 'physical read total IO requests'
AND s20t1.stat_name       = s20t0.stat_name
AND s21t0.stat_name       = 'physical read total multi block requests'
AND s21t1.stat_name       = s21t0.stat_name
AND s22t0.stat_name       = 'physical read total bytes'
AND s22t1.stat_name       = s22t0.stat_name
AND s25t0.stat_name       = 'physical write total bytes'
AND s25t1.stat_name       = s25t0.stat_name
AND s29t0.stat_name       = 'cell physical IO bytes eligible for predicate offload'
AND s29t1.stat_name       = s29t0.stat_name
AND s23t0.stat_name       = 'physical write total IO requests'
AND s23t1.stat_name       = s23t0.stat_name
AND s24t0.stat_name       = 'physical write total multi block requests'
AND s24t1.stat_name       = s24t0.stat_name
AND s13t0.stat_name       = 'redo writes'
AND s13t1.stat_name       = s13t0.stat_name
order by s0.snap_id desc)
-- WHERE
-- tm > to_char(sysdate - 30, 'MM/DD/YY HH24:MI')
-- id  in (select snap_id from (select * from r2toolkit.r2_regression_data union all select * from r2toolkit.r2_outlier_data))
-- id in (338)
-- aas > 1
-- oscpuio > 50
-- rmancpupct > 0
-- AND TO_CHAR(s0.END_INTERVAL_TIME,'D') >= 1     -- Day of week: 1=Sunday 7=Saturday
-- AND TO_CHAR(s0.END_INTERVAL_TIME,'D') <= 7
-- AND TO_CHAR(s0.END_INTERVAL_TIME,'HH24MI') >= 0900     -- Hour
-- AND TO_CHAR(s0.END_INTERVAL_TIME,'HH24MI') <= 1800
-- AND s0.END_INTERVAL_TIME >= TO_DATE('2010-jan-17 00:00:00','yyyy-mon-dd hh24:mi:ss')     -- Data range
-- AND s0.END_INTERVAL_TIME <= TO_DATE('2010-aug-22 23:59:59','yyyy-mon-dd hh24:mi:ss')
where rownum < 41
ORDER BY id ASC;

exit
