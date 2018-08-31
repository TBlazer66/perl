#!/usr/bin/perl -w
use strict;
use 5.010;
use lib "template_stuff";
use html5;
use nibley1;
use utils1;
use Net::SFTP::Foreign;
use Path::Tiny;
use utf8;
use open qw/:std :utf8/;
use Encode;
use URI::Escape;
use URL::Encode qw{ url_encode};
binmode STDOUT, ":utf8";

# initializations that must precede main data structure

my $ts          = "template_stuff";
my $images      = "aimages";
my $captions    = "captions";
my $ruscaptions = "ruscaptions";

## turning things to Path::Tiny

my $abs   = path(__FILE__)->absolute;
my $path1 = Path::Tiny->cwd;
my $title = $path1->basename;

## encode and decode
# reassign to original vars
my $encoded_path = url_encode($path1);
say "encoded path cyrillic is $encoded_path";
$path1 = Encode::decode( 'utf8', uri_unescape($encoded_path) );
my $encoded_title = url_encode($title);
say "encoded title cyrillic is $title";
$title = Encode::decode( 'utf8', uri_unescape($encoded_title) );
my $encoded_abs = url_encode($abs);
say "encoded path cyrillic is $encoded_abs";
$abs = Encode::decode( 'utf8', uri_unescape($encoded_abs) );
say "title is $title";
say "path1 is $path1";
say "abs is $abs";

# page params
my %vars = (
  title        => $title,
  headline     => undef,
  place        => 'Vancouver',
  base_url     => 'http://www.merrillpjensen.com',
  css_file     => "${title}1.css",
  header       => path( $path1, $ts, "hc_input2.txt" ),
  footer       => path( $path1, $ts, "footer_center3.txt" ),
  body         => path( $path1, $ts, "rebus5.tmpl" ),
  print_script => "1",
  code_tmpl    => path( $path1, $ts, "code2.tmpl" ),
  oitop        => path( $path1, "$ts", "oitop.txt" ),
  oibottom     => path( $path1, $ts, "oibottom.txt" ),
  to_images    => path( $path1, $ts, $images ),
  eng_captions => path( $path1, $ts, $captions ),
  rus_captions => path( $path1, $ts, $ruscaptions ),
  bottom       => path( $path1, $ts, "bottom1.txt" ),
  book         => 'Медитация на perlем',
  chapter      => '',
  print_module => 1,
  script_file  => $abs,
  module_tmpl  => path( $path1, "$ts", "code3.tmpl" ),
  server_dir   => 'perlmonks',
  image_dir    => 'pmimage',
);

#create html page
my $rvars = \%vars;

print_hash($rvars);

#my $sftp = get_ftp_object();
my $sftp = get_tiny();
say "object created, back in main";
my $html_file  = get_html_filename( $sftp, $rvars );
my $fh         = create_html_file($html_file);
my $remote_dir = $html_file;
$remote_dir =~ s/\.html$//;
say "remote_dir is $remote_dir";
$vars{remote_dir} = $remote_dir;

# create header
my $rhdr = write_header($rvars);
print $fh $$rhdr;
my $refc = get_content($rvars);
my @AoA  = @$refc;

#print_aoa($refc);
my $body = write_body( $rvars, $refc );
print $fh $$body;
my $rftr = write_footer($rvars);
print $fh $$rftr;
if ( $vars{"print_script"} ) {
  my $script = write_script($rvars);
  print $fh $$script;
}
if ( $vars{"print_module"} ) {
  my $module = write_module($rvars);
  print $fh $$module;
}
my $rhbt = write_bottom($rvars);
print $fh $$rhbt;
close $fh;

#load html file to server
my $server_dir = $vars{"server_dir"};
$sftp->mkdir("/$server_dir")  or warn "mkdir1 failed $!\n";
$sftp->setcwd("/$server_dir") or warn "setcwd1 failed $!\n";
$sftp->put($html_file)        or die "html put failed $!\n";

#load css file to server
$sftp->setcwd("/css") or warn "setcwd2 failed $@\n";
my $path3 = path( $path1, $ts, $vars{"css_file"} );
say "path3 is $path3";
my $remote_css = $vars{"css_file"};
$sftp->put( "$path3", $remote_css ) or warn "css put failed $@\n";

# upload images
my $image_dir = $vars{"image_dir"};
$sftp->mkdir("/$image_dir")  or warn "mkdir2 failed $!\n";
$sftp->setcwd("/$image_dir") or warn "setcwd2 failed $!\n";
$sftp->mkdir("$remote_dir")  or warn "mkdir3 failed $!\n";
$sftp->setcwd("$remote_dir") or warn "setcwd3 failed $!\n";
print $sftp->cwd(), "\n";

for my $i ( 0 .. $#AoA ) {
  my $a = path( $path1, $ts, $images, $AoA[$i][0] );
  say "a is $a";
  my $b = $a->basename;
  say "b is $b";
  $sftp->put( $a, $b ) or warn "AoA put failed $@\n";
}
undef $sftp;
say "new file is $html_file";
__END__ 

