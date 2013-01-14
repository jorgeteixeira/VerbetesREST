package VerbetesREST::Tools;

use strict;
use warnings;
use Encode;
use Time::Local;
use Date::Calc;
use utf8;
binmode(STDOUT, ':utf8');



sub new () {
	shift;
  my $this = {};	

 	bless $this;
  return $this;
}


# This method is like GOLD, tons of GOLD!!!! (credits to C.Valente)
# It verifies is a string is in UTF8, and if not, update its flags.
sub SetStringToUtf8 () {
	my $this = shift;
	my $string = shift || "";

	if ( Encode::is_utf8( $string ) ) {
		#warn("'$string' is utf8\n");
		# String is in utf-8		
		return $string;
	} else {
		#try to see if it's valid utf8 but the flag is off
		Encode::_utf8_on( $string );
		if ( Encode::is_utf8( $string, 1 ) ) {
			#warn("'$string' is utf8 (flagged turned on)\n");
			return $string;
		} else {
			Encode::_utf8_off( $string );
			Encode::_utf8_on( $string );
			#warn("'$string' is utf8 (last chance...)\n");
			return $string;
		}
	}
	
	return $string;
}


############################ VALIDATE INPUTS ###################################

# Validator for date ('YYYY-MM-DD')
sub ValidateDate {
	my $this = shift;
	my $date = shift || ""; # valid format: YYYY-MM-DD
	
	if ($date ne "" && $date !~ /^\d{4}-\d{2}-\d{2}$/) {
		warn("VerbetesREST::Tools::ValidateDate -> Invalid date input format! (should be YYYY-MM-DD). exiting...\n");
		return 0;
	}	
	
	return $date;
}


# Validator for output formats ('json', 'xml')
sub ValidateFormat {
	my $this = shift;
	my $format = shift || ""; # valid format: 'json' or 'xml'
	
	if ($format ne "" && $format !~ /json/i && $format !~ /xml/i) {		
		warn("VerbetesREST::Tools::ValidateFormat -> Invalid 'format' input format! (should be 'json' or 'xml'). exiting...\n");
		return 0;
	}
	
	return $format;
}	


# Validator for order ('date','comments','views')
sub ValidateOrder {
	my $this = shift;
	my $order = shift || ""; # valid format: 'date','comments','views'
	
	if ($order ne "" && $order !~ /date/i && $order !~ /comments/i && $order !~ /views/i) {		
		warn("VerbetesREST::Tools::ValidateFormat -> Invalid 'order' input format! (should be 'date' or 'comments' or 'views'). exiting...\n");
		return 0;
	}
	
	return $order;	
}


# Validator for name	
sub ValidateName {
	my $this = shift;
	my $name = shift || "";
	
	# avoid non-characters (except '-', ',' and spaces) and avoid empty strings
	if ($name ne "" && $name =~ /\d|\!|\/|\\|\?|\.|\:|\;|\"|\'|\*|\+|\(|\)|\&|\=|\%|\$|^$/) {
		warn("VerbetesREST::Tools::ValidateName -> Invalid 'name' input format! exiting...\n");
		return 0;
	}
	
	return $name;
}	 	


# Generic validator for integers
sub ValidateInteger {
	my $this = shift;
	my $int = shift || "";
	
	if ($int ne "" && $int !~ /^\d{1,}$/) {
		warn("VerbetesREST::Tools::ValidateInt -> Invalid 'int' input format! (should be an integer > 0). exiting...\n");
		return 0;
	}
	
	return $int;
}



# Generic validator for true/false
sub ValidateTrueOrFalse {
	my $this = shift;
	my $input = shift || "";
	
	if ($input ne "true" && $input ne "false") {
		warn("VerbetesREST::Tools::ValidateTrueOrFalse -> Invalid input format! (should be true or false). exiting...\n");
		return 0;
	}
	
	return $input;
}

########################### TEMPORAL EXPRESSIONS ###############################

