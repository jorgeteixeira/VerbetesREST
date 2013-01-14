package VerbetesREST::Server;

use strict;
use warnings;
use VerbetesREST::Tools;
use VerbetesREST::DBI;
use VerbetesREST::JSON;
use Date::Calc;
use utf8;
binmode(STDOUT, ':utf8');



sub new {
	shift;
  my $this = {};
  
	$this->{tools} = VerbetesREST::Tools->new();
	$this->{dbi} = VerbetesREST::DBI->new();	
	$this->{json} = VerbetesREST::JSON->new();	
	$this->{dbi}->ConnectToHost();
		
	bless $this;
  return $this;
}


############################ GetNewsInfoFromCoOccurrences #####################


sub GetNewsInfoFromCoOccurrences {
	my $this = shift;
	my $begin_date = shift;
	my $end_date = shift;
	my $name1 = shift;
	my $name2 = shift;
	my $nr_links = shift;
	my $limit = shift;
	my $offset = shift;
	
	# Validate inputs
	if ($this->{tools}->ValidateDate($begin_date) eq 0 ||
			$this->{tools}->ValidateDate($end_date) eq 0 ||
			$this->{tools}->ValidateName($name1) eq 0 ||
			$this->{tools}->ValidateName($name2) eq 0 ||
			$this->{tools}->ValidateInteger($limit) eq 0 ||
			$this->{tools}->ValidateInteger($offset) eq 0 ||
			$this->{tools}->ValidateInteger($nr_links) eq 0) {
		return "ERROR";			
	}
	
	# Date intervals cannot be larger than 30 days
	if ( $this->{tools}->GetDifferenceBetweenDates($begin_date,$end_date) > 31 ) {
		return "ERROR2";
	}

	# Fetch news links
	my $news_ids_name1 = $this->{dbi}->GetNewsIdsFromOccurrencesByName($name1, $begin_date, $end_date);
	my $news_ids_name2 = $this->{dbi}->GetNewsIdsFromOccurrencesByName($name2, $begin_date, $end_date);
	my $news_ids_co_occurrences = $this->GetCommonNewsIds($news_ids_name1, $news_ids_name2);
	my @links_and_titles = @{$this->GetNewsInfoFromCoOccurrencesNewsIds($news_ids_co_occurrences, $begin_date, $end_date, $nr_links, $limit, $offset)};

	# Return json structure
	my $links_ref = "";
	return $this->{json}->PrepareNewsLinks(\@links_and_titles, $limit, $offset, scalar(keys %{$news_ids_co_occurrences}));
}


sub GetCommonNewsIds {
	my $this = shift;
	my $ids1 = shift;
	my $ids2 = shift;
	my %intersected_ids = ();
	
	my %ids1 = %{$ids1};
	my %ids2 = %{$ids2};
	for (keys %ids1) {
		my $id1 = $_;
		$intersected_ids{$id1}++ if (defined($ids2{$id1}));
	}
	
	return \%intersected_ids;
}


