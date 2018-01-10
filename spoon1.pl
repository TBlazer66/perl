#!/usr/bin/perl -w
use strict;
use 5.010;
use lib "template_stuff";
use html3;
use nibley1;
use utils1;
use Cwd;
use File::Basename; 
use Net::SFTP::Foreign;
use Path::Class;
use File::Slurp;
use File::Spec;



# initializations that must precede main data structure
my $fspecfile = File::Spec->rel2abs(__FILE__);
my $ts = "template_stuff";
my $images = "aimages";
my $captions = "captions";
my $ruscaptions = "ruscaptions";
my $bom = "bom";
my $current = cwd; 
my $rd1 = dir($current);
my @a = $rd1->dir_list();
my $srd1 = $rd1->stringify;
my $title = $rd1->basename;
say "title is $title";

my $rd2 = dir(@a,$ts,$images);
my $to_images = $rd2->stringify;
my $rd3 = dir(@a,$ts,$captions);
my $to_captions = $rd3->stringify;
my $rd4 = dir(@a,$ts,$ruscaptions);
my $rus_captions = $rd4->stringify;
my $rd5 = dir(@a,$ts,$bom);
my $bom_dir = $rd5->stringify;

# page params
my %vars = (
   title => $title,
   headline => undef,
   place => 'Vancouver',
   css_file => "${title}1.css",
   header => file($ts,"hc_input2.txt"),
   footer => file($ts,"footer_center3.txt"),
   css_local => file($ts,"${title}1.css"),
   body => file($ts,"rebus4.tmpl"),
   print_script => "1",
   code_tmpl=> file(@a,$ts,"code2.tmpl"), 
   oitop=> file($ts,"oitop.txt"),  
   oibottom=> file($ts,"oibottom.txt"), 
   to_images => $to_images,
   eng_captions => $to_captions,
   rus_captions =>  $rus_captions,
   bottom => file($ts,"bottom1.txt"),
   words => file($bom_dir, "words1.txt"),
   subs  => file($bom_dir, "substitutions1.txt"),
   source => file($bom_dir, "jacob1.txt"),
   book => 'A',
   chapter => 'Proposition',
   path => $to_captions,
   print_module => 0,
   script_file =>  $fspecfile,
   module_tmpl=> file(@a,$ts,"code3.tmpl"), 
        );
#create html page
my $rvars = \%vars;
my $sftp = get_ftp_object();
say "object created, back in main";
my $html_file = get_html_filename($sftp);
my $fh = create_html_file ($html_file);
my $remote_dir = $html_file;
$remote_dir =~ s/\.html$//;
say "remote_dir is $remote_dir";
$vars{remote_dir}= $remote_dir;
# create header
my $rhdr = write_header($rvars);

print $fh $$rhdr;

# text_to_captions($rvars);
my $refc = get_content($rvars);
my @AoA = @$refc;

print_aoa($refc);
my $body = write_body($rvars, $refc);
print $fh $$body;
my $rftr = write_footer($rvars);
print $fh $$rftr;

if ($vars{"print_script"}) {
  my $script = write_script($rvars);
  print $fh $$script;
}
if ($vars{"print_module"}) {
  my $module = write_module($rvars);
  print $fh $$module;
}
my $rhbt = write_bottom($rvars);
print $fh $$rhbt;
close $fh;
#load html file to server
$sftp->setcwd("/pages") or warn "cwd failed $!\n";
$sftp->put($html_file) or die "put failed $!\n";
#load css file to server
$sftp->setcwd("/css") or warn "cwd failed $@\n";
my $path3 = file(@a, $vars{"css_local"});
my $remote_css = $vars{"css_file"};
$sftp->put("$path3", $remote_css) or warn "put failed $@\n";
# load images
#$sftp->binary or warn "binary failed$!\n";
$sftp->setcwd("/images") or warn "cwd failed $!\n";
$sftp->mkdir($remote_dir) or warn "cwd failed $!\n";
$sftp->setcwd($remote_dir)
      or warn "Cannot change working directory ", $sftp->message;
for my $i ( 0 .. $#AoA ) {
   my $a = file(@a,$ts,$images,$AoA[$i][0]);
   my $sa = $a->stringify;  
   my $b = file($AoA[$i][0]);
   my $sb = $b->stringify;
   $sftp->put($sa, $sb) or warn "put failed $@\n";
   }
undef $sftp;
say "new file is $html_file";
__END__ 

