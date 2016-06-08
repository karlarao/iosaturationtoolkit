fuser -k collectl-all.txt collectl-cpuverbose.txt collectl-ioverbose.txt &> /dev/null
mkdir testcases
mv collectl*txt testcases
mv all_nodes_full_table_scan_* testcases
mv px*log testcases
mv gettop* testcases
