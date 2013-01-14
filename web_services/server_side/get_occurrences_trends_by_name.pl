#!/usr/bin/perl -w
## Authors: Jorge Teixeira
##
## Creation data: 24/04/2012
##
##	This script is a perl SERVER-SIDE rest webservice.
##		- Inputs: name, beginDate, endDate
##		- Outputs: array with trends (date:numOccurrences) for that time interval and name
##
## How to use it:
##
##	cgi-bin/VerbetesREST/get_ups_and_downs.pl?beginDate=2012-04-10&endDate=2012-04-18
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
my $jsoncallback = $cgi->param('jsoncallback') || "";



## Prepare Output
my $error = "";
my $output = "";
my $info = "";
if ($name eq "") {
	$error = $json_obj->PrepareError(1,"Missing input parameter: name");  
}
if ($name ne "") {
	#$info = $server->GetOccurrencesTrendsByName($name, $begin_date, $end_date);
	
	# memcached
	my $key = "VerbetesREST::GetOccurrencesTrendsByName::" . $name . "::" . $begin_date . "::" . $end_date;
	$key =~ s/\s/_/g; # needed to be a valid key
	$key =~ s/-//g; # needed to be a valid key
	my $memcached_content = $memcached_handler->GetMemcached($key);
	if (!defined($memcached_content)) {
		$info = $server->GetOccurrencesTrendsByName($name, $begin_date, $end_date);		
		$memcached_handler->SetMemcached($key, $info, 3600*24);
		warn("[$key] empty\n");	
	} else {
		$info = $memcached_content;
		warn("[$key] cached\n");
	}	
	
	if ( $info eq "ERROR" ) {	$error = $json_obj->PrepareError(1,"Invalid format of the input paramenter(s)"); } 
	if ( $info eq "ERROR2" ) {	$error = $json_obj->PrepareError(2,"Maximum time interval is one month"); }	
	else { $output = $info; }
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

print $output; 