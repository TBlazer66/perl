#!/bin/bash

# which bash version?

echo "The shebang is specifying bash"
if [ -z "${BASH_VERSION}" ]; then
        echo "Not using bash but dash"
else
        echo "Using bash ${BASH_VERSION}"
fi 
#get the the first number from $1
#c=$(("$1" : '\([0-9]*\).*$')) didn't work
c=$(expr "$1" : '\([0-9]*\).*$') 
echo $c
f=$1

#integer addition
d=$(expr $c + 1)
echo $d

#munge new file, no clobber
t="$d"
q=${f#*.}
s=$t.$q
echo $s
cp -n $f $s
chmod +x $s
ls -lh $s
gedit $s
