-- Karl Arao, Oracle ACE (bit.ly/karlarao), OCP-DBA, RHCE
-- IO saturation toolkit

###################################################
SECTION 1: THE PLAIN VANILLA IOSATURATION TOOLKIT
###################################################

1) You first need to execute the following to create and populate the table

        ./asmfree                 <-- checks ASM free space
        ./orion_1_create_table.sh <-- creates user oracle, tablespace ts_iosaturationtoolkit, and table iosaturationtoolkit
        ./orion_2_data_grow.sh    <-- populate the table iosaturationtoolkit up to 327680000 rows (34GB)
        ./orion_3_fts.sh          <-- execute this one time to get rid of delayed block cleanout

2) then execute this to drive the load 

        On a single database:
	   ./orion_3_ftsall.sh <number of sessions> 
	   example would be
	   ./orion_3_ftsall.sh 256 
	   will create 256 users doing parallel select
	   
	On multiple databases:
	   ./saturate <number of sessions> <database1> <number of sessions> <database2>
	   example would be 
	   ./saturate 4 dbm1 2 exadb1
	   will create 4 sessions on dbm1 and 2 sessions on exadb1 all doing parallel select
	
	**NOTE: If you have collectl (http://collectl.sourceforge.net) installed on your server
	        then remove the comments on the first few lines of orion_3_ftsall.sh and saturate scripts. 
	        This will run the collectl before spawning the sessions and spooling details on CPU, 
	        IO, and general server workload.  

3) then periodically you can execute this 

	./px.sh
	to know what are the px sessions are doing

4) to kill the sessions execute either of the following:
	orion_4_kill_all.sh    <-- will generate a script to kill all sessions from all DBs
	orion_4_kill_1_db.sh   <-- will generate a script to kill all sessions from the current DB

        as SYS execute the TERMINATE_SESSIONS.SQL

5) then package all the performance files to one directory "testcases", 
   you may rename this to a more descriptive name after packaging all the files

	./orion_5_cleanup.sh

Note the following: 
    * orion_3_ftsall.sh executes collectl to get the OS statistics during the run (see **NOTE above)
    * I usually do an AWR snapshot after killing all the sessions
          exec dbms_workload_repository.create_snapshot;
    * and restart the database after every load test run

So this script will drive your database IO, my objective on running this is to validate 
the orion runs and calibrate IO I did on the DB server.


###################################################
SECTION 2: THE EXADATA IORM TEST CASE SCRIPTS
###################################################

1) This assumes that you have already executed the SECTION 1 -> number1 

2) Since it's Exadata, the underlying disks doesn't show as presented on the compute nodes. 
   So edit the first few lines of orion_3_ftsall.sh and saturate scripts and comment out the 
   fuser and collectl section. 
   
3) Run the following scripts on separate terminal windows 

      ./smartscanloop (this calls the smartscan and get_smartscan scripts)

         **NOTE: There are three versions of the get_smartscan script:
             a) get_smartscan.advanced (DEFAULT) <- shows the Hierarchy of Exadata IO: (check here for more details http://goo.gl/YYlhI)
                                                       smartscan (MB/s) - cell physical IO bytes eligible for predicate offload
                                                       ic (MB/s)        - cell physical IO interconnect bytes
                                                       returned (MB/s)  - cell physical IO interconnect bytes returned by smart scan
                                                       latency          - cell smart table scan event latency milliseconds
                                                       aas              - cell smart table scan event Average Active Sessions
             b) get_smartscan.simple             <- only shows the SmartScan MB/s
                   To use the get_smartscan.simple do this:
                     - $ cp get_smartscan.simple get_smartscan
                     - then edit the smartscanloop -> remove the comment on the 1st line -> comment out 2nd line
             c) get_smartscan.nonexa
                   If you are interested to have the smartscanloop output on a non-Exa environment just do this:
                     - on each node do this if it's a non-Exa RAC
                         while : ; do ./get_smartscan.nonexa | grep "%" ; echo "--" ; sleep 2 ; done

      ./topevents (run this for each database)

      ./iombs (run this for each database)

4) Run the per-10secs-AWR-snap job

      edit the startjoball with the database names included on the IORM test case
      then execute
      ./startjoball (this calls the startawrschedulerjob script)

5) Then execute the saturate script to drive the load

      ./saturate <number of sessions> <database1> <number of sessions> <database2>
      example would be 
      ./saturate 4 dbm1 2 exadb1
      will create 4 sessions on dbm1 and 2 sessions on exadb1 all doing parallel select

6) Once the test case is done, run the following to stop the database jobs

      edit the stopjoball with the database names included on the IORM test case
      then execute
      ./stopjoball (this script calls the stopawrschedulerjob)
      
7) After the test case run execute the following to get the IO MBs rates and response times

      cat *log | grep benchmark

      Sample output below:
  
      benchmark ,instance       ,start            ,end              ,elapsed   ,MBs
      ----------,---------------,-----------------,-----------------,----------,-------
      benchmark ,dbm1           ,05/13/12 19:18:28,05/13/12 19:19:32,        64,    537
      benchmark ,dbm1           ,05/13/12 19:18:28,05/13/12 19:19:30,        62,    554
      benchmark ,dbm1           ,05/13/12 19:18:28,05/13/12 19:19:32,        63,    545
      benchmark ,dbm1           ,05/13/12 19:18:28,05/13/12 19:19:32,        64,    537
      benchmark ,exadb1         ,05/13/12 19:18:28,05/13/12 19:19:32,        64,    539
      benchmark ,exadb1         ,05/13/12 19:18:28,05/13/12 19:19:32,        64,    539


