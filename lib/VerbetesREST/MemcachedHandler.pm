package VerbetesREST::MemcachedHandler;

use strict;
use warnings;
use Cache::Memcached::Fast;

sub new {
	shift;
  my $this = {};
  $this->{memcached} = "";
     
  bless $this;
  return $this;
}


sub Init() {
	my $this = shift;
	
	my @memcache_hosts = ("");	
	$this->{memcached} = new Cache::Memcached::Fast {
		'servers' => \@memcache_hosts,
		utf8 => ($^V ge v5.8.1 ? 1 : 0),
	};
	
	$this->{memcached}->enable_compress(0);
}



sub GetMemcached() {
	my $this = shift;
	my $key = shift || "";
	
	my $content = $this->{memcached}->get($key);

	return $content;

}


sub SetMemcached() {
	my $this = shift;
	my $key = shift || "";
	my $content = shift || "";
	my $timeout = shift || 60;
	
	$this->{memcached}->set($key, $content, $timeout);
	
	return 1;
}



sub SetVerbose() {
	my $this = shift;
  $this->{verbose} = shift || 0;
}



sub Warn() {
  my $this = shift;
  my $message = shift;
  my $min_verbose = shift || 1;

  if ($this->{verbose} < $min_verbose) {
    return;
  }
  ## Caller Info
  my ($package, $filename, $line, $subroutine, 
      $hasargs, $wantarray, $evaltext, $is_require) = caller(1);
  
  ## Time Info
  my ($sec, $min, $hour, $mday, $mon, 
      $year, $wday, $yday, $isdst) = localtime(time());
  if ($sec < 10) {
    $sec = "0" . $sec;
  }
  if ($min < 10) {
    $min = "0" . $min;
  }
  
  warn($hour . ":" . $min . ":" . $sec . " $subroutine($line) - $message\n");
}

1;


__END__

=head1 NAME

	Exporter

=head1 SYNOPSIS

	use VerbetesREST::MemcachedHandler;

=head1 DESCRIPTION

	This module ...

=head1 METHODS

=head2 new()

	Initialize the module
	

=head2 SetVerbose ()

	Method used to define the level of warnings.
	
=head2 Warn ()

	This method is used to release warning during the program execution accordingly
	to the verbose level previously defined.

=head1 SEE ALSO


=head1 AUTHOR

Jorge Teixeira, E<lt>jft@fe.up.ptE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2012 by Jorge Teixeira
Copyright (C) 2012 by Sapo Labs / Universidade do Porto

=cut