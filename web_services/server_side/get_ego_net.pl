#!/usr/bin/perl -w
## Authors: Jorge Teixeira
##
## Creation data: 18/04/2012
##
##	This script is a perl SERVER-SIDE rest webservice.
##		- Inputs: name, name2, beginDate, endDate, nrLink
##		- Outputs: json structure with 'numberLinks' (news links) where 'name1' and
##				'name2' co-occurr between [beginDate; endDate] 
##
## How to use it:
##
##	cgi-bin/VerbetesREST/get_news_links_from_cooccurrences.pl?name1=Pedro Passos Coelho&name2=José Sócrates&beginDate=2012-04-10&endDate=2012-04-18[&numberLinks=3]
##
use strict;
use warnings;
use CGI qw/:standard/;
use VerbetesREST::Server;
use VerbetesREST::Tools;
use VerbetesREST::JSON;
use VerbetesREST::MemcachedHandler;
use utf8;
binmode(STDOUT, ':utf8');

#use Time::HiRes;
#my $start_time = [Time::HiRes::gettimeofday()];

## Initializations
my $cgi = CGI->new();
my $server = VerbetesREST::Server->new();
my $tools = VerbetesREST::Tools->new();
my $json_obj = VerbetesREST::JSON->new();
my $memcached_handler = new VerbetesREST::MemcachedHandler();
$memcached_handler->Init();



## Input parameters
my $name = $cgi->param('name') || "";
$name = $tools->SetStringToUtf8($name);
my $begin_date = $cgi->param("beginDate") || $tools->GetNPreviousDays($tools->GetNow(),7); # default is last week
my $end_date = $cgi->param("endDate") || $tools->GetNow(); # default is now (today)
my $depth = $cgi->param('depth') || 1.5;
my $min_freq_edges = $cgi->param('minFrequencyEdges') || 1;
my $jsoncallback = $cgi->param('jsoncallback') || "";


## Prepare Output
my $error = "";
my $output = "";
my $ego_net = "";
if ($name eq "") {
	$error = $json_obj->PrepareError(1,"Missing input parameter: name");  
}
if ($name ne "") {
	#my $converted_name = $server->GetOriginalName($name,$begin_date,$end_date);	
	#$ego_net = $server->GetEgoNet($converted_name, $begin_date, $end_date, $depth, $min_freq_edges);
	
	# memcached
	my $key = "VerbetesREST::GetEgoNet::" . $name . "::" . $begin_date . "::" . $end_date . "::" . $depth . "::" . $min_freq_edges;
	$key =~ s/\s/_/g; # needed to be a valid key
	$key =~ s/-//g; # needed to be a valid key
	my $memcached_content = $memcached_handler->GetMemcached($key);
	if (!defined($memcached_content)) {
		my $converted_name = $server->GetOriginalName($name,$begin_date,$end_date);	
		$ego_net = $server->GetEgoNet($converted_name, $begin_date, $end_date, $depth, $min_freq_edges);
		$memcached_handler->SetMemcached($key, $ego_net, 3600*24);
		warn("[$key] empty\n");	
	} else {
		$ego_net = $memcached_content;
		warn("[$key] cached\n");
	}		
	
	if ( $ego_net eq "ERROR" ) {	$error = $json_obj->PrepareError(1,"Invalid format of the input paramenter(s)", $name, $begin_date, $end_date, $depth, $min_freq_edges); }
	if ( $ego_net eq "ERROR2" ) {	$error = $json_obj->PrepareError(2,"Maximum time interval is one month"); }
	if ( $ego_net eq "ERROR3" ) {	$error = $json_obj->PrepareError(3,"Empty network", $name, $begin_date, $end_date, $depth, $min_freq_edges); }
	 
	else { $output = $ego_net; }
}



## Prepare headers - json
if ($jsoncallback eq "" && $error eq "") {
	print($cgi->header(-type => "application/json; charset=utf-8"));
}



## Prepare headers - jsoncallback
elsif ($jsoncallback ne "" && $error eq "") {
	print($cgi->header(-type => "application/x-javascript; charset=utf-8"));
	$output = $jsoncallback . "(" . $output . ")";
}



## Prepare headers - error
else {
	print($cgi->header(-type => "application/json; charset=utf-8"));
	if ($jsoncallback eq "") {
		$output = $error;
	} else {
		$output = $jsoncallback . "(" . $error . ")";	
	}
}

#my $diff = Time::HiRes::tv_interval($start_time);
#warn "TIME: $diff\n";

print $output; 