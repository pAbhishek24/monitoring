#!/usr/bin/perl

###################################################################################################################################
###################################################################################################################################
###################################################################################################################################
##	LOG PARSER & STATISTICS AGGREGATOR DEVELOPED FOR EXTENDED WEB SERVER ACCESS LOGS
##	IT CAN ALSO BE USED FOR PARSING ANY LOG FILE & AGGREGATING STATS FOR 1 KEY-VALUE PAIR
##	IN FUTURE VERSIONS, THIS CAN BE EXTENDED FOR MULTIPLE KEY-VALUE PAIRS.
##
##	WRITTEN BY: VISHANT GUPTA (VISHANT.GUPTA@ORACLE.COM)
##
##	EXPECTED COMMAND-LINE INPUT: LOG FILE NAMES (FULL PATH CAN ALSO BE USED)
##	EXPECTED OUPUT: ALL UNIQUE KEYS WITH THEIR COUNT, MIN VALUE, MAX VALUE, AVG & STDEV (Sorted desc by count)
##			 OVERALL COUNT, MIN VALUE, MAX VALUE, AVG & STDEV
##	CONFIGURATION: Script permits defining column position for Key & Value (see section "Define Column Positions" in the code
##			   Also, script filters input log file rows by the one's that start with an interger. This holds true for access 
##			   log files. For other files, the filter criterion would need to be changed accordingly.
###################################################################################################################################
###################################################################################################################################
###################################################################################################################################

use Data::Dumper;
#use warnings;
use strict;

###################################### usage ./gatherLogStats.perl <log_file> #####################################################
unless (@ARGV > 0) {		# print usage message if no files passed	
    print "Usage: $0 <log_files seperated by white space>\n";
    exit(1);	 	
}
####################################################################################################################################


################# Define Column Positions for key, attributes to gather statistics on & delimiter seperating the columns ############
################# Position index starts from 1										 ##############################
my $keyPosition = 1;
my $valuePosition = 8;
my $delimiter = " ";
####################################################################################################################################


#################################### MAIN ##########################################################################################
`cat @ARGV > $PWD/tempFile.txt`;
{
	my %countHash;
	my %minHash;
	my %maxHash;
	my %sumHash;
	my %sqrSumHash;
	my $countAll;
	my $minAll = 99999999999;
	my $maxAll = 0;
	my $sumAll;
	my $sqrSumAll;
	while (<FH1>)
	{
	 chomp($_);
	 if(m/.*PID.*/) ####  This can be changed as per the need.
		{print "First Line Ignored";}
	 else
	  {
		my @thisRow = split(/$delimiter/,$_);
		######### print $thisRow[$keyPosition-1].",".$thisRow[$valuePosition-1]."\n"; ###### To Debug
		$countHash{$thisRow[$keyPosition-1]}++;
		if (exists $minHash{$thisRow[$keyPosition-1]}) {} else {$minHash{$thisRow[$keyPosition-1]} = 999999999999};
		if (exists $maxHash{$thisRow[$keyPosition-1]}) {} else {$maxHash{$thisRow[$keyPosition-1]} = 0};
		if ($minHash{$thisRow[$keyPosition-1]} > $thisRow[$valuePosition-1]) {$minHash{$thisRow[$keyPosition-1]} = $thisRow[$valuePosition-1]};
		if ($maxHash{$thisRow[$keyPosition-1]} < $thisRow[$valuePosition-1]) {$maxHash{$thisRow[$keyPosition-1]} = $thisRow[$valuePosition-1]};
		$sumHash{$thisRow[$keyPosition-1]} = $sumHash{$thisRow[$keyPosition-1]} + $thisRow[$valuePosition-1];
		$sqrSumHash{$thisRow[$keyPosition-1]} = $sqrSumHash{$thisRow[$keyPosition-1]} + $thisRow[$valuePosition-1]**2;

		$countAll++;
		if ($minAll > $thisRow[$valuePosition-1]) {$minAll = $thisRow[$valuePosition-1]};
		if ($maxAll < $thisRow[$valuePosition-1]) {$maxAll = $thisRow[$valuePosition-1]};
		$sumAll = $sumAll + $thisRow[$valuePosition-1];
		$sqrSumAll = $sqrSumAll + $thisRow[$valuePosition-1]**2;
		######## print $thisRow[$valuePosition-1].",".$sumHash{$thisRow[$keyPosition-1]}.",".$sqrSumHash{$thisRow[$keyPosition-1]}."\n"; ###### To Debug
	  }
	}
	my @urlsSortedByCount = sort {$countHash{$a} <=> $countHash{$b}} keys %countHash;
	
	######################################################## Now Printing all Stats ##############################################
	print "##################################### OVERALL STATS FOR ALL REQUESTS ###################################################\n";
	print "Count, Min(s), Max(s), Avg(s), Stdev\n";
	print "----------------------------------------------------------------------------------------------------------------\n";
	print $countAll.",".$minAll.",".$maxAll.",".$sumAll/$countAll.",".sqrt($sqrSumAll/$countAll - ($sumAll/$countAll)**2)."\n";
	print "########################################################################################################################\n\n";

	print "####################### INDIVIDUAL STATS FOR EACH UNIQUE REQUEST (Sorted descending by Count) ############################\n";
	print "Key, Count, Min(s), Max(s), Avg, Stdev\n";
	print "--------------------------------------------------------------------------------------------------------------------------\n";
	for( my $i=$#urlsSortedByCount; $i >= 0; $i--)
	{
		my $thisRow = $urlsSortedByCount[$i];
		printf $thisRow.",".$countHash{$thisRow}.",".$minHash{$thisRow}.",".$maxHash{$thisRow}.",".$sumHash{$thisRow}/$countHash{$thisRow}.",".sqrt($sqrSumHash{$thisRow}/$countHash{$thisRow} - ($sumHash{$thisRow}/$countHash{$thisRow})**2)."\n";
	}
	print "#########################################################################################################################\n";
	##############################################################################################################################
}
close(FH1);
`rm -f $PWD/tempFile.txt`; 
####################################################################################################################################
