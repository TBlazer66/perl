#!/bin/bash

_app=$(basename $0)
_path_to=/home/bob/Desktop/perl/logs/dhooks/
_perliname=`perl 1.perliname.pl`
_out_fn=$_path_to$_perliname.log


echo "basename dollar sign zero is" $_app
echo "path is" $_path_to
echo $_perliname
echo "Time is $_perliname " >> $_out_fn

nmcli network off
ifaceinfo >> $_out_fn
netinfo  >> $_out_fn
env | sort >> $_out_fn
nmcli network on
sleep 40s
journalctl --since "1 minute ago"  >> $_out_fn
ifaceinfo >> $_out_fn
netinfo  >> $_out_fn
exit
#*******************end**************************