sub GetNewsInfoFromCoOccurrencesNewsIds {
	my $this = shift;
	my $news_ids = shift;
	my $begin_date = shift;
	my $end_date = shift;
	my $nr_links = shift;
	my $limit = shift;
	my $offset = shift;
	my %news_ids = %{$news_ids};
	
	my %news_info = %{$this->{dbi}->GetNewsInfoFromIds($news_ids)};
	my %comments_info = ();
	for (keys %news_info) {
		my $news_id = $_;
		$comments_info{$news_id} = $news_info{$news_id}{"nr_comments"};
	}	
	
	my %news_ids_to_be_returned = ();
	
	# (1) Most commented news
	my @final_news_ids = ();
	for (sort {$comments_info{$b} <=> $comments_info{$a}} keys %comments_info) {
		if ( defined( $news_ids_to_be_returned{$_} ) ) { next; }
		if ($comments_info{$_} eq 0) { next; }		
		$news_ids_to_be_returned{$_}++;
		push(@final_news_ids, $_);		 
	}
	
	# (2) News from (noticias|desporto) sapo domain
	for (keys %news_info) {
		if ( defined( $news_ids_to_be_returned{$_} ) ) { next; }
		if ($news_info{$_}{"page_url"} =~ /http:\/\/(noticias|desporto)\.sapo\.pt/) {						
			$news_ids_to_be_returned{$_}++;
			push(@final_news_ids, $_);
		}
	}
	
	# (3) News from other sapo domain	
	for (keys %news_info) {
		if ( defined( $news_ids_to_be_returned{$_} ) ) { next; }
		if ($news_info{$_}{"page_url"} =~ /sapo\.pt/) {	
			$news_ids_to_be_returned{$_}++;					
			push(@final_news_ids, $_);			
		}
	}
	
	# (4) Random news
	for (keys %news_info) {
		if ( defined( $news_ids_to_be_returned{$_} ) ) { next; }			
		$news_ids_to_be_returned{$_}++;
		push(@final_news_ids, $_); 
	}


	my @output = ();
	my $counter1 = 0;
	my $counter2 = 0;
	for (@final_news_ids) {
		if (++$counter1 <= $offset) { next; }
		if (++$counter2 > $limit) { last; }
		my %info = ();
		$info{link} = $news_info{$_}{"page_url"};
		$info{title} = $news_info{$_}{"title"};
		$info{pubdate} = $news_info{$_}{"pubdate"};
		$info{source} = $news_info{$_}{"hostname"};
		#$info{nr_comments} = $news_info{$_}{"nr_comments"};
		#$info{id} = $_;
		push(@output, \%info);			
	}
	
	return \@output;
} 



############################### GetEgoNet ######################################

sub GetOriginalName {
	my $this = shift;
	my $name = shift;
	my $begin_date = shift;
	my $end_date = shift;
	
	return $this->{dbi}->GetOriginalName($name,$begin_date,$end_date);
}


sub GetEgoNet {
	my $this = shift;
	my $ego = shift;
	my $begin_date = shift;
	my $end_date = shift;
	my $depth = shift;
	my $min_freq_edges = shift; # minimum frequency of the edge (nr co-occurrences on news between two nodes) 

	# Validate inputs
	if ($this->{tools}->ValidateDate($begin_date) eq 0 ||
			$this->{tools}->ValidateDate($end_date) eq 0 ||
			$this->{tools}->ValidateName($ego) eq 0 ||
			$this->{tools}->ValidateInteger($min_freq_edges) eq 0) {
		return "ERROR";			
	}
	
	
	# Date intervals cannot be larger than 30 days
	if ( $this->{tools}->GetDifferenceBetweenDates($begin_date,$end_date) > 31 ) {
		return "ERROR2";
	}	

	# Fetch all occurrences for this period
	my $occurrences_by_date = $this->{dbi}->GetCoOccurrecesWithEgoByDate($ego, $begin_date, $end_date);
	
	# Calculate network for depth 1 (this is used in all cases)
	my ($nodes_depth1, $nodes_info, $edges_depth1) = $this->GetEgoNetDepth1($occurrences_by_date, $ego, $min_freq_edges, $begin_date, $end_date);
	
	
	# Ego net with depth = 1
	my ($nodes, $edges) = ();
	if ($depth eq 1) {		
		($nodes, $edges) = ($nodes_depth1, $edges_depth1);
	}
	
	
	# Ego net with depth = 1.5
	if ($depth eq 1.5) {
		($nodes, $edges) = $this->GetEgoNetDepth15($nodes_depth1, $nodes_info, $min_freq_edges);
	}
	
	if (scalar(keys %{$nodes}) eq 0) {
		return "ERROR3";	
	}
	
	# Return json structure
	my %ego_net = ();
	return $this->{json}->PrepareEgoNet($ego, $begin_date, $end_date, $depth, $min_freq_edges, $nodes, $edges);
}