sub GetNow() {
	my $this = shift;
	
	my %months = ('Jan' => 1, 'Feb' => 2, 'Mar' => 3, 'Apr' => 4, 'May' => 5, 
								'Jun' => 6, 'Jul' => 7, 'Aug' => 8, 'Sep' => 9, 'Oct' => 10, 
								'Nov' => 11, 'Dec' => 12);

	my $now = localtime (time());

	# Wed Jan  5 18:18:04 2011
	$now =~ /^(.+?) (.+?)\s{1,2}(.+?) (.+?) (.+?)$/;
	$now = "$5-$months{$2}-$3";
	
	$now =~ s/^(\d\d\d\d)-(\d\d)-(\d)$/$1\-$2\-0$3/;
	$now =~ s/^(\d\d\d\d)-(\d)-(\d\d)$/$1\-0$2\-$3/;
	$now =~ s/^(\d\d\d\d)-(\d)-(\d)$/$1\-0$2\-0$3/;	

	return $now;
}


sub GetNPreviousDays {
	my $this = shift;
	my $input_date = shift; # format YYYY-MM-DD
	my $nr_days = shift || 1;

	my %months = ('Jan' => '01', 'Feb' => '02', 'Mar' => '03', 'Apr' => '04', 'May' => '05',
								'Jun' => '06', 'Jul' => '07', 'Aug' => '08', 'Sep' => '09', 'Oct' => '10',
								'Nov' => '11', 'Dec' => '12');

	$input_date =~ /^(.+?)-(.+?)-(.+?)$/;
	my $input_date_timestamp = timelocal(0,0,0,$3,$2-1,$1-1900);
  my $previous_day_timestamp = localtime($input_date_timestamp - 3600*24*$nr_days);
	# Wed Jan  5 18:18:04 2011
	$previous_day_timestamp =~ /^(.+?) (.+?)\s{1,2}(.+?) (.+?) (.+?)$/;
  my $previous_day = "$5-$months{$2}-$3";
  
	$previous_day =~ s/^(\d\d\d\d)-(\d\d)-(\d)$/$1\-$2\-0$3/;
	$previous_day =~ s/^(\d\d\d\d)-(\d)-(\d\d)$/$1\-0$2\-$3/;
	$previous_day =~ s/^(\d\d\d\d)-(\d)-(\d)$/$1\-0$2\-0$3/;

	return $previous_day;
}


sub GetNFollowingDays {
	my $this = shift;
	my $input_date = shift; # format YYYY-MM-DD
	my $nr_days = shift || 1;

	my %months = ('Jan' => '01', 'Feb' => '02', 'Mar' => '03', 'Apr' => '04', 'May' => '05',
								'Jun' => '06', 'Jul' => '07', 'Aug' => '08', 'Sep' => '09', 'Oct' => '10',
								'Nov' => '11', 'Dec' => '12');

	$input_date =~ /^(.+?)-(.+?)-(.+?)$/;
	my $input_date_timestamp = timelocal(0,0,0,$3,$2-1,$1-1900);
  my $previous_day_timestamp = localtime($input_date_timestamp + 3600*24*$nr_days);
	# Wed Jan  5 18:18:04 2011
	$previous_day_timestamp =~ /^(.+?) (.+?)\s{1,2}(.+?) (.+?) (.+?)$/;
  my $previous_day = "$5-$months{$2}-$3";
  
	$previous_day =~ s/^(\d\d\d\d)-(\d\d)-(\d)$/$1\-$2\-0$3/;
	$previous_day =~ s/^(\d\d\d\d)-(\d)-(\d\d)$/$1\-0$2\-$3/;
	$previous_day =~ s/^(\d\d\d\d)-(\d)-(\d)$/$1\-0$2\-0$3/;

	return $previous_day;
}


sub GetDatesFromInterval {
	my $this = shift;
	my $begin_date = shift;
	my $end_date = shift;
	my @dates = ();
	
	my $begin_date_plain = $begin_date;
	$begin_date_plain =~ s/-//g;
	my $end_date_plain = $end_date;
	$end_date_plain =~ s/-//g;

	my $plain_date = $begin_date_plain;
	while ($plain_date <= $end_date_plain) {
		my $date = $plain_date;
		$date =~ s/^(\d{4})(\d{2})(\d{2})$/$1-$2-$3/;
		push (@dates, $date);
		$date = $this->GetNFollowingDays($date,1);
		$plain_date = $date;
		$plain_date =~ s/-//g;
	}
	
	return \@dates;
}


