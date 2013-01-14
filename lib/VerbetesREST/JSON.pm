package VerbetesREST::JSON;

use strict;
use warnings;
use JSON;
use VerbetesREST::Tools;
use utf8;
binmode(STDOUT, ':utf8');


sub new {
	shift;
  my $this = {};
	$this->{tools} = new VerbetesREST::Tools;	
 	bless $this;
  return $this;
}

# Returns a json structure with quotations
sub PrepareNewsLinks {
	my $this = shift;
	my $ref_tuples = shift || "";
	my $limit = shift;
	my $offset = shift;
	my $total_num_news = shift;	

	my @tuples = @{$ref_tuples};
	my %output_hash = ();
	
	$output_hash{NewsLinks} = \@tuples;
	$output_hash{limit} = int($limit);
	$output_hash{offset} = int($offset);
	$output_hash{totalNumNews} = $total_num_news;
	$output_hash{numResults} = scalar(@tuples);
	my $output = encode_json \%output_hash;
	$output = $this->{tools}->SetStringToUtf8($output);
	
	return $output;
}


sub PrepareEgoNet {
	my $this = shift;
	my $ego = shift;
	my $begin_date = shift;
	my $end_date = shift;
	my $depth = shift;
	my $min_freq_edges = shift;
	my $nodes = shift;
	my $edges = shift;

	my %output_hash = ();	
	$output_hash{ego} = $ego;
	$output_hash{beginDate} = $begin_date;
	$output_hash{endDate} = $end_date;
	$output_hash{depth} = $depth;
	$output_hash{minFrequencyEdges} = $min_freq_edges;
	$output_hash{nodes} = $nodes;
	$output_hash{edges} = $edges;
	my $output = encode_json \%output_hash;
	$output = $this->{tools}->SetStringToUtf8($output);
	
	return $output;	
}


sub PrepareGlobalNet {
	my $this = shift;
	my $begin_date = shift;
	my $end_date = shift;
	my $min_freq_edges = shift;
	my $nodes = shift;
	my $edges = shift;

	my %output_hash = ();	
	$output_hash{beginDate} = $begin_date;
	$output_hash{endDate} = $end_date;
	$output_hash{minFrequencyEdges} = $min_freq_edges;
	$output_hash{nodes} = $nodes;
	$output_hash{edges} = $edges;
	my $output = encode_json \%output_hash;
	$output = $this->{tools}->SetStringToUtf8($output);
	
	return $output;		
}


sub PrepareTooltipInfo {
	my $this = shift;
	my $trends = shift;	
	my $occurrences_on_news = shift;
	my $prev_occurrences_on_news = shift;
	my %output_hash = ();
	
	# Trends
	my $ordered_trends = $this->{tools}->OrderTrendsByDate($trends);
	$output_hash{Trends} = $ordered_trends;
	
	# Num occurrences on news
	$output_hash{NumOccurrences} = $occurrences_on_news;
	
	# Previous num of occurrences on news
	$output_hash{PreviousNumOccurrences} = $prev_occurrences_on_news;
	
	my $output = encode_json \%output_hash;
	$output = $this->{tools}->SetStringToUtf8($output);
	
	return $output;	
}


sub PrepareUpsAndDowns {
	my $this = shift;
	my $results = shift || "";

	my %output_hash = ();
	
	$output_hash{UpsAndDowns} = $results;
	my $output = encode_json \%output_hash;
	$output = $this->{tools}->SetStringToUtf8($output);
	
	return $output;
}


sub PrepareOccurrencesTrends {
	my $this = shift;
	my $trends = shift;	
	my %output_hash = ();
	
	# Trends
	my $ordered_trends = $this->{tools}->OrderTrendsByDate($trends);
	$output_hash{Trends} = $ordered_trends;	
	my $output = encode_json \%output_hash;
	$output = $this->{tools}->SetStringToUtf8($output);
	
	return $output;		
}


sub PrepareNewsByOccurrencesName {
	my $this = shift;
	my $info = shift;	
	my %output_hash = ();
	
	# Trends
	$output_hash{News} = $info;	
	$output_hash{numberResults} = scalar(@{$info});
	my $output = encode_json \%output_hash;
	$output = $this->{tools}->SetStringToUtf8($output);
	
	return $output;	
}


sub PrepareTopPersonalitiesFromCoOccurrences {
	my $this = shift;
	my $info = shift;	
	my %output_hash = ();
	
	# Trends
	$output_hash{TopPersonalities} = $info;	
	my $output = encode_json \%output_hash;
	$output = $this->{tools}->SetStringToUtf8($output);
	
	return $output;		
}


sub PrepareWhoIsLight {
	my $this = shift;
	my $info = shift;
	my %info = %{$info};

	my %output_hash = ();
	$output_hash{name} = $info{name};
	$output_hash{ergo} = $info{ergo};
	$output_hash{ergo} = "ex-" . $output_hash{ergo} if (defined($info{active}) && $info{active} eq "no");
	my $output = encode_json \%output_hash;
	$output = $this->{tools}->SetStringToUtf8($output);
	
	return $output;		
}


sub PrepareWhoIsLightForJobs {
	my $this = shift;
	my $info = shift;

	my $output = encode_json $info;
	$output = $this->{tools}->SetStringToUtf8($output);
	
	return $output;		
}



# Returns a json structure with the error type and description
sub PrepareError {
	my $this = shift;
	my $error_number = shift || "undef";	
	my $error_description = shift || "NA";
	my $ego = shift;
	my $begin_date = shift;
	my $end_date = shift;
	my $depth = shift;
	my $min_freq_edges = shift;	
	
	my %error = ();
	$error{error} = $error_description;
	$error{numberError} = $error_number;
	$error{ego} = $ego;
	$error{beginDate} = $begin_date;
	$error{endDate} = $end_date;
	$error{depth} = $depth;
	$error{minFrequencyEdges} = $min_freq_edges;	
	my $output = encode_json \%error;
	$output = $this->{tools}->SetStringToUtf8($output);

	return $output;			
}



1;
__END__
# Below is stub documentation for your module. You'd better edit it!

=head1 NAME

Verbetes - Perl extension for blah blah blah

=head1 SYNOPSIS

  use VerbetesREST::JSON;
  blah blah blah

=head1 DESCRIPTION

Stub documentation for Verbetes, created by h2xs. It looks like the
author of the extension was negligent enough to leave the stub
unedited.

Blah blah blah.

=head2 EXPORT

None by default.

=head1 SEE ALSO

Mention other useful documentation such as the documentation of
related modules or operating system documentation (such as man pages
in UNIX), or any relevant external documentation such as RFCs or
standards.

If you have a mailing list set up for your module, mention it here.

If you have a web site set up for your module, mention it here.

=head1 AUTHOR

Jorge Teixeira, E<lt>jft@fe.up.ptE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2012 by Jorge Teixeira
Copyright (C) 2012 by Sapo Labs / Universidade do Porto

=cut