sub GetEgoNetOffline {
	my $this = shift;
	my $ego = shift;
	my $begin_date = shift;
	my $end_date = shift;
	my $depth = shift;
	my $min_freq_edges = shift; # minimum frequency of the edge (nr co-occurrences on news between two nodes) 


	# Fetch all occurrences for this period
	my $occurrences_by_date = $this->{dbi}->GetCoOccurrecesWithEgoByDate($ego, $begin_date, $end_date);
	
	# Calculate network for depth 1 (this is used in all cases)
	my ($nodes_depth1, $nodes_info, $edges_depth1) = $this->GetEgoNetDepth1($occurrences_by_date, $ego, $min_freq_edges, $begin_date, $end_date);
	
	
	# Ego net with depth = 1
	my ($nodes, $edges) = ();
	if ($depth eq 1) {		
		($nodes, $edges) = ($nodes_depth1, $edges_depth1);
	}
	
	
	# Ego net with depth = 1.5
	if ($depth eq 1.5) {
		($nodes, $edges) = $this->GetEgoNetDepth15($nodes_depth1, $nodes_info, $min_freq_edges);
	}

	
	# Return json structure
	my %ego_net = ();
	return ($nodes, $edges);
}


sub GetEgoNetDepth1 {
	my $this = shift;
	my $occurrences = shift;
	my $ego = shift;
	my $min_freq_edges = shift;
	my $begin_date = shift;
	my $end_date = shift;
	my %occurrences = %{$occurrences};
	
	# (1) get all news_ids from the ego 'name'
	my %ego_news_ids = %{$this->GetNewsIdsFromName($ego, $occurrences)};
	#warn "Ego '$ego' occurs in " . scalar(keys %ego_news_ids) . " unique news\n";
	
	
	# (2) get names that occur with these previous news_ids
	my %co_occurrences = %{$this->GetNamesOccuringInNewsIds(\%ego_news_ids, $occurrences)};
	
	
	# (3) Prepare edges for depth = 1
	# 		$edges{$source}{$target} = $edge_freq
	my %edges = ();
	my @edges = (); 
	my $counter = 0;	
	for (sort {$co_occurrences{$b} <=> $co_occurrences{$a}} keys %co_occurrences) {
		my $node = $_;
		if ($ego eq $node) { next; } # avoid "Cavaco" <=> "Cavaco"
		my $edge_frequency = $co_occurrences{$_};
		if ($edge_frequency < $min_freq_edges) { last; } # if edge freq is < threshold, stop adding edges
		$edges{$ego}{$node} = $edge_frequency;
		
		my %h = ();
		$h{source} = $ego;
		$h{target} = $node;
		$h{edge_frequency} = $edge_frequency;
		push(@edges, \%h);		
	}	
	
	
	# (4) Prepare nodes for depht = 1
	# 		$nodes{$name} = $node_freq
	my %nodes_depth1 = (); 	
	my %nodes = %{$this->{dbi}->GetNodesFrequencyByNames(\%co_occurrences,$begin_date,$end_date)};
	for (keys %nodes) {
		my $name = $_;
		if (defined($edges{$name}) || defined($edges{$ego}{$name})) {
			my $freq = scalar(keys %{$nodes{$name}});
			$nodes_depth1{$_} = int($freq);
		}
	}	
	
	return \%nodes_depth1, \%nodes, \@edges;
}


sub GetNewsIdsFromName {
	my $this = shift;
	my $name = shift;
	my $occurrences = shift;
	my %occurrences = %{$occurrences};
	my %news_ids = ();
	
	for (keys %{$occurrences{$name}}) {
		$news_ids{$_}++;
	}	
	
	return \%news_ids;
}


sub GetNamesOccuringInNewsIds {
	my $this = shift;
	my $news_ids = shift;
	my $occurrences = shift;
	my %news_ids = %{$news_ids};
	my %occurrences = %{$occurrences};
	my %names = ();
	
	for (keys %occurrences) {
		my $name = $_;
		for (keys %news_ids) {
			my $news_id = $_;
			$names{$name}++ if (defined($occurrences{$name}{$news_id}));
		}		
	}
	
	return \%names;	
}


sub GetNodesFrequency {
	my $this = shift;
	my $occurrences = shift;
	my %occurrences = %{$occurrences};
	my %nodes = ();
	
	for (keys %occurrences) {
		my $name = $_;
		my $node_frequency = 0;
		for (keys %{$occurrences{$name}}) {
			$node_frequency++;
		}
		$nodes{$name} = $node_frequency;
	} 
	
	return \%nodes;
}


