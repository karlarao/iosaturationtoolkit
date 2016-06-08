# you may run this as...........  
# while : ; do sh px.sh ; echo "---" ; sleep 60; done
# but I usually execute it periodically
#
export DATE=$(date +%Y%m%d%H%M%S%N)

sqlplus -s /NOLOG <<! &
connect oracle/oracle;
set timing on
set echo on
spool px-$ORACLE_SID-$DATE.log
@px.sql
spool off
exit;
!
