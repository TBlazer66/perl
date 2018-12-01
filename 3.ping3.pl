#!/usr/bin/perl -w
use 5.011;
use Path::Tiny;
use POSIX qw(strftime);

# initialization that must precede main data structure
# User: enter a subdirectory you would like to create
#       enter a subdirectory of this^^^ for output

my $ts = "template_stuff";
my $output = "translations";

## turning things to Path::Tiny
my $abs   = path(__FILE__)->absolute;
my $path1 = Path::Tiny->cwd;
my $path2 = path( $path1, $ts );
say "abs is $abs";
say "path1 is $path1";
say "path2 is $path2";
print "This script will build the above path2. Proceed? (y|n)";

my $prompt = <STDIN>;
chomp $prompt;
die unless ( $prompt eq  "y" );
my $template_file = "1.monk.tmpl";
my $abs_to_template = path( $path2, $template_file )->touchpath;
my $string1 = '<{$symbol}></{$symbol}>';
my $return5 = $abs_to_template->spew_utf8($string1);
say "return5 is $return5";

# script params
my %vars = (
  monk_tags    => path( $path2, $template_file  ),
  translations => path( $path2, $output ),
  book         => 'monastery tags ',
);

my $rvars   = \%vars;
my $return1 = write_monk_tags($rvars);
say "return1 is $return1";
my $munge = strftime( "%d-%m-%Y-%H-%M-%S", localtime );
$munge .= ".monk.txt";

# use Path::Tiny to create and write to a text in relevant directory
my $save_file = path( $vars{$output}, $munge )->touchpath;
my $return2 = $save_file->spew_utf8($return1);
say "return2 is $return2";

## ping a few sites and add it to this log; append output
# keep time

my $start = time;

my $return3 = ping_sites($save_file);
say "return3 is $return3";
say time-$start, "seconds elapsed during pinging";

say "created file $save_file";
system("gedit $save_file &");

sub ping_sites {

  use 5.011;
use Path::Tiny;

my $outfile = shift;

for my $dest ('www.google.com', 'www.perlmonks.org', 'microsoft.com', 'foo.bar') { 
    system ("ping -nqc1 -w 3 -W 3 $dest >> $outfile") and
        print "### $dest is unreachable\n";
}   
return "done with pinging";
}

sub write_monk_tags {
  use warnings;
  use 5.011;
  use Text::Template;

  my $rvars = shift;
  my %vars  = %$rvars;

  my $body     = $vars{"monk_tags"};
  my $template = Text::Template->new(
    ENCODING => 'utf8',
    SOURCE   => "$body",
  ) or die "Couldn't construct template: $!";
  my $return     = "$vars{\"book\"}\n";
  # User: change these quoted values for different order or tags
  my @buchstaben = qw/i p c readmore b/;
  for my $i (@buchstaben) {
    $vars{"symbol"} = $i;
    print "How many $i tag pairs would you like?: ";
    my $prompt = <STDIN>;
    chomp $prompt;
    if ( $prompt lt 1 ) {
      $prompt = 0;
    }
    while ( $prompt gt 0 ) {
      my $result = $template->fill_in( HASH => \%vars );
      $return = $return . $result;
      --$prompt;
    }
  }
  return $return;
}
__END__ 
