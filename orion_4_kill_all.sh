# by Randy Johnson
#!/bin/bash

ps -ef | grep pmon | grep -v grep | grep -v perl | grep -v ASM | grep -v DBFS |\
while read PMON; do
   INST=`echo $PMON | awk {' print $8 '} | cut -f3 -d_`
  echo $INST

  sqlplus -s /nolog <<-EOF
  connect / as sysdba
  set head off
  set lines 200
  select 'Connected to: '|| INSTANCE_NAME from v\$instance;
  spool TERMINATE_SESSIONS.SQL
  SELECT 'alter system disconnect session '''||sid||','||serial#||''''||' post_transaction;'
    FROM v\$session WHERE username is not null and username not in ('SYS','SYSTEM','DBSNMP','SYSMAN');
  spool off
  set echo on
  set feedback on
EOF

done
