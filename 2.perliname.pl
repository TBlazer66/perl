#!/usr/bin/perl
use strict;
use warnings;
use feature qw/say/;


my $isotime = MungeTimeString();
say "$isotime";
sub MungeTimeString {
my @t = localtime time;
sprintf "%02d-%02d-%02d_%04d-%02d-%02d", @t[2,1,0], 1900+$t[5], 1+$t[4], $t[3]
}



