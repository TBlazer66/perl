#!/bin/bash

# $1 to be cloned with $2 as basename

#munge new file, no clobber
new_file="1.$2"
cp -n $1 $new_file
chmod +x $new_file
ls -lh $new_file
gedit $new_file
