#!/usr/bin/perl
use strict;
use warnings;
use feature qw/say/;


my $isotime = GiveTimeString();
say Unique_node_name("$isotime");


sub GiveTimeString {
my @t = localtime time;
sprintf "%04d-%02d-%02d_%02d-%02d-%02d", 1900+$t[5], 1+$t[4], @t[3,2,1,0]
}

#   Returns a unique node name
sub Unique_node_name {
return $_[0] unless -e $_[0];
(my $i = $_[0]) =~s/\/*$//;
my ($dir,$node) = $i =~/^(.*?)([^\/]*)\/?$/;
$dir =~s/\/*$//;
$i=1; while (-e "$dir/$i.$node") {$i++}
"$dir/$i.$node"
}

