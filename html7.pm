package html7;
require Exporter;

use utils1;

our @ISA    = qw(Exporter);
our @EXPORT = qw(
  get_content
  write_body
  get_html_filename
  create_html_file
  write_script
  write_bottom
  write_header
  write_footer
  write_module
  get_tiny
  create_page
  put_page
);

sub create_page {

  use 5.011;
  use trans1;
  use Net::SFTP::Foreign;

  use Encode;
  use open OUT => ':encoding(UTF-8)', ':std';

  #create html page
  my $rvars = shift;
  my %vars  = %$rvars;

  my $sftp = get_tiny();
  say "object created, back with caller";
  my $html_file = get_html_filename( $sftp, $rvars );
  $vars{html_file} = $html_file;
  print "Make rus captions(y/n)?: ";
  my $prompt1 = <STDIN>;
  chomp $prompt1;
  if ( $prompt1 eq ( "y" | "Y" ) ) {
    my $ref_cap = make_russian_captions($rvars);
  }
  my $fh         = create_html_file($html_file);
  my $remote_dir = $html_file;
  $remote_dir =~ s/\.html$//;
  say "remote_dir is $remote_dir";
  $vars{remote_dir} = $remote_dir;
  $rvars = \%vars;  ## why so necessary?

  # create header
  my $rhdr = write_header($rvars);
  print $fh $$rhdr;
  $vars{refc} = get_content($rvars);

  #print_aoa($refc);
  my $body = write_body( $rvars, $vars{refc} );
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

  print "Put file to server(y/n)?: ";
  my $prompt2 = <STDIN>;
  chomp $prompt2;
  if ( $prompt2 eq ( "y" | "Y" ) ) {
    put_page( $sftp, $rvars );
  }
  return $html_file;
}

sub put_page {

  use 5.011;
  #use html6;
  #use nibley1;
  use utils1;
  use Net::SFTP::Foreign;
  use Encode;
  use open OUT => ':encoding(UTF-8)', ':std';
  use Data::Dumper;

  my ( $sftp, $rvars ) = (@_);
  my %vars = %$rvars;

  #load html file to server
  my $server_dir = $vars{"server_dir"};
  say "server dir is $server_dir";
  $sftp->mkdir("/$server_dir")   or warn "mkdir1 failed $!\n";
  $sftp->setcwd("/$server_dir")  or warn "setcwd1 failed $!\n";
  $sftp->put( $vars{html_file} ) or die "html put failed $!\n";

  #load css file to server
  $sftp->setcwd("/css") or warn "setcwd2 failed $@\n";
  my $path3 = path( $vars{css_path}, $vars{"css_file"} );
  say "path3 is $path3";
  my $remote_css = $vars{"css_file"};
  $sftp->put( "$path3", $remote_css ) or warn "css put failed $@\n";

  # upload images
  my $image_dir = $vars{"image_dir"};
  $sftp->mkdir("/$image_dir")        or warn "mkdir2 failed $!\n";
  $sftp->setcwd("/$image_dir")       or warn "setcwd2 failed $!\n";
  $sftp->mkdir( $vars{remote_dir} )  or warn "mkdir3 failed $!\n";
  $sftp->setcwd( $vars{remote_dir} ) or warn "setcwd3 failed $!\n";
  print $sftp->cwd(), "\n";

  #print Dumper $rvars;
  my $ref_content = $vars{refc};
  my @AoA         = @$ref_content;

  for my $i ( 0 .. $#AoA ) {
    my $a = path( $vars{to_images}, $AoA[$i][0] );
    say "a is $a";
    my $b = $a->basename;
    say "b is $b";
    $sftp->put( $a, $b ) or warn "AoA put failed $@\n";
  }
  undef $sftp;

  return "nothing";

}

sub get_content {
  use 5.010;

  my $rvars      = shift;
  my %vars       = %$rvars;
  my $refimg     = get_images($rvars);
  my $refcaps    = get_utf8_text( $rvars, $vars{"eng_captions"} );
  my $refruscaps = get_utf8_text( $rvars, $vars{"rus_captions"} );
  my $aoa        = [ $refimg, $refcaps, $refruscaps ];
  my $b          = invert_aoa($aoa);
  return ($b);
}

sub get_images {
  use 5.011;

  my $rvars     = shift;
  my %vars      = %$rvars;
  my @filetypes = qw/jpg gif png jpeg GIF/;
  my $pattern   = join '|', map "($_)", @filetypes;
  my @matching2;
  opendir my $hh, $vars{to_images} or warn "warn  $!\n";
  while ( defined( $_ = readdir($hh) ) ) {
    if ( $_ =~ /($pattern)$/i ) {
      push( @matching2, $_ );
    }
  }

  #important to sort
  @matching2 = sort @matching2;
  return \@matching2;
}

