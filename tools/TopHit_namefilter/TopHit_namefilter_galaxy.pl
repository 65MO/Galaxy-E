#!/usr/bin/perl -w

# Simple filter to keep just the TOPHIT / first occurrence of some identifier
# usefull for keeping only the first tophit in blast when multiple hits are returned
#
# Please be aware that NO additional filtering or checking is done on for instance
# E values of BLAST hits. Tophit = FIRST hit...not necessarily the best..
#
# input list/table having some groupable identifier
# input the column number to filter on (column number starts at 1)
# input number of occurrences to keep
#       note that the hits are displayed in order of occurrence
#       and NOT sorted on given column!
# column splitter (default TAB)
#		Note that: splitting on tab:    \t
#		           splitting on pipe:   \|
#		           combined splits:		-|\|	(splits on '-' OR '|')
#
# output the same table having only the FIRST occurrence of the identifier.
#
# alex.bossers@wur.nl
#

my $version = "v0.13.alx 19-5-2011";
# Version history
# 		0.13	19-05-2011  added extra cmdline opt hits to keep -> first galaxy version
#		0.12	19-05-2011	mods to fit initial needs. Not distributed.
#		0.1		xx-xx-2010	template

use strict;
use warnings;

#cmd line options
if (!$ARGV[4]) {
	warn "Error: not enough arguments\n";
	usage();
}
my ($input) = $ARGV[0] =~ m/^([A-Z0-9_.\-\/]+)$/ig;
my $column = $ARGV[1];   # column numbers start at 1!
my $splitter = $ARGV[2]; # splitter for fields to use (might need enclosing "")
my $hits = $ARGV[3];	 # number of occurences to keep
my ($output) = $ARGV[4] =~ m/^([A-Z0-9_.\-\/]+)$/ig;

if ($column <1 || $hits < 1){warn "Invalid column/hits number\n";usage();}

#keeping track
my $entrycounter = 0;
my $filter_count = 0;

#open the files
open (IN,$input) || die "Input file error: $!\n" ;
open (OUT, ">$output") || die "Output file error: $!\n";

#read file into hash having KEY equal to column data specified
my %filtered;
while (<IN>){
	chomp;
	my $line = $_;
	my @fields = split($splitter,$line);
	#print "@fields\n";
	$entrycounter++;
	if (exists $filtered{$fields[$column-1]}){
		if ($filtered{$fields[$column-1]} < $hits){
			#number of occurrences to keep
			print OUT "$line\n";
			$filtered{$fields[$column-1]}++;
			$filter_count++;
		}
		next;
	}
	else {
		$filtered{$fields[$column-1]} = "1"; #first occurrence
		print OUT "$line\n";
		#print "key: $fields[$column-1]\tLine: $line\n";
		$filter_count++;
	}
}

#end and close
close (IN);
close (OUT);

print "\nVersion   : $version\nComments/bugs : alex.bossers\@wur.nl\n";
print "Processed : $entrycounter entries\n";
print "Filtered  : $filter_count entries remain\n";

sub usage {
  warn "\nVersion: $version\nContact/bugs: alex.bossers\@wur.nl\n";
  my ($cmd) = $0 =~ m/([A-Z0-9_.-]+)$/ig;
  die <<EOF;
usage: $cmd <infile> <column> <splitter> <outfile>

    INPUT:  infile      Input original tabular/text

            column      Input column number to use (>= 1)

            splitter    Splitter char to use (i.e. \t for tab)
                        For splitting on pipe use escaping: \|
                        Combined splits possible: -|\| splits both on - as |

            hits        Number of hits to keep (in chronological order)
                        The results are NOT sorted!

    OUTPUT: outfile     Output filename of filtered table.

EOF
}
#end script