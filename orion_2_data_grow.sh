# This script grows the data in the iosaturationtoolkit table to over 32GB
(( n=0 ))
while (( n<15 ));do
(( n=n+1 ))
sqlplus -s /NOLOG <<! &
connect oracle/oracle;
set timing on
set time on
alter session enable parallel dml;
insert /*+ APPEND */ into iosaturationtoolkit select * from iosaturationtoolkit;
commit;
exit;
!
wait
done
wait