sub DumpEdges {
	my $this = shift;
	my @edges = shift;
	
	for (@edges) {
		my %edge = %{$_};
		warn "$edge{source} <== $edge{edge_frequency} ==> $edge{target}\n";
	}

	return 1;	
}


sub GetEgoNetDepth15 {
	my $this = shift;
	my $nodes_depth1 = shift;
	my $nodes_info = shift;
	my $min_freq_edges = shift;
	my %nodes_depth1 = %{$nodes_depth1};
	my %nodes_info = %{$nodes_info};

	my %edges = ();
	my %nodes_depth15 = (); 	
	my @edges = ();
	
	
	# (0) Get occurrences of depth 1.5 (here we have all news ids from names from depth 1)
	for (keys %nodes_info) {
		my $name = $_;
		my $freq = scalar(keys %{$nodes_info{$name}});
		my $ids = "";
		for (keys %{$nodes_info{$name}}) { $ids .= $_ . ","; }
		#warn "$_ ($freq)\n";
		#warn "$_ ($freq) $ids\n";
	}	
	my %occurrences = %nodes_info;
	
	
	# For each node of depth 1
	for (keys %{$nodes_depth1}) {
		my $name_node_depth1 = $_;
		
		# (1) Get all news_ids from each name at depth = 1	
		my %node_news_ids = ();
		for (keys %nodes_info) {
			my $name = $_;
			if ($name ne $name_node_depth1) { next; }
			for (keys %{$nodes_info{$name}}) { $node_news_ids{$_}++; }
		}	
		#warn "=> N1 '$name_node_depth1' occurs in " . scalar(keys %node_news_ids) . " unique news\n";
		
		
		# (2) get names that occur with these previous news_ids
		my %co_occurrences = ();		
		for (keys %nodes_info) {
			my $name = $_;
			for (keys %{$nodes_info{$name}}) { 
				$co_occurrences{$name}++ if (defined($node_news_ids{$_}));
			}			
		}
		
		
		# (3) Prepare edges for this depth1 node '$name_node_depth1'
		# 		$edges{$source}{$target} = $edge_freq
		for (sort {$co_occurrences{$b} <=> $co_occurrences{$a}} keys %co_occurrences) {
			my $node = $_;
			if ($name_node_depth1 eq $node) { next; } # avoid "Cavaco" <=> "Cavaco"
			my $edge_frequency = $co_occurrences{$_};
			if ($edge_frequency < $min_freq_edges) { last; } # if edge freq is < threshold, stop adding edges
						
			if (!defined($nodes_depth1{$node})) { next; } # this is a 1.5 network, so each node must be connected to the ego 

			if (defined($edges{$node}{$name_node_depth1})) { next; } # this network has no directionality so one edget 'A<=>B' is enough, 'B<=>A' is not necessary
			$edges{$name_node_depth1}{$node} = $edge_frequency;
			
			my %h = ();
			$h{source} = $name_node_depth1;
			$h{target} = $node;
			$h{edge_frequency} = $edge_frequency;
			push(@edges, \%h);
		}	
		#$this->DumpEdges(@edges);
		
		
		# (4) Prepare nodes (nodes from depth 1.5 are the same as for depth 1)			
		%nodes_depth15 = %nodes_depth1;		
				
	} # for each name (node at depth 1)
	
	return \%nodes_depth15, \@edges;
}


################################ GetGlobalNet ##################################

sub GetGlobalNet {
	my $this = shift;
	my $begin_date = shift;
	my $end_date = shift;
	my $min_freq_edges = shift; # minimum frequency of the edge (nr co-occurrences on news between two nodes) 

	# Validate inputs
	if ($this->{tools}->ValidateDate($begin_date) eq 0 ||
			$this->{tools}->ValidateDate($end_date) eq 0 ||
			$this->{tools}->ValidateInteger($min_freq_edges) eq 0) {
		return "ERROR";			
	}
	
	
	# Date intervals cannot be larger than 30 days
	if ( $this->{tools}->GetDifferenceBetweenDates($begin_date,$end_date) > 31 ) {
		return "ERROR2";
	}	
	
	
	# Get all occurrences for this period
	my $occurrences_by_date = $this->{dbi}->GetCoOccurrecesByDate($begin_date, $end_date); 
	
	my ($nodes,$edges) = $this->BuildGlobalOccurrences($occurrences_by_date, $min_freq_edges); 
	
	return $this->{json}->PrepareGlobalNet($begin_date, $end_date, $min_freq_edges, $nodes, $edges);
}


