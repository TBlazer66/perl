#!/usr/bin/perl -w
use 5.011;
use utf8;
use open qw/:std :utf8/;
use Path::Tiny;
use Encode;
use open OUT => ':encoding(UTF-8)', ':std';

#  This script clones the template directory in $1 to $2.
#  Some names need munging.
#  $from is a populated child directory; $to is child dir to be created.  $pop is the folder with the data.
######
## enabling cyrillic
## decode argv and current

say "argv is @ARGV";

foreach (@ARGV)
{
  say "before decode is $_";
  $_ = decode('UTF-8', $_);
  say "after decode is $_";
}

my ( $from, $to, $pop ) = @ARGV;

my $current = Path::Tiny->cwd;
$current = decode('UTF-8', $current);
say "current is $current";
say "-------------";
say "making directories";

# define the paths within the target directory:
my $ts = "template_stuff";
my $abs_to = path( $current, $to, $ts );
$abs_to->mkpath;
say "abs to template is $abs_to";

# $from template directory:
my $abs_from = path( $current, $from, $ts );
say "string abs from is $abs_from";
say "-------------";
say "copying files";

foreach my $child ( $abs_from->children(qr/\.(txt|pm|tmpl|pl|sh)$/) ) {
  next unless $child->is_file;
  my $base = $child->basename;
  #say "base is $base";

  #syntax is from to to
  my $return = path($child)->copy( $abs_to, $base );

  if ( $base =~ m/\.(pl|sh)$/ ) {
    $return->chmod(0755);
  }

  say "return is $return";

}
say "-------------copy munged css file";


# copy css file to template with munged name
foreach my $child ( $abs_from->children ) {
  #say "child is $child";
  my $base = $child->basename;
  ### added to handle cyrillic
  my $base2 = decode('UTF-8', $base);
  #say "base2 is $base2";

  if ( $base2 =~ m/^$from(\d*)\.css$/ ) {

    #say "matching is $base";
    say "dollar one is $1";
    my $munge = $to . "1" . ".css";
    say "munge is $munge";
    my $name = path( $abs_to, $munge );
    say "name is $name";

    #syntax is from to to
    my $return = path( $abs_from, $base2 )->copy($name);
    say "return2 is $return";

  }
}

## munge and copy executable, change permissions
say "-------------munge, copy executable";
my $path3 = path( $current, $from );
say "path3 is $path3";
my @matching;
foreach my $child ( $path3->children ) {
  say "child is $child";
  my $base = $child->basename;
  ### added to handle cyrillic
  my $base2 = decode('UTF-8', $base);
  say "base2 is $base2";
  say "from is $from";
  if ( $base2 =~ m/^$from(\d*)\.pl$/ ) {
    say "matching is $base2";
    say "dollar one is $1";
push @matching, $base2;
@matching = sort @matching;
say "matched is @matching";
my $winner  = pop @matching;
say "winner is $winner";
    my $munge = $to . "1" . ".pl";
    say "munge is $munge";
    my $path4 = path( $current, $to, $munge );
    say "path4 is $path4";
    #syntax is from to to
    my $return = path( $path3, $winner )->copy($path4);
    $return->chmod(0755);
    say "return is $return";
  }
}


my $abs_pop = path( $current, $pop, $ts );
say "string abs pop is $abs_pop";
my $string_pop = "$abs_pop";

foreach my $child ( $abs_pop->children ) {
  next unless $child->is_dir;

  say "e is $child";
  my $base_dir = $child->basename;
  say "base dir is $base_dir";
  my @dirs = path( $current, $to, $ts, $base_dir )->mkpath;
  say "dirs are @dirs";
  my $pop_from = $child;
  next if ( $child =~ m/logs/ );
  foreach my $pchild ( $pop_from->children ) {
    say "default is $pchild\n";
    my $base = $pchild->basename;
    say "base is $base";
    my $to_name = path( @dirs, $base );
    say "to name is $to_name";
    my $return4 = path($pchild)->copy($to_name);
    say "return4 is $return4";

  }

}
my $exec_path = path( $current, $to );
my $return5 = chdir($exec_path);
say "return5 is $return5";
system("pwd ");
system("ls ");

#system ("./$newfile ");
