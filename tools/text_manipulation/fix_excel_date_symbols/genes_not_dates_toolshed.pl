#!/usr/bin/perl

use strict;
use warnings;
#use POSIX;

use Getopt::Long;
use Pod::Usage;

my $log='';
my $data_in='';
my $geneCols='';
my $out_file='';
my $spec='';
my $lookupCol='';


GetOptions(
    "log=s"                  => \$log,
    "expfile=s"              => \$data_in,
    "cols=s"                 => \$geneCols,  ##want to specify columns otherwise if user wants to preserve actual dates anywhere they'll get replaced
    "resultsfile=s"          => \$out_file,
    "species=s"              => \$spec,
    "lookup=s"		     => \$lookupCol,  ##this could be empty
#    "h|help"                 => \$help
) or pod2usage( -exitval => 2, -verbose => 2 );


#check parameters and options
my $debug = scalar(@ARGV);
use IO::Handle;
open OUTPUT, '>',$log or die "cant open this file for OUTPUT: $log. Computer says: $!\n";
open(my $results,'>',$out_file) or die "cannot open results file $out_file: $!\n";
open(my $allexpr, "<", $data_in) or die "Cannot open input file $data_in: $!\n";
my @Expression = <$allexpr>;
close($allexpr);


my @geneCols_ary = (split(',', $geneCols));
my $numCols = scalar @geneCols_ary;

if ($lookupCol) {print OUTPUT "User specified second identifier col for 1/2-Mar genes.\n\n";} ##DEBUG

my $human_yes = 0;  ##initialize human switch to 0 (default is mouse, otherwise need to convert symbol to uppercase)
if ($spec eq "human") {
    $human_yes = 1;
}
my $current2ndLookup_noquotes;
my $current2ndLookup;
for (my $i=0; $i<scalar @Expression; $i++) {
    my $tmp = scalar @Expression;
    my @linetmp = split('\t', $Expression[$i]);
    $linetmp[-1] = substr($linetmp[-1],0,-1); ##get rid of newline in last piece; will mess up matching
    if ($lookupCol) {
	##NEED TO ACCOUNT FOR COMMA-DELIMITED LISTS
	$current2ndLookup = $linetmp[$lookupCol-1]; ##This is 2nd gene identifier
	$current2ndLookup =~ s/"//g; ##Remove quotes if they're there
	my @stuff = split(',',$current2ndLookup); ##Need to consider comma-delim list (fairly common)
	$current2ndLookup = $stuff[0]; ##First in list should be somewhere in lookup file
    }

    for (my $j=0; $j<$numCols; $j++) {  ##IF $LOOKUP THEN NUMCOLS WILL BE 1 AND ONLY ONE TIME THROUGH LOOP
        my $currentGene = $linetmp[$geneCols_ary[$j]-1];
        $currentGene =~ s/"//g; ##Might have quotes here too
		
	my $match = qx(cat ./genesymbol_dateLUT.tab | awk '\$1 == "$currentGene"');  ##10-8-14 change
	my $debugL = length $match;
	my @matchAry;
        if ($debugL>0) {  ##FOUND IN THE FIRST LIST
            @matchAry = split('\t',$match);
	    $match =~ s///g; ##Try to fix the ^Ms at ends of lines
        } else {  ##CHECK IF THEY'RE 1-MAR OR 2-MAR:
	       if ($lookupCol) {
                if ($human_yes == 1) {
                        $match = qx(cat ./Mar1_2_LUT_human.txt | awk '\$1 == "$currentGene"' | awk '\$2 == "$current2ndLookup"');
                } else {
                        $match = qx(cat ./Mar1_2_LUT_mouse.txt | awk '\$1 == "$currentGene"' | awk '\$2 == "$current2ndLookup"');
                }
                @matchAry = split('\t',$match);
	     }
	}
	$debugL = length $match;
	if ($debugL > 0) {
		my $blah;
		if ($human_yes == 1) {    ##Replace date with gene symbol (2nd col in file)
                	$blah = uc substr($matchAry[-1],0,-1);  ##SHOULD BE ALWAYS LAST THING IN THE ROW
                	$blah =~ s///g;
			$linetmp[$geneCols_ary[$j]-1] = $blah;  ##SHOULD BE ALWAYS LAST THING IN THE ROW
                	print OUTPUT "Match found for $currentGene, replacing with $linetmp[$geneCols_ary[$j]-1]\n";
            	} else {
                	$blah = substr($matchAry[-1],0,-1);
			$blah =~ s///g;
                	$linetmp[$geneCols_ary[$j]-1] = $blah;
                	print OUTPUT "Match found for $currentGene, replacing with $linetmp[$geneCols_ary[$j]-1]\n";
            	}

	} else {
		##GIVE SOME OUTPUT TO HINT USER IF GENES ARE 1/2-MAR (REGARDLESS OF WHAT WAS CHOSEN). THIS WILL SLOW CODE DOWN THOUGH...
		my $match_h = qx(cat ./Mar1_2_LUT_human.txt | awk '\$1 == "$currentGene"');
		my $match_m = qx(cat ./Mar1_2_LUT_mouse.txt | awk '\$1 == "$currentGene"');
		my $debugL_h = length $match_h;
		my $debugL_m = length $match_m;
		if ( ($debugL_h>0) || ($debugL_m>0) ) { ##We have a 1/2-Mar gene but can't fix it
			print OUTPUT "In file is $currentGene. Cannot replace because ";
			if ($lookupCol) {
				print OUTPUT "second identifier, $current2ndLookup, is not in reference file.\n";
			} else {
				print OUTPUT "no second identifier column was specified.\n";
			}
		}
	}
	

    }
    print $results join("\t",@linetmp),"\n";
}

close $results;
close OUTPUT;
