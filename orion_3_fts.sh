# This is the main script 
export DATE=$(date +%Y%m%d%H%M%S%N)

sqlplus -s /NOLOG <<! &
connect oracle/oracle;
set timing off
set echo off
set lines 300
spool all_nodes_full_table_scan_$ORACLE_SID-$DATE.log  

col time1 new_value time1
col time2 new_value time2
col total_time new_value total_time
col mb_per_sec new_value mb_per_sec
col start_time new_value start_time 

select TO_CHAR(SYSDATE,'MM/DD/YY HH24:MI:SS') start_time from dual;
select to_char(sysdate, 'SSSSS') time1 from dual;
select count(*) from iosaturationtoolkit;
select to_char(sysdate, 'SSSSS') time2 from dual;
select &&time2 - &&time1 total_time from dual;

select (sum(s.bytes)/1024/1024)/(&&time2 - &&time1) mb_per_sec 
from sys.dba_segments s
where segment_name='IOSATURATIONTOOLKIT';

set colsep ','
col instname format a15
col MBs format 999990
col benchmark format a10
select 'benchmark' benchmark, '$ORACLE_SID' instname, '&&start_time' "START", TO_CHAR(SYSDATE,'MM/DD/YY HH24:MI:SS') "END", &&total_time elapsed, &&mb_per_sec "MBs" from dual;

undef time1
undef time2
spool off
exit;
!

