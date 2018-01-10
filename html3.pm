package html3;
require Exporter;
use config2;
use utils1;

our @ISA = qw(Exporter);
our @EXPORT = qw( 
  get_content  
  write_body  
  get_ftp_object  
  get_html_filename
  create_html_file 
  write_script
  write_bottom
  write_header
  write_footer
  write_module
);

sub get_content{
use 5.010;
use File::Basename;
use Cwd;
use HTML::FromText;
use File::Slurp;
use Path::Class;

my $rvars = shift;
my %vars = %$rvars;
my $refimg = get_images($rvars);
my $refcaps = get_eng_text($rvars);
my $refruscaps = get_rus_text($rvars);
my $aoa = [ $refimg, $refcaps, $refruscaps ];
my $b = invert_aoa($aoa);
return ($b);
}

sub get_images {
use strict;
use 5.010;
use File::Basename;
use Cwd;
use HTML::FromText;
use File::Slurp;
use Path::Class;

my $rvars = shift;
my %vars = %$rvars;
my $current = getcwd; 
my $rd2 = dir($current);
my @a = $rd2->dir_list();
my @filetypes = qw/jpg gif png jpeg GIF/;
my $pattern = join '|', map "($_)", @filetypes;
my @matching2;
opendir my $hh, $vars{to_images} or warn "warn  $!\n";
while (defined ($_ = readdir($hh))){
if ($_ =~ /($pattern)$/i) {
   push(@matching2, $_);
   }
}
#important to sort
@matching2 = sort @matching2;
return \@matching2;
}

sub get_eng_text {
use strict;
use 5.010;
use File::Basename;
use Cwd;
use HTML::FromText;
use File::Slurp;
use Path::Class;

my $rvars = shift;
my %vars = %$rvars;
my %content;
my $refc = \%content;
opendir my $eh, $vars{"eng_captions"} or die "dead  $!\n";
while (defined ($_ = readdir($eh))){
next if m/~$/;
next if -d;
if (m/txt$/){
   my $file = file($vars{"eng_captions"},$_);
   my $string = read_file($file);
   my $temp = text2html(
      $string,
      urls  => 1,
      email => 1,
      paras => 1,
     
   );
   # surround by divs
   my $oitop = read_file($vars{"oitop"});
   my $oibottom = read_file($vars{"oibottom"});
   my $text = $oitop.$temp.$oibottom;
   say "default is $_";
   $content{$_} = $text;
   }
}
closedir $eh;
#important to sort
my @return;
foreach my $key (sort keys %content) {
   
    push @return, $content{$key};
}

#say "return is @return";
return \@return;
}

sub write_body{
use strict;
use warnings;
use 5.010;
use Text::Template;
use Encode;

my $rvars = shift;
my $reftoAoA = shift;
my %vars = %$rvars;
my @AoA = @$reftoAoA;
my $body = $vars{"body"};
my $template = Text::Template->new(
    ENCODING => 'utf8',
    SOURCE => $body)
    or die "Couldn't construct template: $!";
my $return;
for my $i ( 0 .. $#AoA ){
$vars{"file"} = $AoA[$i][0];
$vars{"english"} = $AoA[$i][1];
my $ustring = $AoA[$i][2];
$ustring = decode_utf8( $ustring );
$vars{"russian"} = $ustring;
my $result = $template->fill_in(HASH => \%vars);
$return = $return.$result;
}
return \$return;
}

sub get_rus_text {
use 5.010;
use File::Basename;
use Cwd;
use HTML::FromText;
use File::Slurp;
use Path::Class;

my $rvars = shift;
my %vars = %$rvars;
my %content;
my $refc = \%content;
opendir my $eh, $vars{"rus_captions"} or die "dead  $!\n";
while (defined ($_ = readdir($eh))){
next if m/~$/;
next if -d;
if (m/txt$/){
   my $file = file($vars{"rus_captions"},$_);
   my $string = read_file($file);
   # surround by divs
   my $oitop = read_file($vars{"oitop"});
   my $oibottom = read_file($vars{"oibottom"});
   my $text = $oitop.$string.$oibottom;
   $content{$_} = $text;
   }
}
closedir $eh;
#important to sort
my @return;
foreach my $key (sort keys %content) {
    print $content{$key} . "\n";
    push @return, $content{$key};
}
return \@return;
}

