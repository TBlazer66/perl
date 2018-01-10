#!/usr/bin/perl -w
use strict;
use 5.010;
use Cwd;
use Path::Class;
use File::Copy;
use File::Basename;
use File::Find;
use File::Slurp qw(read_dir);
#  This script clones the template directory in $1 to $2.
#  Some names need munging.
#  $from is a populated child directory; $to is child dir to be created.  $pop is the folder with the data.
my ( $from, $to, $pop ) = @ARGV;
my $ts      = "template_stuff";
my $current = cwd;
# choose good lexical variable for directory list: @a.
say "-------------";
my $rd2 = dir($current);
my @a   = $rd2->dir_list();
say "a is @a";
say "-------------";
say "making directories";
# make root directory of clone:
my $rd1 = dir( @a, $to );
my $srd1 = $rd1->stringify;
mkdir $srd1 or warn "couldn't make $srd1: $!\n";
say "srd1 is $srd1";
# define the paths within the target directory:
my $rd3 = dir( @a, $to, $ts );
my $srd3 = $rd3->stringify;
mkdir $srd3 or warn "couldn't make $srd3: $!\n";
#say "srd3 is $srd3";
# stringify $from template directory:
my $rd6 = dir( @a, $from, $ts );
my $srd6 = $rd6->stringify;
say "srd6 is $srd6";
# copy files:
opendir my $eh, $srd6 or die "dead  $!\n";
while ( defined( $_ = readdir($eh) ) ) {
    if (m/(txt|pm|css|tmpl)$/) {
        say "matching is $_";
        $a = file( $srd6, $_ );
        #say "a is $a";
        $b = file( $srd3, $_ );
        #say "b is $b";
        copy( $a, $b );
    }
}
# copy css file to template with munged name
opendir my $fh, $srd6 or die "dead  $!\n";
while ( defined( $_ = readdir($fh) ) ) {
    if (m/^$from(\d*)\.css$/) {
        say "matching is $_";
        say "dollar one is $1";
        $a = file( $srd6, $_ );
        say "a is $a";
        my $munge = $to . $1 . ".css";
        $b = file( $srd3, $munge );
        say "b is $b";
        copy( $a, $b );
    }
}
closedir $fh;
my $rd7 = dir( @a, $from );
my $srd7 = $rd7->stringify;
say "srd7 is $srd7";
my @matching;
opendir my $dh, $srd7 or die "dead $!\n";
while ( defined( $_ = readdir($dh) ) ) {
    if (m/$from(\d*)\.pl$/i) {
        push @matching, $_;
    }
}
closedir $dh;
@matching = sort @matching;
say "matched is @matching";
my $winner  = pop @matching;
my $newfile = "${to}1.pl";
my $a       = file( $srd7, $winner );
print "a is $a\n";
my $b = file( $srd1, $newfile );
print "b is $b\n";
copy( $a, $b );
say "end of clone";
say "addressing pop";

#declare directories for this template
my @dirs = qw /aimages captions ruscaptions/;
#say "dirs are @dirs";
while (@dirs) {
    my $dir = shift @dirs;
    say "dir is $dir";
    my $rd4 = dir( @a, $pop, $ts, $dir );
    my $srd4 = $rd4->stringify;
    say "bla vlab $srd4";
    my $rd5 = dir( @a, $to, $ts, $dir );
    my $srd5 = $rd5->stringify;
    #say "srd5 is $srd5";
    mkdir $srd5 or warn "couldn't make $srd5: $!\n";
    opendir my $gh, $srd4 or warn "dir not there  $!\n";
    while ( defined( $_ = readdir($gh) ) ) {
        next if -d $_;
        next if $_ =~ /~$/;
        say "matching is $_";
        $a = file( $srd4, $_ );
        #say "a is $a";
        $b = file( $srd5, $_ );
        #say "b is $b";
        copy( $a, $b );
    }
    closedir $gh;
}

