#!/bin/bash
set -u
app=${0##*/}
trap_err() 
   {
      echo " $(caller) errexit on line $1 $BASH_COMMAND exit status=$2" >&2
   }
trap 'trap_err ${LINENO}  $?' ERR

pathto=/logs
timename=$(date +"%m-%d-%Y-%H-%M-%S")
out=$HOME$pathto/$timename.log

echo "basename dollar sign zero is" $app
echo "path is" $pathto
echo "Munged time is" $timename
echo "out fn is $out"
echo "Time is $timename " | tee -a "$out"

declare -ir SUCCESS=0
declare -ir E_FATAL=1
MINARGS=1          # Script requires min arguments
E_BADARGS=65

# Checks number of arguments.
if [ $# -lt $MINARGS ]; then
   echo "Not enough arguments."
   exit $E_BADARGS
fi  

FILE=$1

if [ ! -f $FILE ]; then
    echo "File \"$FILE\" does not exist."
    exit $E_BADARGS
fi


#get the first number from $1
c=$(expr "$1" : '\([0-9]*\).*$') 
echo $c
#integer addition
d=$(expr $c + 1)
echo $d

#munge new file, no clobber
q=${FILE#*.}
echo "q is $q"  | tee -a "$out"
s="$d.$q"
echo $s
cp -n "$FILE" "$s"
num=$(stat -c "%a" "$FILE")
echo "octal permissions are $num"

#new for zeit
mkdir a #How to handle this
cp -n "$FILE" "a/$FILE.bak"

gedit $s  && read -n 1
duration=$SECONDS

#done editing

   diff --normal "$FILE" "$s" > "$d.$q.dif"
     if [ $? -ne 0 ] ; then
       cat $d.$q.dif >> $out
       echo "hot damn"
      
     else
       echo "ain't nothing there"
     fi

ls -lh *"$q"* | tee -a "$out"
today=$(date +"%Y-%m-%d")
echo "today is $today" | tee -a "$out"

cat $s | tee -a "$out"

gedit $out
exit $SUCCESS