sub write_bottom  {
use strict;
use Text::Template;
my ($rvars) = shift;
my %vars = %$rvars;
my $footer = $vars{"bottom"};
my $template = Text::Template->new(SOURCE => $footer)
          or die "Couldn't construct template: $!";
my $result = $template->fill_in(HASH => $rvars);
return \$result;
}


sub get_html_filename{
use Net::SFTP::Foreign;
use File::Basename;
use Cwd;
use 5.01;

my $sftp = shift;
# get working directory
my $dir = getcwd();
my $word = basename($dir);
say "word is $word";
# get files from /pages
my $ls = $sftp->ls("/pages", wanted => qr/$word/)     
or warn "unable to retrieve ".$sftp->error;
print "$_->{filename}\n" for (@$ls);

my @remote_files = map  { $_->{filename} } @$ls;
say "files are @remote_files";
my $rref = \@remote_files;
my $filetype = "html";
my $old_num = highest_number($rref, $filetype, $word);
print "old num is $old_num\n";
my $new_num = $old_num + 1;
my $html_file = $word.$new_num.'.'.$filetype;
return $html_file;
}

sub get_ftp_object{
use strict;
use Net::SFTP::Foreign;
use 5.01;
my $sub_hash = "my_sftp";
my $domain = $config{$sub_hash}->{'domain'};
my $username = $config{$sub_hash}->{'username'};
my $password = $config{$sub_hash}->{'password'};
my $port = 22;
#dial up the server

say "values are $domain $username $password";
my $sftp = Net::SFTP::Foreign->new( $domain, user => $username,
port => $port, password => $password)
  or die "Can't connect: $!\n";
  return $sftp;
}


sub create_html_file {
my  $html_file = shift;
open( my $fh, ">>:encoding(UTF-8)", $html_file )
  or die("Can't open $html_file for writing: $!");
  return $fh;
  }

sub write_header {
use Text::Template;
my $rvars = shift;
my %vars = %$rvars;
# get time
my $now_string = localtime;
$vars{"date"} = $now_string;

my $headline = join(' ',$vars{"book"},$vars{"chapter"});
$vars{"headline"} = $headline;
my $header = $vars{"header"};
my $template2 = Text::Template->new(SOURCE => $header)
          or die "Couldn't construct template: $!";
my $result2 = $template2->fill_in(HASH => \%vars);
return \$result2;
}

sub write_footer  {
use Text::Template;
my ($rvars) = shift;
my %vars = %$rvars;
my $footer = $vars{"footer"};
my $template = Text::Template->new(SOURCE => $footer)
          or die "Couldn't construct template: $!";
my $result = $template->fill_in(HASH => $rvars);
return \$result;
}

sub write_script  {
use Text::Template;
use File::Slurp;
use 5.010;
my ($rvars) = shift;
my %vars = %$rvars;
my $tmpl = $vars{"code_tmpl"};
say "tmpl is $tmpl";
my $file = $vars{"script_file"};
my $text = read_file($file);
my %data = ('script', $text);
my $template = Text::Template->new(SOURCE => $tmpl)
          or die "Couldn't construct template: $!";
my $result = $template->fill_in(HASH =>\%data);
return \$result;
}

sub write_module  {
use 5.010;
use File::Spec;
use File::Slurp;

my ($rvars) = shift;
my %vars = %$rvars;
my $tmpl = $vars{"module_tmpl"};
say "tmpl is $tmpl";
my %data = ('module', $text);
my $template = Text::Template->new(SOURCE => $tmpl)
          or die "Couldn't construct template: $!";
my $result = $template->fill_in(HASH =>\%data);
return \$result;

my $fspecfile = File::Spec->rel2abs(__FILE__);
my $text1 = read_file($fspecfile);
return \$text1;
}


1;
