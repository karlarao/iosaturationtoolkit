
SET SERVEROUTPUT ON
DECLARE
  l_max_iops        PLS_INTEGER;
  l_max_mbps        PLS_INTEGER;
  l_actual_latency  PLS_INTEGER;
BEGIN
  DBMS_RESOURCE_MANAGER.calibrate_io (
    num_physical_disks => 8,
    max_latency        => 20,
    max_iops           => l_max_iops,
    max_mbps           => l_max_mbps,
    actual_latency     => l_actual_latency);
 
  DBMS_OUTPUT.put_line ('l_max_iops       = ' || l_max_iops);
  DBMS_OUTPUT.put_line ('l_max_mbps       = ' || l_max_mbps);
  DBMS_OUTPUT.put_line ('l_actual_latency = ' || l_actual_latency);
END;
/


SELECT d.name,
       i.asynch_io
FROM   v$datafile d,
       v$iostat_file i
WHERE  d.file# = i.file_no
AND    i.filetype_name  = 'Data File';

SELECT * FROM v$io_calibration_status;

SET LINESIZE 150
COLUMN start_time FORMAT A30
COLUMN end_time FORMAT A30
SELECT * FROM dba_rsrc_io_calibrate;