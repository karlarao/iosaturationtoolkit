# This script creates the user oracle and the table iosaturationtoolkit.
sqlplus /nolog<<EOF
connect / as sysdba
--drop user oracle cascade;

create bigfile tablespace ts_iosaturationtoolkit;

create user oracle identified by oracle;
grant dba to oracle;
alter user oracle default tablespace ts_iosaturationtoolkit;
alter user oracle temporary tablespace temp;

connect oracle/oracle
create table iosaturationtoolkit tablespace ts_iosaturationtoolkit parallel nologging as select * from sys.dba_objects where rownum <= 10000;
commit;
exit
EOF

