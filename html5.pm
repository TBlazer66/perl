package html5;
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
);

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
  use strict;
  use 5.010;

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
  use strict;
  use warnings;
  use 5.010;
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



sub get_tiny {

  use 5.011;
  use warnings;
  use Net::SFTP::Foreign;
  use Config::Tiny;
  use Data::Dumper;

  my $ini_path = qw( /home/bob/Documents/html_template_data/3.values.ini );
  say "ini path is $ini_path";

  my $sub_hash = "my_sftp";
  my $Config   = Config::Tiny->new;
  $Config = Config::Tiny->read( $ini_path, 'utf8' );
  say Dumper $Config;
  # -> is optional between brackets
  my $domain   = $Config->{$sub_hash}{'domain'};
  my $username = $Config->{$sub_hash}{'username'};
  my $password = $Config->{$sub_hash}{'password'};
  my $port     = $Config->{$sub_hash}{'port'};

  #dial up the server

  say "values are $domain $username $password $port";
  my $sftp = Net::SFTP::Foreign->new(
    $domain,
    user     => $username,
    port     => $port,
    password => $password
  ) or die "Can't connect: $!\n";
  return $sftp;
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
  my $header = $vars{"header"};
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