# Return the difference in days between two dates
sub GetDifferenceBetweenDates {
	my $this = shift;
	my $date1 = shift;
	my $date2 = shift;
	$date1 =~ /^(.+?)-(.+?)-(.+?)$/g;
	my $year1 = $1;
	my $month1 = $2;
	my $day1 = $3;
	$date2 =~ /^(.+?)-(.+?)-(.+?)$/g;
	my $year2 = $1;
	my $month2 = $2;
	my $day2 = $3;

	my $difference = Date::Calc::Delta_Days($year1,$month1,$day1,$year2,$month2,$day2);	
	
	return $difference;
}


# Returns a date interval based on the margin (method used for web-services)
# example:-> input_date:2010-03-01 , input_margin:60 
#					-> output: [2010-01-01;2010-05-01]
# Used in Verbetes->WhoIsLight()
sub GetDateWithMargin() {
	my $this = shift;
	my $input_date = shift || GetNow();
	my $margin = shift || 30; # measured in days
		
	my %months = ('Jan' => 1, 'Feb' => 2, 'Mar' => 3, 'Apr' => 4, 'May' => 5, 
								'Jun' => 6, 'Jul' => 7, 'Aug' => 8, 'Sep' => 9, 'Oct' => 10, 
								'Nov' => 11, 'Dec' => 12);

	# Convert input date into timestamp
	$input_date =~ /^(.+?)-(.+?)-(.+?)$/;
	my $date_timestamp = timelocal(0,0,0,$3,$2-1,$1-1900);

	# Create date +/- margin
	my $date_minus = localtime ($date_timestamp - 3600*24*$margin);
	my $date_plus = localtime ($date_timestamp + 3600*24*$margin);

	# Wed Jan  5 18:18:04 2011
	$date_plus =~ /^(.+?) (.+?)\s{1,2}(.+?) (.+?) (.+?)$/;
	$date_plus = "$5-$months{$2}-$3";
	
	my $flag_plus = 0;
	if ($flag_plus eq 0 && $date_plus =~ /^(\d\d\d\d)-(\d\d)-(\d)$/) {
		$date_plus =~ s/^(\d\d\d\d)-(\d\d)-(\d)$/$1-$2-0$3/;
		#warn "1+ : $date_plus\n";
		$flag_plus = 1;
	}	
	if ($flag_plus eq 0 && $date_plus =~ /^(\d\d\d\d)-(\d)-(\d\d)$/) {
		$date_plus =~ s/^(\d\d\d\d)-(\d)-(\d\d)$/$1-0$2-$3/;
		#warn "2+ : $date_plus";
		$flag_plus = 1;
	} 
	if ($flag_plus eq 0 && $date_plus =~ /^(\d\d\d\d)-(\d)-(\d)$/) {
		$date_plus =~ s/^(\d\d\d\d)-(\d)-(\d)$/$1-0$2-0$3/;
		#warn "3+ : $date_plus";
		$flag_plus = 1;
	}
	
	$date_minus =~ /^(.+?) (.+?)\s{1,2}(.+?) (.+?) (.+?)$/;
	$date_minus = "$5-$months{$2}-$3";	
	my $flag_minus = 0;
	if ($flag_minus eq 0 && $date_minus =~ /^(\d\d\d\d)-(\d\d)-(\d)$/) {
		$date_minus =~ s/^(\d\d\d\d)-(\d\d)-(\d)$/$1-$2-0$3/;
		#warn "1- : $date_minus";
		$flag_minus = 1;
	}	
	if ($flag_minus eq 0 && $date_minus =~ /^(\d\d\d\d)-(\d)-(\d\d)$/) {
		$date_minus =~ s/^(\d\d\d\d)-(\d)-(\d\d)$/$1-0$2-$3/;
		#warn "2- : $date_minus";
		$flag_minus = 1;
	} 
	if ($flag_minus eq 0 && $date_minus =~ /^(\d\d\d\d)-(\d)-(\d)$/) {
		$date_minus =~ s/^(\d\d\d\d)-(\d)-(\d)$/$1-0$2-0$3/;
		#warn "3- : $date_minus";
		$flag_minus = 1;
	}
	
	#warn "Date plus: $date_plus\n";
	#warn "Date minus: $date_minus\n";
	return ($date_minus, $date_plus);
}


