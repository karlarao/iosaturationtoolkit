# purpose: execute multiple SELECT count(*) on 1 database
# usage: sh orion_3_ftsall.sh 4
#
#fuser -k collectl-all.txt collectl-cpuverbose.txt collectl-ioverbose.txt &> /dev/null
#collectl --all -o T -o D >> collectl-all.txt 2> /dev/null &
#collectl -sc --verbose -o T -o D >> collectl-cpuverbose.txt 2> /dev/null &
#collectl -sD --verbose -o T -o D >> collectl-ioverbose.txt 2> /dev/null &

(( n=0 ))
while (( n<$1 ));do
(( n=n+1 ))
./orion_3_fts.sh &
done