sub BuildGlobalOccurrences {
	my $this = shift;
	my $occurrences = shift;
	my $min_freq_edges = shift;
	#my %occurrences = %{$occurrences};
	my @occurrences = @{$occurrences};
	my %edges = ();
	my %nodes = ();

	warn scalar(@occurrences) . " occurrences\n";
	my %info_nodes = ();
	for (@occurrences) {
		my %h = %{$_};
		my $name = $h{name};
		my $news_id = $h{news_id};
		
		if ( defined($info_nodes{$name}) ) {
			my %ids = %{$info_nodes{$name}};
			$ids{$news_id}++ if (!defined($ids{$news_id}));
			$info_nodes{$name} = \%ids;
		} 
		else {
			my %ids = ();
			$ids{$news_id}++ if (!defined($ids{$news_id}));
			$info_nodes{$name} = \%ids;	
		}
		
	}
	
	
	for (keys %info_nodes) {
		my $name1 = $_;
		my %news_ids1 = %{$info_nodes{$name1}};
		
		for (keys %info_nodes) {
			my $name2 = $_;
			my %news_ids2 = %{$info_nodes{$name2}};	
			if ($name1 eq $name2) { next; }
			for (keys %news_ids2) {
				$edges{$name1}{$name2}++ if ( defined( $news_ids1{$_} ) );
			}			
	
		}
	
	}
	
	
	# Prepare nodes
	my @nodes = ();
	my $counter = 0;
	for (keys %nodes) {
		my $name = $_;
		my $node_freq = $nodes{$name};
		my %h = ();
		$h{name} = $name;
		$h{id} = ++$counter;
		$h{frequency} = $node_freq;
		push(@nodes, \%h);
	}	


	# Prepare edges
	my @edges = ();
	for (keys %edges) {
		my $name1 = $_;
		for (keys %{$edges{$name1}}) {
			my $name2 = $_;
			if ($edges{$name1}{$name2} >= $min_freq_edges) {
				#warn "[$edges{$name1}{$name2}] $name1 <=> $name2\n";
				my %h = ();
				$h{source} = $name1;
				$h{target} = $name2;
				$h{frequency} = $edges{$name1}{$name2};
				push(@edges, \%h);
			}
		}
	}
	
	return (\@nodes, \@edges);
}


################################ ToolTips ######################################

sub GetTooltipInfo {
	my $this = shift;
	my $name = shift;
	my $begin_date = shift;
	my $end_date = shift;
	
	# Validate inputs
	if ($this->{tools}->ValidateDate($begin_date) eq 0 ||
			$this->{tools}->ValidateDate($end_date) eq 0 ||
			$this->{tools}->ValidateName($name) eq 0) {
		return "ERROR";			
	}
	
	# Date intervals cannot be larger than 30 days
	if ( $this->{tools}->GetDifferenceBetweenDates($begin_date,$end_date) > 40 ) {
		return "ERROR2";
	}		
	
	# Trends
	my $trends = $this->GetTrendsByNameAndDate($name, $begin_date, $end_date);
	
	# Nr occurrences on news
	my $occurrences_on_news = $this->GetNrOccurrencesOnNews($trends);
	
	# Nr occurrences on news (last 'week')
	my $prev_end_date = $this->{tools}->GetNPreviousDays($begin_date,1);
	my $diff_nr_days = $this->GetDiffNrDays($begin_date,$end_date);
	my $prev_begin_date = $this->{tools}->GetNPreviousDays($prev_end_date,$diff_nr_days);
	my $prev_occurrences_on_news = $this->{dbi}->GetNrOccurrencesOnNewsByDate($name, $prev_begin_date, $prev_end_date);
	
	return $this->{json}->PrepareTooltipInfo($trends,$occurrences_on_news,$prev_occurrences_on_news);
}

