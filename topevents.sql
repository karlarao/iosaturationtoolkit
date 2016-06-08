-- awr_topevents.sql
-- AWR Top Events Report, a version of "Top 5 Timed Events" but across SNAP_IDs with AAS metric 
-- Karl Arao, Oracle ACE (bit.ly/karlarao), OCP-DBA, RHCE
-- http://karlarao.wordpress.com
--
-- Changes: 
-- 20100427     included the columns "tm, inst, dur" and "event_rank"
-- 20100511     added timestamp to filter specific workload periods, must uncomment to use
-- 20120120     added a section to compute for "CPU wait" (new metric in 11g) to include the 
--               "unaccounted for DB Time" on high run queue or CPU intensive workloads
--                


COLUMN dbid NEW_VALUE _dbid NOPRINT
select dbid from v$database;

COLUMN name NEW_VALUE _instname NOPRINT
select lower(instance_name) name from v$instance;

COLUMN name NEW_VALUE _hostname NOPRINT
select lower(host_name) name from v$instance;

COLUMN instancenumber NEW_VALUE _instancenumber NOPRINT
select instance_number instancenumber from v$instance;

-- ttitle center 'AWR Top Events Report' skip 2
set pagesize 50000
set linesize 350

col instname    format a9
col hostname    format a9
col snap_id     format 99999            heading snap_id   
col tm          format a17              heading tm        
col inst        format 90               heading inst      
col dur         format 9990.00          heading dur       
col event       format a32              heading event     
col event_rank  format 90               heading event_rank
col waits       format 9999999990.00    heading waits     
col time        format 9999999990.00    heading time      
col avgwt       format 99990.00         heading avgwt     
col pctdbt      format 9990.0           heading pctdbt    
col aas         format 990.0            heading aas       
col wait_class  format a15              heading wait_class
break on snap_id on tm skip 1