# Used in Verbetes->WhoIsLight(). It tests the intersection of 4 
#		different dates (begin and end date of the ergo	plus/minus the margin). 
sub AnalyseDateIntervals() {
	my $this = shift;
	my $t1 = shift || ""; # date format: YYYY-MM-DD
	my $t2 = shift || ""; # date format: YYYY-MM-DD
	my $t3 = shift || ""; # date format: YYYY-MM-DD
	my $t4 = shift || ""; # date format: YYYY-MM-DD
	
	$t1 =~ s/^(\d{4})-(\d{2})-(\d{2})$/$1$2$3/;
	$t2 =~ s/^(\d{4})-(\d{2})-(\d{2})$/$1$2$3/;
	$t3 =~ s/^(\d{4})-(\d{2})-(\d{2})$/$1$2$3/;
	$t4 =~ s/^(\d{4})-(\d{2})-(\d{2})$/$1$2$3/;
	
	
	# Case 1: The user date interval includes all the interval of the verbete
	##					(verbete)	T1	/-----------------/ T2
	##				(teste)	T3	/------------------------/ T4			
	if ($t1>$t3 && $t2<$t4) {
		## good result
		return 1;
	}

	# Case 2: The user date interval is inside the interval of the verbete
	##					(verbete)	T1	/-----------------/ T2
	##								(teste)	T3	/---------/ T4			
	if ($t1<$t3 && $t2>$t4) {
		## good result
		return 1;
	}

	# Case 3: 
	##					(verbete)	T1	/-----------------/ T2
	##				(teste)	T3	/---------/ T4			
	if ($t1>$t3 && $t2>$t4 && $t1<$t4) {
		## good result
		return 1;
	}


	# Case 4: 
	##					(verbete)	T1	/-----------------/ T2
	##					(teste)							T3	/------------/ T4			
	if ($t1<$t3 && $t2<$t4 && $t3<$t2) {
		## good result
		return 1;
	}	
	
	return 0;
}

################################ TRENDS #######################################

sub OrderTrendsByDate {
	my $this = shift;
	my $trends_ref = shift;
	
	my %tmp_trends = ();
	my %trends = %{$trends_ref};
	for (keys %trends) {
		my $date = $_;
		$date =~ s/^(\d{4})-(\d\d)-(\d\d)$/$1$2$3/;
		$tmp_trends{$date} = $trends{$_};
	}
	
	my @output = ();
	for (sort {$a <=> $b} keys %tmp_trends) {
		my $date = $_;
		$date =~ s/^(\d{4})(\d\d)(\d\d)$/$1\-$2\-$3/;
		my %h = ();
		$h{$date} = int($tmp_trends{$_});
		push(@output, \%h);
	}
	
	return \@output;
}


############################## Normalize Inputs ###############################

sub NormalizeString {
	my $this = shift;
	my $name = shift;
	
	$name = lc($name);

	#$name =~ s/(á|é|í|ó|ú|à|ã|õ|ç)/$map{$1}/gis;
	$name =~ s/à|À|á|Á|ã|Ã|â|Â/a/igs;
	$name =~ s/é|É|ê|Ê/e/igs;
	$name =~ s/í|Í/i/igs;
	$name =~ s/ó|Ó|õ|Õ|ô|Ô/o/igs;
	$name =~ s/ú|Ú/u/igs;
	$name =~ s/ç|Ç/c/igs;	
		
	return $name;	
}


################################################################################

sub PrepareOccurrencesByNews {
	my $this = shift;
	my $info = shift;
	my $occurrences_info = shift;
	my %occurrences_info = %{$occurrences_info};
	
	my @output = ();
	my %used_occurrences = ();
	for (@{$info}) {
		my %h = %{$_};
		$occurrences_info{$h{id}} =~ s/,$//;
		my @occurrences = split(/,/,$occurrences_info{$h{id}});
		$h{occurrences} = \@occurrences;
		push(@output, \%h);	
	}
	
	return \@output;
}

1;

__END__
# Below is stub documentation for your module. You'd better edit it!

=head1 NAME

VerbetesREST::Tools - Perl extension for blah blah blah

=head1 SYNOPSIS

  use VerbetesREST::Tools;
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