sub GetTrendsByNameAndDate {
	my $this = shift;
	my $name = shift;
	my $begin_date = shift;
	my $end_date = shift;
	
	my $trends = $this->{dbi}->GetTrendsByNameAndDate($name, $begin_date, $end_date);
	$trends = $this->FillTrendsWithZeros($begin_date,$end_date,$trends);
	
	return $trends;	
}

sub FillTrendsWithZeros {
	my $this = shift;
	my $begin_date = shift;
	my $end_date = shift;
	my $trends = shift;
	
	my $dates = $this->{tools}->GetDatesFromInterval($begin_date, $end_date);	
	
	my @tuples = @{$trends};
	my %trends = ();
	for (@tuples) {
		my %h = %{$_};
		$h{date} =~ s/ (.+?)$//; # remove time
		$trends{$h{date}} = $h{num};
	}
	
	for (@$dates) {
		my $date = $_;
		if (!defined($trends{$date})) {
			$trends{$date} = 0;
		}
	}

	return \%trends;
}

sub GetNrOccurrencesOnNews {
	my $this = shift;
	my $trends = shift;
	
	my $num_occurrences = 0;
	for (keys %{$trends}) {
		$num_occurrences += $$trends{$_};
	}
	
	return $num_occurrences;
}

sub GetDiffNrDays {
	my $this = shift;
	my $begin_date = shift;
	my $end_date = shift;

	$begin_date =~ /^(.+?)-(.+?)-(.+?)$/g;
	my $begin_year = $1;
	my $begin_month = $2;
	my $begin_day = $3;
	$end_date =~ /^(.+?)-(.+?)-(.+?)$/g;
	my $end_year = $1;
	my $end_month = $2;
	my $end_day = $3;

	my @begin_date = ($begin_year, $begin_month, $begin_day);
	my @end_date  = ($end_year, $end_month, $end_day);
	my $difference = Date::Calc::Delta_Days(@begin_date, @end_date);
	
	return $difference;
}


################################ Ups and downs #################################

sub GetUpsAndDowns {
	my $this = shift;
	my $begin_date = shift;
	my $end_date = shift;
	my $num_results = shift;
	
	# Validate inputs
	if ($this->{tools}->ValidateDate($begin_date) eq 0 ||
			$this->{tools}->ValidateDate($end_date) eq 0 ||
			$this->{tools}->ValidateInteger($num_results) eq 0) {
		return "ERROR";			
	}
	
	# Date intervals cannot be larger than 30 days
	#if ( $this->{tools}->GetDifferenceBetweenDates($begin_date,$end_date) > 31 ) {
	#	return "ERROR2";
	#}		
	
	# Top names that occurs on news "this week"
	my $tuples_this_week = $this->{dbi}->GetTopNamesFromOccurrencesByDateFirstPeriod($begin_date, $end_date);
	my $names_this_week = ();
	for (@{$tuples_this_week}) {
		my %info = %{$_};
		$names_this_week .= "\"" . $info{name} . "\",";
	}
	$names_this_week =~ s/,$//;
	
	# Top names that occurs on news "last week"
	my $prev_end_date = $this->{tools}->GetNPreviousDays($begin_date,1);
	my $diff_nr_days = $this->GetDiffNrDays($begin_date,$end_date);
	my $prev_begin_date = $this->{tools}->GetNPreviousDays($prev_end_date,$diff_nr_days);
	
	# Get names from previous week
	my $tuples_last_week = $this->{dbi}->GetTopNamesFromOccurrencesByDateSecondPeriod($prev_begin_date, $prev_end_date,$names_this_week);
	
	# Get ups and downs
	my $results = $this->ProcessUpsAndDowns($tuples_this_week,$tuples_last_week, $num_results);
	
	return $this->{json}->PrepareUpsAndDowns($results);
}


