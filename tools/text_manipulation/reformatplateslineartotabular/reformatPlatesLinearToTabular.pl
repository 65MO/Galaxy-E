###############################################################################
# This script converts plate data from linear to tabular format.
# 
# Args:
# input file: 
# a text file containing a set of linear data in either 384/96 well format, 
#
# Returns:
# For each input file, a tabular version of the data is returned
# in the same format typically generated from synergy or cellomics software. 
#
# Author: jason ellul
###############################################################################

use strict;
use warnings;
use IO::Handle;
use File::Temp qw/ tempfile tempdir /;
my $tdir = tempdir( CLEANUP => 0 );

# check to make sure having correct input and output files
my $usage = "usage: reformatPlatesTabularToLinear.pl [TABULAR.in] [TABULAR.out] \n";
die $usage unless @ARGV == 2;

#get the input arguments
my $linearPlateTable = $ARGV[0];
my $tabularPlateTable =  $ARGV[1];

#open the input files
open (INPUT, "<", $linearPlateTable) || die("Could not open file $linearPlateTable \n");
open (OUTPUT1, ">", $tabularPlateTable) || die("Could not open file $tabularPlateTable \n");

#variable to store the name of the R script file
my $r_script;

# R script to implement the calcualtion of q-values based on multiple simultaneous tests p-values 	
# construct an R script file and save it in a temp directory
chdir $tdir;
$r_script = "reformatPlatesLinearToTabular.r";

open(Rcmd,">", $r_script) or die "Cannot open $r_script \n\n"; 
print Rcmd "
	#options(show.error.messages = FALSE);
	
	#read the plates table
	#tables <- read.table(\"$linearPlateTable\", sep=\"\\t\", head=T, comment=\"\");
	tablesTMP <- scan(\"$linearPlateTable\", sep=\"\\n\", what=\"character\", quiet = TRUE);
	tmp <- strsplit(tablesTMP[1], \"\t\")[[1]];
	tables <- matrix(\"\", nrow=length(tablesTMP)-1, ncol=length(tmp))
	colnames(tables) <- tmp;
	for(i in 2:length(tablesTMP)) {
		tmp <- strsplit(tablesTMP[i], \"\t\")[[1]];
		if(length(tmp) > ncol(tables)) stop(paste(\"Error: Row\", i, \"has more columns than the header\"));
		tables[i-1, 1:length(tmp)] <- tmp;
	}
	tables <- as.data.frame(tables, stringsAsFactors=F);
	
	if(ncol(tables) < 2) {
		stop(\"The first column of the table must contain the well ID from A01 to either H12 or P24 depending on the number of wells.\")
	}

	# check if the plate is in 96 or 384 well format
	if(nrow(tables) == 96) {
		nc <- 12;
		nr <- 8;	
	} else if(nrow(tables) == 384) {
		nc <- 24;
		nr <- 16;
	} else {
		stop(\"Table is not for a 96 or 384 well plate. Please ensure you either have 96 or 384 rows plus a header.\")
	}

	# for each table
	for(i in 2:ncol(tables)) {
		# write the name of the table
		write(paste(colnames(tables)[i], sep=\"\"), file=\"$tabularPlateTable\", append=T);
		write(\"\", file=\"$tabularPlateTable\", append=T);
		# the column header
		write(paste(\"\\t\", paste(1:nc, collapse=\"\\t\"), sep=\"\"), file=\"$tabularPlateTable\", append=T);
		# replace any NAs with blank
		if(any(is.na(tables[,i]))) tables[which(is.na(tables[,i])),i] <- \"\";
		# for each row print the values
		curr <- 0;
		for(j in LETTERS[1:nr]) {
			write(paste(j, \"\\t\", paste(tables[(curr+1):(curr+nc), i], collapse=\"\\t\"), sep=\"\"), file=\"$tabularPlateTable\", append=T);
			curr <- curr + nc;
		}
		# if we are at the last table do not add an extra line
		if(i != ncol(tables)) write(\"\", file=\"$tabularPlateTable\", append=T);
	}
	#eof\n";

close Rcmd;	

system("R --no-restore --no-save --no-readline < $r_script > $r_script.out");

#close the input and output files
close(OUTPUT1);
close(INPUT);
