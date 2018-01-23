#!/bin/bash
#  
#  modified to make arbitrary path explicit
#  and more verbose
#  keep a log named by time stamp
export PATH=:/usr/local/sbin:/usr/sbin:/sbin:/usr/local/bin:/usr/bin:/bin
export pager=less 
set -u
app=${0##*/}
pathto=/logs
timename=$(date +"%m-%d-%Y_%H-%M-%S")
out=$HOME$pathto/$timename.log

if [ 1 -eq 0 ] ; then
echo "basename dollar sign zero is" $app
echo "path is" $pathto
echo "Munged time is" $timename
echo "out fn is $out"
echo "Time is $timename " > "$out"
fi # end if [ 1 -eq 0 ] 

declare -ir SUCCESS=0
declare -ir E_FATAL=1

  if [ -z "EDITOR" ] ; then    # set default file editor
     echo "export from perl didn't work" | tee -a "$out"
     EDITOR=gedit
    fi

echo "mv all in Camera" | tee -a "$out"
gedit $out && read -n 1

pwd | tee -a "$out"
ls -1v | tee -a "$out"

# get fresh directory from perl to copy images to
perl_dir=$(perl /home/bob/1.scripts/3.maus | tail -1)
echo "perl dir is $perl_dir"
bash_dir=/home/bob/Pictures/$perl_dir
mv {,.[^.]}* $bash_dir | tee -a "$out"
cd $bash_dir
pwd | tee -a "$out"
ls -1v | tee -a "$out"


echo "behold your log and journal; stop timer and cat app" | tee -a "$out"
journalctl --since "30 seconds ago"  | tee -a "$out"
echo "dollar zero is $0" | tee -a "$out"
cat $0 | tee -a "$out"
$EDITOR $out & 
read -n 1
echo "duration=$SECONDS"  | tee -a "$out"
date  | tee -a "$out"
exit $SUCCESS