sub ProcessUpsAndDowns {
	my $this = shift;
	my $results_this_week = shift;
	my $results_previous_week = shift;
	my $num_results = shift;
	my %output = ();
	
	my %ups_and_downs = ();
	my %occurrences_this_week = ();
	
	for (@{$results_this_week}) {
		my %h = %{$_};
		$ups_and_downs{$h{name}}{this_week} = int($h{num});
		$occurrences_this_week{$h{name}} = int($h{num});
	}

	for (@{$results_previous_week}) {
		my %h = %{$_};
		$ups_and_downs{$h{name}}{previous_week} = int($h{num});
	}
	
	for (sort {$occurrences_this_week{$b} <=> $occurrences_this_week{$a}} keys %occurrences_this_week) {
		my $name = $_;
		if ( defined($ups_and_downs{$name}{this_week}) && defined($ups_and_downs{$name}{previous_week}) ) {
			$output{$name}{this_week} = $ups_and_downs{$name}{this_week};
			$output{$name}{previous_week} = $ups_and_downs{$name}{previous_week};
			if (scalar(keys %output) >= $num_results) { last; }
		}
		elsif ( defined($ups_and_downs{$name}{this_week}) ) {
			$output{$name}{this_week} = $ups_and_downs{$name}{this_week};
			$output{$name}{previous_week} = 0;
			if (scalar(keys %output) >= $num_results) { last; }
		}
	}
	
	return \%output;
}


############################### Occurrences Trends #############################

sub GetOccurrencesTrendsByName {
	my $this = shift;
	my $name = shift;
	my $begin_date = shift;
	my $end_date = shift;
	
	
	# Validate inputs
	if ($this->{tools}->ValidateDate($begin_date) eq 0 ||
			$this->{tools}->ValidateDate($end_date) eq 0 ||
			$this->{tools}->ValidateName($name) eq 0) {
		return "ERROR";			
	}
	
	# Date intervals cannot be larger than 30 days
	if ( $this->{tools}->GetDifferenceBetweenDates($begin_date,$end_date) > 31 ) {
		return "ERROR2";
	}		
	
	my $trends = $this->{dbi}->GetTrendsByNameAndDate($name, $begin_date, $end_date);
	$trends = $this->FillTrendsWithZeros($begin_date,$end_date,$trends);
	
	return $this->{json}->PrepareOccurrencesTrends($trends);	
}

############################# News by Occurrences ##############################

sub GetNewsByOccurrencesName {
	my $this = shift;
	my $name = shift;
	my $begin_date = shift;
	my $end_date = shift;
	my $source = shift;
	my $nr_news = shift;
	my $order = shift;
	my $body = shift;
	
	# Validate inputs
	if ($this->{tools}->ValidateDate($begin_date) eq 0 ||
			$this->{tools}->ValidateDate($end_date) eq 0 ||
			$this->{tools}->ValidateName($name) eq 0 ||
			$this->{tools}->ValidateInteger($nr_news) eq 0 ||
			$this->{tools}->ValidateOrder($order) eq 0 ||
			$this->{tools}->ValidateTrueOrFalse($body) eq 0) {
		return "ERROR";			
	}
	
	# Date intervals cannot be larger than 30 days
	if ( $this->{tools}->GetDifferenceBetweenDates($begin_date,$end_date) > 31 ) {
		return "ERROR2";
	}	
	
	my ($info, $occurrences_info) = $this->{dbi}->GetNewsOccurrencesByName($name, $begin_date, $end_date, $source, $nr_news, $order, $body);
	
	# Prepare array of occurrences
	$info = $this->{tools}->PrepareOccurrencesByNews($info, $occurrences_info);
	
	return $this->{json}->PrepareNewsByOccurrencesName($info);	
}

#################### GetTopPersonalitiesFromCoOccurrences ######################