SELECT * FROM
(
select substr('&_instname',1,8) instname, substr('&_hostname',1,8) hostname, snap_id, tm, inst, dur, event, event_rank, avgwt, pctdbt, aas, wait_class
from 
      (select snap_id, TO_CHAR(tm,'MM/DD/YY HH24:MI:SS') tm, inst, dur, event, waits, time, avgwt, pctdbt, aas, wait_class, 
            DENSE_RANK() OVER (
          PARTITION BY snap_id ORDER BY time DESC) event_rank
      from 
              (
              select * from 
                    (select * from 
                          (select 
                            s0.snap_id snap_id,
                            s0.END_INTERVAL_TIME tm,
                            s0.instance_number inst,
                            round(EXTRACT(DAY FROM s1.END_INTERVAL_TIME - s0.END_INTERVAL_TIME) * 1440 
                                    + EXTRACT(HOUR FROM s1.END_INTERVAL_TIME - s0.END_INTERVAL_TIME) * 60 
                                    + EXTRACT(MINUTE FROM s1.END_INTERVAL_TIME - s0.END_INTERVAL_TIME) 
                                    + EXTRACT(SECOND FROM s1.END_INTERVAL_TIME - s0.END_INTERVAL_TIME) / 60, 2) dur,
                            e.event_name event,
                            e.total_waits - nvl(b.total_waits,0)       waits,
                            round ((e.time_waited_micro - nvl(b.time_waited_micro,0))/1000000, 2)  time,     -- THIS IS EVENT (sec)
                            round (decode ((e.total_waits - nvl(b.total_waits, 0)), 0, to_number(NULL), ((e.time_waited_micro - nvl(b.time_waited_micro,0))/1000) / (e.total_waits - nvl(b.total_waits,0))), 2) avgwt,
                            ((round ((e.time_waited_micro - nvl(b.time_waited_micro,0))/1000000, 2)) / ((s5t1.value - s5t0.value) / 1000000))*100 as pctdbt,     -- THIS IS EVENT (sec) / DB TIME (sec)
                            (round ((e.time_waited_micro - nvl(b.time_waited_micro,0))/1000000, 2))/60 /  round(EXTRACT(DAY FROM s1.END_INTERVAL_TIME - s0.END_INTERVAL_TIME) * 1440 
                                                            + EXTRACT(HOUR FROM s1.END_INTERVAL_TIME - s0.END_INTERVAL_TIME) * 60 
                                                            + EXTRACT(MINUTE FROM s1.END_INTERVAL_TIME - s0.END_INTERVAL_TIME) 
                                                            + EXTRACT(SECOND FROM s1.END_INTERVAL_TIME - s0.END_INTERVAL_TIME) / 60, 2) aas,     -- THIS IS EVENT (min) / SnapDur (min) TO GET THE % DB CPU ON AAS
                            e.wait_class wait_class
                            from 
                                 dba_hist_snapshot s0,
                                 dba_hist_snapshot s1,
                                 dba_hist_system_event b,
                                 dba_hist_system_event e,
                                 dba_hist_sys_time_model s5t0,
                                 dba_hist_sys_time_model s5t1
                            where 
                              s0.dbid                   = &_dbid            -- CHANGE THE DBID HERE!
                              AND s1.dbid               = s0.dbid
                              and b.dbid(+)             = s0.dbid
                              and e.dbid                = s0.dbid
                              AND s5t0.dbid             = s0.dbid
                              AND s5t1.dbid             = s0.dbid
                              AND s0.instance_number    = &_instancenumber  -- CHANGE THE INSTANCE_NUMBER HERE!
                              AND s1.instance_number    = s0.instance_number
                              and b.instance_number(+)  = s0.instance_number
                              and e.instance_number     = s0.instance_number
                              AND s5t0.instance_number = s0.instance_number
                              AND s5t1.instance_number = s0.instance_number
                              AND s1.snap_id            = s0.snap_id + 1
                              AND b.snap_id(+)          = s0.snap_id
                              and e.snap_id             = s0.snap_id + 1
                              AND s5t0.snap_id         = s0.snap_id
                              AND s5t1.snap_id         = s0.snap_id + 1
                              AND s5t0.stat_name       = 'DB time'
                              AND s5t1.stat_name       = s5t0.stat_name
                                    and b.event_id            = e.event_id
                                    and e.wait_class          != 'Idle'
                                    and e.total_waits         > nvl(b.total_waits,0)
                                    and e.event_name not in ('smon timer', 
                                                             'pmon timer', 
                                                             'dispatcher timer',
                                                             'dispatcher listen timer',
                                                             'rdbms ipc message')
                                  order by snap_id, time desc, waits desc, event)
                    union all
                              select 
                                       s0.snap_id snap_id,
                                       s0.END_INTERVAL_TIME tm,
                                       s0.instance_number inst,
                                       round(EXTRACT(DAY FROM s1.END_INTERVAL_TIME - s0.END_INTERVAL_TIME) * 1440 
                                            + EXTRACT(HOUR FROM s1.END_INTERVAL_TIME - s0.END_INTERVAL_TIME) * 60 
                                            + EXTRACT(MINUTE FROM s1.END_INTERVAL_TIME - s0.END_INTERVAL_TIME) 
                                            + EXTRACT(SECOND FROM s1.END_INTERVAL_TIME - s0.END_INTERVAL_TIME) / 60, 2) dur,
                                        'CPU time',
                                        0,
                                        round ((s6t1.value - s6t0.value) / 1000000, 2) as time,     -- THIS IS DB CPU (sec)
                                        0,
                                        ((round ((s6t1.value - s6t0.value) / 1000000, 2)) / ((s5t1.value - s5t0.value) / 1000000))*100 as pctdbt,     -- THIS IS DB CPU (sec) / DB TIME (sec)..TO GET % OF DB CPU ON DB TIME FOR TOP 5 TIMED EVENTS SECTION
                                        (round ((s6t1.value - s6t0.value) / 1000000, 2))/60 /  round(EXTRACT(DAY FROM s1.END_INTERVAL_TIME - s0.END_INTERVAL_TIME) * 1440 
                                                                    + EXTRACT(HOUR FROM s1.END_INTERVAL_TIME - s0.END_INTERVAL_TIME) * 60 
                                                                    + EXTRACT(MINUTE FROM s1.END_INTERVAL_TIME - s0.END_INTERVAL_TIME) 
                                                                    + EXTRACT(SECOND FROM s1.END_INTERVAL_TIME - s0.END_INTERVAL_TIME) / 60, 2) aas,  -- THIS IS DB CPU (min) / SnapDur (min) TO GET THE % DB CPU ON AAS
                                        'CPU'
                                      from 
                                        dba_hist_snapshot s0,
                                        dba_hist_snapshot s1,
                                        dba_hist_sys_time_model s6t0,
                                        dba_hist_sys_time_model s6t1,
                                        dba_hist_sys_time_model s5t0,
                                        dba_hist_sys_time_model s5t1
                                      WHERE 
                                      s0.dbid                   = &_dbid              -- CHANGE THE DBID HERE!
                                      AND s1.dbid               = s0.dbid
                                      AND s6t0.dbid            = s0.dbid
                                      AND s6t1.dbid            = s0.dbid
                                      AND s5t0.dbid            = s0.dbid
                                      AND s5t1.dbid            = s0.dbid
                                      AND s0.instance_number    = &_instancenumber    -- CHANGE THE INSTANCE_NUMBER HERE!
                                      AND s1.instance_number    = s0.instance_number
                                      AND s6t0.instance_number = s0.instance_number
                                      AND s6t1.instance_number = s0.instance_number
                                      AND s5t0.instance_number = s0.instance_number
                                      AND s5t1.instance_number = s0.instance_number
                                      AND s1.snap_id            = s0.snap_id + 1
                                      AND s6t0.snap_id         = s0.snap_id
                                      AND s6t1.snap_id         = s0.snap_id + 1
                                      AND s5t0.snap_id         = s0.snap_id
                                      AND s5t1.snap_id         = s0.snap_id + 1
                                      AND s6t0.stat_name       = 'DB CPU'
                                      AND s6t1.stat_name       = s6t0.stat_name
                                      AND s5t0.stat_name       = 'DB time'
                                      AND s5t1.stat_name       = s5t0.stat_name
                    union all
                                      (select 
                                               dbtime.snap_id,
                                               dbtime.tm,
                                               dbtime.inst,
                                               dbtime.dur,
                                               'CPU wait',
                                                0,
                                                round(dbtime.time - accounted_dbtime.time, 2) time,     -- THIS IS UNACCOUNTED FOR DB TIME (sec)
                                                0,
                                                ((dbtime.aas - accounted_dbtime.aas)/dbtime.aas)*100 as pctdbt,     -- THIS IS UNACCOUNTED FOR DB TIME (sec) / DB TIME (sec)
                                                round(dbtime.aas - accounted_dbtime.aas, 2) aas,     -- AAS OF UNACCOUNTED FOR DB TIME
                                                'CPU wait'
                                      from
                                                  (select  
                                                     s0.snap_id, 
                                                     s0.END_INTERVAL_TIME tm,
                                                     s0.instance_number inst,
                                                    round(EXTRACT(DAY FROM s1.END_INTERVAL_TIME - s0.END_INTERVAL_TIME) * 1440 
                                                    + EXTRACT(HOUR FROM s1.END_INTERVAL_TIME - s0.END_INTERVAL_TIME) * 60 
                                                    + EXTRACT(MINUTE FROM s1.END_INTERVAL_TIME - s0.END_INTERVAL_TIME) 
                                                    + EXTRACT(SECOND FROM s1.END_INTERVAL_TIME - s0.END_INTERVAL_TIME) / 60, 2) dur,
                                                    'DB time',
                                                    0,
                                                    round ((s5t1.value - s5t0.value) / 1000000, 2) as time,     -- THIS IS DB time (sec)
                                                    0,
                                                    0,
                                                     (round ((s5t1.value - s5t0.value) / 1000000, 2))/60 /  round(EXTRACT(DAY FROM s1.END_INTERVAL_TIME - s0.END_INTERVAL_TIME) * 1440 
                                                                                    + EXTRACT(HOUR FROM s1.END_INTERVAL_TIME - s0.END_INTERVAL_TIME) * 60 
                                                                                    + EXTRACT(MINUTE FROM s1.END_INTERVAL_TIME - s0.END_INTERVAL_TIME) 
                                                                                    + EXTRACT(SECOND FROM s1.END_INTERVAL_TIME - s0.END_INTERVAL_TIME) / 60, 2) aas,
                                                    'DB time'
                                                  from 
                                                                    dba_hist_snapshot s0,
                                                                    dba_hist_snapshot s1,
                                                                    dba_hist_sys_time_model s5t0,
                                                                    dba_hist_sys_time_model s5t1
                                                                  WHERE 
                                                                  s0.dbid                   = &_dbid              -- CHANGE THE DBID HERE!
                                                                  AND s1.dbid               = s0.dbid
                                                                  AND s5t0.dbid            = s0.dbid
                                                                  AND s5t1.dbid            = s0.dbid
                                                                  AND s0.instance_number    = &_instancenumber    -- CHANGE THE INSTANCE_NUMBER HERE!
                                                                  AND s1.instance_number    = s0.instance_number
                                                                  AND s5t0.instance_number = s0.instance_number
                                                                  AND s5t1.instance_number = s0.instance_number
                                                                  AND s1.snap_id            = s0.snap_id + 1
                                                                  AND s5t0.snap_id         = s0.snap_id
                                                                  AND s5t1.snap_id         = s0.snap_id + 1
                                                                  AND s5t0.stat_name       = 'DB time'
                                                                  AND s5t1.stat_name       = s5t0.stat_name) dbtime, 
                                                  (select snap_id, sum(time) time, sum(AAS) aas from 
                                                          (select * from (select 
                                                                s0.snap_id snap_id,
                                                                s0.END_INTERVAL_TIME tm,
                                                                s0.instance_number inst,
                                                                round(EXTRACT(DAY FROM s1.END_INTERVAL_TIME - s0.END_INTERVAL_TIME) * 1440 
                                                                        + EXTRACT(HOUR FROM s1.END_INTERVAL_TIME - s0.END_INTERVAL_TIME) * 60 
                                                                        + EXTRACT(MINUTE FROM s1.END_INTERVAL_TIME - s0.END_INTERVAL_TIME) 
                                                                        + EXTRACT(SECOND FROM s1.END_INTERVAL_TIME - s0.END_INTERVAL_TIME) / 60, 2) dur,
                                                                e.event_name event,
                                                                e.total_waits - nvl(b.total_waits,0)       waits,
                                                                round ((e.time_waited_micro - nvl(b.time_waited_micro,0))/1000000, 2)  time,     -- THIS IS EVENT (sec)
                                                                round (decode ((e.total_waits - nvl(b.total_waits, 0)), 0, to_number(NULL), ((e.time_waited_micro - nvl(b.time_waited_micro,0))/1000) / (e.total_waits - nvl(b.total_waits,0))), 2) avgwt,
                                                                ((round ((e.time_waited_micro - nvl(b.time_waited_micro,0))/1000000, 2)) / ((s5t1.value - s5t0.value) / 1000000))*100 as pctdbt,     -- THIS IS EVENT (sec) / DB TIME (sec)
                                                                (round ((e.time_waited_micro - nvl(b.time_waited_micro,0))/1000000, 2))/60 /  round(EXTRACT(DAY FROM s1.END_INTERVAL_TIME - s0.END_INTERVAL_TIME) * 1440 
                                                                                                + EXTRACT(HOUR FROM s1.END_INTERVAL_TIME - s0.END_INTERVAL_TIME) * 60 
                                                                                                + EXTRACT(MINUTE FROM s1.END_INTERVAL_TIME - s0.END_INTERVAL_TIME) 
                                                                                                + EXTRACT(SECOND FROM s1.END_INTERVAL_TIME - s0.END_INTERVAL_TIME) / 60, 2) aas,     -- THIS IS EVENT (min) / SnapDur (min) TO GET THE % DB CPU ON AAS
                                                                e.wait_class wait_class
                                                          from 
                                                               dba_hist_snapshot s0,
                                                               dba_hist_snapshot s1,
                                                               dba_hist_system_event b,
                                                               dba_hist_system_event e,
                                                               dba_hist_sys_time_model s5t0,
                                                               dba_hist_sys_time_model s5t1
                                                          where 
                                                            s0.dbid                   = &_dbid            -- CHANGE THE DBID HERE!
                                                            AND s1.dbid               = s0.dbid
                                                            and b.dbid(+)             = s0.dbid
                                                            and e.dbid                = s0.dbid
                                                            AND s5t0.dbid             = s0.dbid
                                                            AND s5t1.dbid             = s0.dbid
                                                            AND s0.instance_number    = &_instancenumber  -- CHANGE THE INSTANCE_NUMBER HERE!
                                                            AND s1.instance_number    = s0.instance_number
                                                            and b.instance_number(+)  = s0.instance_number
                                                            and e.instance_number     = s0.instance_number
                                                            AND s5t0.instance_number = s0.instance_number
                                                            AND s5t1.instance_number = s0.instance_number
                                                            AND s1.snap_id            = s0.snap_id + 1
                                                            AND b.snap_id(+)          = s0.snap_id
                                                            and e.snap_id             = s0.snap_id + 1
                                                            AND s5t0.snap_id         = s0.snap_id
                                                            AND s5t1.snap_id         = s0.snap_id + 1
                                                      AND s5t0.stat_name       = 'DB time'
                                                      AND s5t1.stat_name       = s5t0.stat_name
                                                            and b.event_id            = e.event_id
                                                            and e.wait_class          != 'Idle'
                                                            and e.total_waits         > nvl(b.total_waits,0)
                                                            and e.event_name not in ('smon timer', 
                                                                                     'pmon timer', 
                                                                                     'dispatcher timer',
                                                                                     'dispatcher listen timer',
                                                                                     'rdbms ipc message')
                                                          order by snap_id, time desc, waits desc, event)
                                                    union all
                                                          select 
                                                                   s0.snap_id snap_id,
                                                                   s0.END_INTERVAL_TIME tm,
                                                                   s0.instance_number inst,
                                                                   round(EXTRACT(DAY FROM s1.END_INTERVAL_TIME - s0.END_INTERVAL_TIME) * 1440 
                                                                        + EXTRACT(HOUR FROM s1.END_INTERVAL_TIME - s0.END_INTERVAL_TIME) * 60 
                                                                        + EXTRACT(MINUTE FROM s1.END_INTERVAL_TIME - s0.END_INTERVAL_TIME) 
                                                                        + EXTRACT(SECOND FROM s1.END_INTERVAL_TIME - s0.END_INTERVAL_TIME) / 60, 2) dur,
                                                                    'CPU time',
                                                                    0,
                                                                    round ((s6t1.value - s6t0.value) / 1000000, 2) as time,     -- THIS IS DB CPU (sec)
                                                                    0,
                                                                    ((round ((s6t1.value - s6t0.value) / 1000000, 2)) / ((s5t1.value - s5t0.value) / 1000000))*100 as pctdbt,     -- THIS IS DB CPU (sec) / DB TIME (sec)..TO GET % OF DB CPU ON DB TIME FOR TOP 5 TIMED EVENTS SECTION
                                                                    (round ((s6t1.value - s6t0.value) / 1000000, 2))/60 /  round(EXTRACT(DAY FROM s1.END_INTERVAL_TIME - s0.END_INTERVAL_TIME) * 1440 
                                                                                                + EXTRACT(HOUR FROM s1.END_INTERVAL_TIME - s0.END_INTERVAL_TIME) * 60 
                                                                                                + EXTRACT(MINUTE FROM s1.END_INTERVAL_TIME - s0.END_INTERVAL_TIME) 
                                                                                                + EXTRACT(SECOND FROM s1.END_INTERVAL_TIME - s0.END_INTERVAL_TIME) / 60, 2) aas,  -- THIS IS DB CPU (min) / SnapDur (min) TO GET THE % DB CPU ON AAS
                                                                    'CPU'
                                                                  from 
                                                                    dba_hist_snapshot s0,
                                                                    dba_hist_snapshot s1,
                                                                    dba_hist_sys_time_model s6t0,
                                                                    dba_hist_sys_time_model s6t1,
                                                                    dba_hist_sys_time_model s5t0,
                                                                    dba_hist_sys_time_model s5t1
                                                                  WHERE 
                                                                  s0.dbid                   = &_dbid              -- CHANGE THE DBID HERE!
                                                                  AND s1.dbid               = s0.dbid
                                                                  AND s6t0.dbid            = s0.dbid
                                                                  AND s6t1.dbid            = s0.dbid
                                                                  AND s5t0.dbid            = s0.dbid
                                                                  AND s5t1.dbid            = s0.dbid
                                                                  AND s0.instance_number    = &_instancenumber    -- CHANGE THE INSTANCE_NUMBER HERE!
                                                                  AND s1.instance_number    = s0.instance_number
                                                                  AND s6t0.instance_number = s0.instance_number
                                                                  AND s6t1.instance_number = s0.instance_number
                                                                  AND s5t0.instance_number = s0.instance_number
                                                                  AND s5t1.instance_number = s0.instance_number
                                                                  AND s1.snap_id            = s0.snap_id + 1
                                                                  AND s6t0.snap_id         = s0.snap_id
                                                                  AND s6t1.snap_id         = s0.snap_id + 1
                                                                  AND s5t0.snap_id         = s0.snap_id
                                                                  AND s5t1.snap_id         = s0.snap_id + 1
                                                                  AND s6t0.stat_name       = 'DB CPU'
                                                                  AND s6t1.stat_name       = s6t0.stat_name
                                                                  AND s5t0.stat_name       = 'DB time'
                                                                  AND s5t1.stat_name       = s5t0.stat_name
                                                          ) group by snap_id) accounted_dbtime
                                                            where dbtime.snap_id = accounted_dbtime.snap_id 
                                        )
                    )
              )
      )
WHERE event_rank <= 5
-- AND tm > to_char(sysdate - 30, 'MM/DD/YY HH24:MI')
-- AND TO_CHAR(tm,'D') >= 1     -- Day of week: 1=Sunday 7=Saturday
-- AND TO_CHAR(tm,'D') <= 7
-- AND TO_CHAR(tm,'HH24MI') >= 0900     -- Hour
-- AND TO_CHAR(tm,'HH24MI') <= 1800
-- AND tm >= TO_DATE('2010-jan-17 00:00:00','yyyy-mon-dd hh24:mi:ss')     -- Data range
-- AND tm <= TO_DATE('2010-aug-22 23:59:59','yyyy-mon-dd hh24:mi:ss')
-- and snap_id = 495
-- and snap_id >= 495 and snap_id <= 496
-- and event = 'db file sequential read'
-- and event like 'CPU%'
-- and avgwt > 5
-- and aas > .5
-- and wait_class = 'CPU'
-- and wait_class like '%I/O%'
-- and event_rank in (1,2,3)
ORDER BY snap_id DESC)
where rownum < 21
ORDER BY snap_id, event_rank ASC;

exit
