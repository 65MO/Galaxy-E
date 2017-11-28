###############################################################################
# This script converts plate data from tabular to linear format.
# 
# Args:
# input file: 
# a text file containing a set of tabular data in vertical layout in either 384/96 well format, 
# typically generated from synergy or cellomics software.
#
# Returns:
# For each input file, a linear version of tabular data is returned with 
# "Well" column inserted as first column and "Table_<count> for all subsequent
# columns where <count> is ordinal number of tables in file. 
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
my $tabularPlateTable = $ARGV[0];
my $linearPlateTable =  $ARGV[1];

#open the input files
open (INPUT, "<", $tabularPlateTable) || die("Could not open file $tabularPlateTable \n");
open (OUTPUT1, ">", $linearPlateTable) || die("Could not open file $linearPlateTable \n");

#variable to store the name of the R script file
my $r_script;

# R script to implement the calcualtion of q-values based on multiple simultaneous tests p-values 	
# construct an R script file and save it in a temp directory
#chdir $tdir;
$r_script = "reformatPlatesTabularToLinear.r";

open(Rcmd,">", $r_script) or die "Cannot open $r_script \n\n"; 
print Rcmd "
	#options(show.error.messages = FALSE);
	
	#read the plates table
	tables <- scan(\"$tabularPlateTable\", sep=\"\\n\", what=\"character\", quiet = TRUE);
	
    # if there any lines which when all tabs/spaces are removed amounts to an empty line then remove this line
  	if(length(which(gsub(\"\\t|\\\\s\", \"\", tables) == \"\")) > 0) tables <- tables[-which(gsub(\"\\t|\\\\s\", \"\", tables) == \"\")];

	  # search for occurrences of the below column header line in the tables data.
	  colheads <- grep(\"^\\t 1 \\t 2 \\t 3 \\t 4 \\t 5 \\t 6 \\t 7 \\t 8 \\t 9 \\t 10 \\t 11 \\t 12 \\t 13 \\t 14 \\t 15 \\t 16 \\t 17 \\t 18 \\t 19 \\t 20 \\t 21 \\t 22 \\t 23 \\t 24 \", tables);
	  # if not found we assume the tables are 96-well
	  if(length(colheads) == 0) {
	    platetype <- 96;
	    colheads <- grep(\"^\\t 1 \\t 2 \\t 3 \\t 4 \\t 5 \\t 6 \\t 7 \\t 8 \\t 9 \\t 10 \\t 11 \\t 12 \", tables);
	    nc <- 12;
	    nr <- 8;
	  } else {
	 	# else dealing with 384-well
	    platetype <- 384;
	    nc <- 24;
	    nr <- 16;
	  }
	  # set up the structure of the output matrix
	  linearized.data <- matrix(NA, nrow=platetype, ncol=length(colheads)+1);
	  
	  # generate the well column
	  well.name <- NULL;
	  for(i in LETTERS[1:nr]) {
	    for(j in c(\"01\", \"02\", \"03\", \"04\", \"05\", \"06\", \"07\", \"08\", \"09\", 10:nc)) {
	      well.name <- c(well.name , paste(i, j, sep=\"\"));
	    }
	  }
	  
	  # set up the column names for the output matrix
	  colnames(linearized.data) <- c(\"\\\\#Well\", paste(\"Table\", 1:length(colheads), sep=\"_\"));
	  linearized.data[, \"\\\\#Well\"] <- well.name;
	  colnames(linearized.data)[1] <- sub(\"^.\", \"\", colnames(linearized.data)[1]);
	      
	  for(i in 1:length(colheads)) {
	    for(j in 1:nr) {
	      # for each row of current table split the data by tab.
	      tab.row <- strsplit(tables[colheads[i]+j], \"\\t\");
	      # assign the current row from the current table 
	      # the min part of code takes account for table rows which may not have the full set of values expected
	      linearized.data[((j-1)*nc+1):((j*nc)-(nc-min(nc+1, length(tab.row[[1]]))+1)), i+1] <- tab.row[[1]][2:min(length(tab.row[[1]]),(nc+1))];
	    }
	  }
	  linearized.data <- as.data.frame(linearized.data, stringsAsFactors=FALSE);
	  # ensure all columns excluding first one are numeric
	  #for(i in 2:ncol(linearized.data)) {
	  #  linearized.data[,i] <- as.numeric(linearized.data[,i]);
	  #}
	  
	  #save the linear plate data
	  write.table(linearized.data, file=\"$linearPlateTable\", quote=F, sep=\"\\t\", row.names=F);
	#eof\n";

close Rcmd;	

system("R --no-restore --no-save --no-readline < $r_script > $r_script.out");

#close the input and output files
close(OUTPUT1);
close(INPUT);