sub GetTopPersonalitiesFromCoOccurrences {
	my $this = shift;
	my $begin_date = shift;
	my $end_date = shift;
	my $num_results = shift;
	
	# Validate inputs
	if ($this->{tools}->ValidateDate($begin_date) eq 0 ||
			$this->{tools}->ValidateDate($end_date) eq 0 ||
			$this->{tools}->ValidateInteger($num_results) eq 0) {
		return "ERROR";			
	}
	
	# Date intervals cannot be larger than 30 days
	if ( $this->{tools}->GetDifferenceBetweenDates($begin_date,$end_date) > 31 ) {
		return "ERROR2";
	}	
	
	my $info = $this->{dbi}->GetOcOccurrencesNamesByDate($begin_date, $end_date);
	my %names = ();
	for (@{$info}) {
		my %h = %{$_};
		$names{$h{name1}}++;
	}
	
	# Limit to the top results
	my $counter = 0;
	my %output = ();
	for (sort { $names{$b} <=> $names{$a} } keys %names ) {
		$output{$_} = $names{$_};
		#if (++$counter > $num_results) { last; }
	}
	
	return $this->{json}->PrepareTopPersonalitiesFromCoOccurrences(\%output);	
		
}

############################# WhoIsLight #######################################

sub WhoIsLight {
	my $this = shift;
	my $name = shift;
	my $date = shift;
	my $counter = shift;

	# Validate inputs
	if ($this->{tools}->ValidateDate($date) eq 0 ||
			$this->{tools}->ValidateName($name) eq 0 ||
			$this->{tools}->ValidateInteger($counter) eq 0) {
		return "ERROR";			
	}
	
	my $tuples = $this->{dbi}->GetPersonalityInfoLight($name,$counter);
	my $personality_info = $this->IntersectVerbetesWithDateIntervals($tuples, $date);
	
	return $this->{json}->PrepareWhoIsLight($personality_info);
}


sub WhoIsJobLight {
	my $this = shift;
	my $job = shift;
	my $job_like = shift;
	my $date = shift;
	my $counter = shift;

	# Validate inputs
	if ($this->{tools}->ValidateDate($date) eq 0 ||
			$this->{tools}->ValidateName($job) eq 0 ||
			$this->{tools}->ValidateName($job_like) eq 0 ||
			$this->{tools}->ValidateInteger($counter) eq 0) {
		return "ERROR";			
	}
	
	my $tuples = $this->{dbi}->GetPersonalityInfoByJobLight($job,$job_like,$counter);
	my $personality_info = $this->IntersectVerbetesWithDateIntervalsForJobs($tuples, $date);
	
	return $this->{json}->PrepareWhoIsLightForJobs($personality_info);	
}


sub IntersectVerbetesWithDateIntervals {
	my $this = shift;
	my $tuples = shift;
	my $date = shift;
	my @tuples = @{$tuples};
	my %output = ();
	
	# Get date based on margin (default is 120 days)
	my ($first_date, $last_date) = $this->{tools}->GetDateWithMargin($date, 120);

	for (@tuples) {
		my %info = %{$_};
		if ($this->{tools}->AnalyseDateIntervals($info{begin_date},$info{end_date},$first_date,$last_date) eq 1) {
			$output{name} = $info{name};
			$output{ergo} = $info{ergo} if(defined($info{ergo}));
			$output{active} = $info{active} if(defined($info{active}));
			return \%output;
		}
	}	
	
	return \%output;
}


sub IntersectVerbetesWithDateIntervalsForJobs {
	my $this = shift;
	my $tuples = shift;
	my $date = shift;
	my @tuples = @{$tuples};
	
	
	# Get date based on margin (default is 120 days)
	my ($first_date, $last_date) = $this->{tools}->GetDateWithMargin($date, 120);

	my @output = ();
	for (@tuples) {
		my %info = %{$_};
		my %output = ();
		if ($this->{tools}->AnalyseDateIntervals($info{begin_date},$info{end_date},$first_date,$last_date) eq 1) {
			$output{name} = $info{name};
			$output{ergo} = $info{ergo};
			$output{firstSeen} = $info{begin_date};
			$output{lastSeen} = $info{end_date};
			$output{counter} = $info{counter};
			push(@output,\%output);
		}
	}	
	
	return \@output;
}


1;
__END__
# Below is stub documentation for your module. You'd better edit it!

=head1 NAME

VerbetesREST::Server - Perl extension for blah blah blah

=head1 SYNOPSIS

  use VerbetesREST::Server;
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
Copyright (C) 2012 by Labs Sapo / Universidade do Porto

=cut
