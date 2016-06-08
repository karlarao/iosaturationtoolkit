# purpose: driver to execute SELECT count(*) on multiple databases
# usage: sh orion_3_ftsallmulti.sh 4 dbm1
#
#fuser -k collectl-all.txt collectl-cpuverbose.txt collectl-ioverbose.txt &> /dev/null
#collectl --all -o T -o D >> collectl-all.txt 2> /dev/null &
#collectl -sc --verbose -o T -o D >> collectl-cpuverbose.txt 2> /dev/null &
#collectl -sD --verbose -o T -o D >> collectl-ioverbose.txt 2> /dev/null &

export ORACLE_SID=$2
export ORAENV_ASK=NO
. oraenv

(( n=0 ))
while (( n<$1 ));do
(( n=n+1 ))
./orion_3_fts.sh $1 $2 &
done