sub get_utf8_text {
  use 5.010;
  use HTML::FromText;
  use Path::Tiny;
  use utf8;
  use open qw/:std :utf8/;

### Passing in
  #reference to main data structure and directory for captions
  my ( $rvars, $dir ) = (@_);
  my %vars = %$rvars;

  say "dir is $dir";
  opendir my $eh, $dir or warn "can't open dir for utf8 captions  $!\n";
  while ( defined( $_ = readdir($eh) ) ) {
    next if m/~$/;
    next if -d;
    if (m/txt$/) {
      my $file = path( $dir, $_ );
      my $guts = $file->slurp_utf8;
      my $temp = text2html(
        $guts,
        urls  => 1,
        email => 1,
        paras => 1,

      );

      # surround by divs

      my $oitop    = $vars{"oitop"};
      my $oben     = $oitop->slurp_utf8;
      my $oibottom = $vars{"oibottom"};
      my $unten    = $oibottom->slurp_utf8;
      my $text     = $oben . $temp . $unten;

      #say "text is $text";
      $content{$_} = $text;
    }
  }
  closedir $eh;

  #important to sort
  my @return;
  foreach my $key ( sort keys %content ) {

    #print $content{$key} . "\n";
    push @return, $content{$key};
  }
  return \@return;
}

sub write_body {
  use warnings;
  use 5.011;
  use Text::Template;
  use Encode;

  my $rvars    = shift;
  my $reftoAoA = shift;
  my %vars     = %$rvars;
  my @AoA      = @$reftoAoA;
  my $body     = $vars{"body"};
  my $template = Text::Template->new(
    ENCODING => 'utf8',
    SOURCE   => $body
  ) or die "Couldn't construct template: $!";
  my $return;

  for my $i ( 0 .. $#AoA ) {
    $vars{"file"}    = $AoA[$i][0];
    $vars{"english"} = $AoA[$i][1];
    my $ustring = $AoA[$i][2];
    $vars{"russian"} = $ustring;
    my $result = $template->fill_in( HASH => \%vars );
    $return = $return . $result;
  }
  return \$return;
}

sub write_bottom {
  use strict;
  use Text::Template;
  my ($rvars) = shift;
  my %vars    = %$rvars;
  my $footer  = $vars{"bottom"};
  my $template = Text::Template->new( SOURCE => $footer )
    or die "Couldn't construct template: $!";
  my $result = $template->fill_in( HASH => $rvars );
  return \$result;
}

sub get_html_filename {
  use Net::SFTP::Foreign;
  use File::Basename;
  use Cwd;
  use 5.01;
  binmode STDOUT, ":utf8";

  my ( $sftp, $rvars ) = (@_);
  my %vars = %$rvars;

  # get working directory
  my $word = $vars{"title"};
  say "word is $word";

  # get files from /pages
  my $dir2 = $vars{"server_dir"};
  say "dir2 is $dir2";
  my $ls = $sftp->ls( "/$dir2", wanted => qr/$word/ )
    or warn "unable to retrieve " . $sftp->error;
  print "$_->{filename}\n" for (@$ls);

  my @remote_files = map { $_->{filename} } @$ls;
  say "files are @remote_files";
  my $rref     = \@remote_files;
  my $filetype = "html";
  my $old_num  = highest_number( $rref, $filetype, $word );
  print "old num is $old_num\n";
  my $new_num   = $old_num + 1;
  my $html_file = $word . $new_num . '.' . $filetype;
  return $html_file;
}



sub create_html_file {
  my $html_file = shift;
  open( my $fh, ">>:encoding(UTF-8)", $html_file )
    or die("Can't open $html_file for writing: $!");
  return $fh;
}

sub write_header {
  use Text::Template;
  use 5.011;
  use warnings;
  my $rvars = shift;
  my %vars  = %$rvars;

  # get time
  my $now_string = localtime;
  $vars{"date"} = $now_string;

  my $headline = join( ' ', $vars{"book"}, $vars{"chapter"} );
  $vars{"headline"} = $headline;
  my $header   = $vars{"header"};
  my $template = Text::Template->new(
    ENCODING => 'utf8',
    SOURCE   => $header,
  ) or die "Couldn't construct template: $!";

  my $result = $template->fill_in( HASH => \%vars );
  say "result is $result";
  return \$result;
}

sub write_footer {
  use Text::Template;
  my ($rvars) = shift;
  my %vars    = %$rvars;
  my $footer  = $vars{"footer"};
  my $template = Text::Template->new( SOURCE => $footer )
    or die "Couldn't construct template: $!";
  my $result = $template->fill_in( HASH => $rvars );
  return \$result;
}

sub write_script {
  use Text::Template;
  use 5.010;
  use utf8;
  my ($rvars) = shift;
  my %vars    = %$rvars;
  my $tmpl    = $vars{"code_tmpl"};
  say "tmpl is $tmpl";
  my $file = $vars{"script_file"};
  my $text = do {
    open my $fh, '<:raw:encoding(UTF-8)', $file
      or die "$file: $!";
    local $/;
    <$fh>;
  };
  my %data = ( 'script', $text );
  my $template = Text::Template->new( SOURCE => $tmpl )
    or die "Couldn't construct template: $!";
  my $result = $template->fill_in( HASH => \%data );
  return \$result;
}

sub write_module {
  use 5.010;
  use File::Spec;
  use Text::Template;
  use utf8;

  my ($rvars) = shift;
  my %vars    = %$rvars;
  my $tmpl    = $vars{"module_tmpl"};
  say "tmpl is $tmpl";
  my $file = File::Spec->rel2abs(__FILE__);
  my $text = do {
    open my $fh, '<:raw:encoding(UTF-8)', $file
      or die "$file: $!";
    local $/;
    <$fh>;
  };
  my %data = ( 'module', $text );
  my $template = Text::Template->new( SOURCE => $tmpl )
    or die "Couldn't construct template: $!";
  my $result = $template->fill_in( HASH => \%data );
  return \$result;
}

1;
