package trans1;
require Exporter;

use utils1;

our @ISA    = qw(Exporter);
our @EXPORT = qw(

  get_tiny
  make_russian_captions

);

sub make_russian_captions {
  use 5.011;
  use warnings;
  use POSIX qw(strftime);
  use Path::Tiny;
  use Encode;
  use open OUT => ':encoding(UTF-8)', ':std';

  my $rvars = shift;
  my %vars  = %$rvars;

  my $munge = strftime( "%d-%m-%Y-%H-%M-%S\.txt", localtime );
  my $in_path = path( $vars{translations}, $munge )->touchpath;

  #system("pwd >$in_path"); works
  my @matching2;
  opendir( my $hh, $vars{eng_captions} ) or die "death  $!\n";
  while ( defined( $_ = readdir($hh) ) ) {
    if (m/txt$/) {
      push( @matching2, $_ );
    }
  }

  #important to sort
  @matching2 = sort @matching2;
  say "matching are @matching2";
  my $rus_munge = path( $vars{translations}, "trans." . $munge );
  say "rus_munge is $rus_munge";

  # open file for writing
  my $fh = path($in_path)->openw_utf8;
  foreach (@matching2) {
    my $eng_path = path( $vars{eng_captions}, $_ );
    say $fh "##$_##";
    my $rus_path = path( $vars{rus_captions}, $_ )->touchpath;
    say "rus_path is $rus_path";
    my $content = path($eng_path)->slurp_utf8;
    $content =~ s/^\s+|\s+$//g;
    say $fh "$content";
    system("trans :ru file://$eng_path >$rus_path");

  }
  print "Get other translations(y/n)?: ";
  my $prompt = <STDIN>;
  chomp $prompt;
  if ( $prompt eq ( "y" | "Y" ) ) {
    my @translators = qw /yandex bing apertium /;
    for my $remote (@translators) {
      my $trans_munge = path( $vars{translations}, "$remote." . $munge );

      ## use trans shell
      say "getting translation from $remote";
      system("trans :ru -e $remote file://$in_path >$trans_munge");
    }
  }
  return "nothing yet";
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

    #more     => '-v',
    user     => $username,
    port     => $port,
    password => $password
  ) or die "Can't connect: $!\n";
  return $sftp;
}

1;
