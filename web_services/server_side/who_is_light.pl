#!/usr/bin/perl -w
## Authors: Jorge Teixeira
##
## Creation data: 06/08/2012
##
##	This script is a perl SERVER-SIDE rest webservice.
##		- Inputs: name (complete), date
##		- Outputs: json structure with info about personality 
##
## How to use it:
##
##	cgi-bin/VerbetesREST/who_is_light.pl?name=Pedro Passos Coelho&date=2012-08-06
##
## 
## IMPORTANT:
##
##		This is a light version of "WhoIs" web-service. It uses a 120 days default
##			margin, a minimum frequency of the counter of 2 and that the input name
##			is in its complete form (e.g.: Aníbal Cavaco Silva). It only return the
##			most popular ergo for the search query
##
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

use Time::HiRes;
my $start_time = [Time::HiRes::gettimeofday()];

## Initializations
my $cgi = CGI->new();
my $server = VerbetesREST::Server->new();
my $tools = VerbetesREST::Tools->new();
my $json_obj = VerbetesREST::JSON->new();
my $memcached_handler = new VerbetesREST::MemcachedHandler();
$memcached_handler->Init();



## Input parameters
my $name = $cgi->param('name') || "";
my $job = $cgi->param('job') || "";
my $job_like = $cgi->param('job_like') || "";
$name = $tools->SetStringToUtf8($name);
$job = $tools->SetStringToUtf8($job);
$job_like = $tools->SetStringToUtf8($job_like);
my $date = $cgi->param("date") || $tools->GetNow(); # default is now (today)
my $jsoncallback = $cgi->param('jsoncallback') || "";
my $counter = $cgi->param('min') || 2;



## Prepare Output
my $error = "";
my $output = "";
my $info = "";
if ($name eq "" && $job eq "" && $job_like eq "") {
	$error = $json_obj->PrepareError(1,"Missing input parameter: name/job/job_like");  
}

## (1) name
if ($name ne "" && $job eq "" && $job_like eq "") {	
	# memcached
	my $key = "VerbetesREST::WhoIsLight::" . $name . "::" . $date;
	$key =~ s/\s/_/g; # needed to be a valid key
	$key =~ s/-//g; # needed to be a valid key
	my $memcached_content = $memcached_handler->GetMemcached($key);
	if (!defined($memcached_content)) {
		$info = $server->WhoIsLight($name,$date,$counter);	
		$memcached_handler->SetMemcached($key, $info, 3600*24*7); #one week cache
		warn("[$key] empty\n");	
	} else {
		$info = $memcached_content;
		warn("[$key] cached\n");
	}		
	
	if ( $info eq "ERROR" ) {	$error = $json_obj->PrepareError(1,"Invalid format of the input paramenter(s)", $name, $date); } 
	else { $output = $info; }
}



## (2) job/job_like
if ( ($job ne "" || $job_like ne "") && $name eq "" ) {
	my $key = "VerbetesREST::WhoIsLight::" . $job . "::" . $job_like . "::" . $date;
	$key =~ s/\s/_/g; # needed to be a valid key
	$key =~ s/-//g; # needed to be a valid key
	my $memcached_content = $memcached_handler->GetMemcached($key);
	if (!defined($memcached_content)) {
		$info = $server->WhoIsJobLight($job,$job_like,$date,$counter);	
		$memcached_handler->SetMemcached($key, $info, 3600*24*7); #one week cache
		warn("[$key] empty\n");	
	} else {
		$info = $memcached_content;
		warn("[$key] cached\n");
	}		
	
	if ( $info eq "ERROR" ) {	$error = $json_obj->PrepareError(1,"Invalid format of the input paramenter(s)", $name, $date); } 
	else { $output = $info; }	
}


## (3) not name nor job/job_like
if ( ($job ne "" || $job_like ne "") && $name ne "" ) {
	$output = $json_obj->PrepareError(1,"Invalid format of the input paramenter(s). Choose only name OR job/job_like");
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


my $diff = Time::HiRes::tv_interval($start_time);
warn "TIME (WhoIsLight): $diff\n";

print $output; 