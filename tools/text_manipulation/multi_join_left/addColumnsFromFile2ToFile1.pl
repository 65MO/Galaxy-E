#! /usr/bin/perl -w
#===============================================================================
#
#     FILENAME:  addColumnsFromFile2ToFile1.pl
#
#        USAGE:  see -help
#
#  DESCRIPTION:  This program adds columns in File 2 to File 1, 
#                if there are correnponding entries in File 1 
#
#       AUTHOR:  Ron Stewart
#      VERSION:  1.1
#      CREATED:  12/18/06 CDT
#===============================================================================

use lib '/opt/galaxy/galaxy-dist/tools/ngs_rna/Unreleased';  ##CMS ADDED 11-05-14, DIR CONTAINS CUSTOM MODULE

use strict;
use IO::File;
use GetOptWC;
# parsing the command line
my %optVarsIn = ();
# help information
$optVarsIn{'File1'} = './File1.txt`=s`Input file of genes to include';  
$optVarsIn{'File2'} = './File2.txt`=s`Input file to be added';
$optVarsIn{'cola1'} = '2`=f`first column to look for match in File1';
$optVarsIn{'colb1'} = '4`=f`second column to look for match in File1';
$optVarsIn{'cola2'} = '2`=f`first column to look for match in File2';
$optVarsIn{'colb2'} = '4`=f`second column to look for match in File2';
$optVarsIn{'file1FirstColToCopy'} = '-1`=f`first column to copy in File1';
$optVarsIn{'file1LastColToCopy'} = '-1`=f`last column to copy  in File1';
$optVarsIn{'file2FirstColToCopy'} = '-1`=f`first column to copy in File2';
$optVarsIn{'file2LastColToCopy'} = '-1`=f`last column to copy  in File2';
$optVarsIn{'HelpPrefix'} = 'This script is for adding entries in File2 to the corresponding entries in File1.';
$optVarsIn{'HelpSuffix'} = 'example call:  ./addColumnsFromFile2ToFile1.pl -File1=./esAndDiffMarkersWithSage20061211.txt -cola1=2 -calb1=4 -File2=./pan_whole_table_fold_ann.txt -cola2=1 -colb2=4`Note: Two input files should have title lines`NOTE:Files must be text files, NOT .xls files.  If you have an .xls file, save it as "Text(Windows) in Excel.';
my %retVars = ();
my $retVarsRef =  GetOptWC::getOptions(\%optVarsIn);
%retVars = %$retVarsRef;
if ($retVars{'HelpCalled'}) {
	   print "exiting now, help called\n";
	   exit;
}
my $File1 = $retVars{'File1'};
my $FHFile1;
$FHFile1 = IO::File->new("<$File1");

my $File2 = $retVars{'File2'};
my $FHFile2;
$FHFile2 = IO::File->new("<$File2");
my $File1name = $File1;
print "file1name: $File1name\n";
$File1name =~ s/[\.\/]/_/g;
print "file1name: $File1name\n";

my $File2name = $File2;
$File2name =~ s/[\.\/]/_/g;
#my $Out = $File1name.'.'.$File2name; # this can be too long in some cases
my $Out = "file1_file2.txt"; 
print" out is $Out\n";
my $OutFile = IO::File->new(">$Out");
my $cola1 = $retVars{'cola1'};
my $colb1 = $retVars{'colb1'};
my $cola2 = $retVars{'cola2'};
my $colb2 = $retVars{'colb2'};
my $firstColFile1 = $retVars{'file1FirstColToCopy'};
my $lastColFile1 = $retVars{'file1LastColToCopy'};
my $firstColFile2 = $retVars{'file2FirstColToCopy'};
my $lastColFile2 = $retVars{'file2LastColToCopy'};
my %genes2 = ();
my %genes4 = ();
my %genes4key = ();
my $lineCtr = 0;
my @cols = ();
my $firstLineFile2 = $FHFile2->getline();
$firstLineFile2 =~ s/\s+$//;
@cols = split "\t",$firstLineFile2;
my $numColFile2 = @cols;
if($firstColFile2==-1){
	$firstColFile2 = 0;
	$lastColFile2 = $numColFile2-1;
}
my @titleFile2 = @cols[$firstColFile2..$lastColFile2];
while (my $line = $FHFile2->getline()) {
	   $lineCtr++;
	   #$line =~ s/\s+$//;
	   $line =~ s/\R//g;  ##CMS 11-6-14
	   chomp($line);
	   @cols = split "\t",$line;
	   my $numCols = (@cols + 0);

	   #$cols[$cola2] = uc($cols[$cola2]); ##CMS 11-6-14
	   #$cols[$colb2] = uc($cols[$colb2]); ##CMS 11-6-14
	   $cols[$cola2] =~ s/ //g;
	   my $colsBSymbol = "";
	   if ($cols[$colb2] =~ /\"{0,1}CDS\; ([^\;]+);/) {
	   		$colsBSymbol = $1;
	   }
	   else {
	   		#if ($numCols == ($colb2 +1)) {  ##CMS COMMENTED OUT 11-6-14
			#print "$line\n";
			#print "Please check this line\n";
			#exit;
	   		#}  ##CMS END COMMENTS 11-6-14
	   		$cols[$colb2] =~ s/ //g;
	   		$colsBSymbol = $cols[$colb2];
	   }
	   if($numCols<$lastColFile2){
	   		for(my $i = $numCols;$i<$lastColFile2;$i++){
				$cols[$i] = "";
			}
	   }
	   
	   $genes2{$cols[$cola2]} = join("\t",@cols[$firstColFile2..$lastColFile2]);
	   $genes4{$colsBSymbol}->{$cols[$cola2]} = join("\t",@cols[$firstColFile2..$lastColFile2]);
	   $genes4key{$colsBSymbol}="x";
}
print "linectr: $lineCtr\n";
$lineCtr = 0;
@cols = ();
my $firstLineFile1 = $FHFile1->getline();
$firstLineFile1 =~ s/\s+$//;
@cols = split "\t",$firstLineFile1;
my $numColFile1 = @cols;
if($firstColFile1==-1){
	$firstColFile1 = 0;
	$lastColFile1 = $numColFile1-1;
}
#print "numcolsfile1: $numColFile1\n";
#print "lastcolsfile1: $lastColFile1\n";

my @titleFile1 = @cols[$firstColFile1..$lastColFile1];
#print "tf1:  @titleFile1\n";
#print "tf2:  @titleFile2\n";
#print "outfile: $OutFile\n";

print $OutFile join("\t",@titleFile1)."\t".join("\t",@titleFile2)."\n";
#my $numCol = $lastColFile1 - $firstColFile1 +1;
my $numCurrentLine =0;
while (my $line = $FHFile1->getline()) {
	   $lineCtr++;
	   $line =~ s/\s+$//;
	   my $selectedEntries;
	   @cols = split "\t",$line;
	   $numCurrentLine = $#cols;#[$firstColFile1..$LastColFile1];
	   #print "numcurrentline: $numCurrentLine\n";
	   $line = $line."\t";
	   if($numCurrentLine<$lastColFile1){
	        #print "in if\n";
			for(my $i =$numCurrentLine+1;$i<=$lastColFile1;$i++){
			    #print "in for. i=$i\n";
				$cols[$i]="";
				#$line = $line."\t";
			}
	   }
	   $selectedEntries = join("\t",@cols[$firstColFile1..$lastColFile1]);
	   my $numCols = (@cols + 0);
	   #$cols[$cola1] = uc($cols[$cola1]); ##CMS 11-6-14
	   #$cols[$colb1] = uc($cols[$colb1]); ##CMS 11-6-14
	   $cols[$cola1] =~ s/ //g;
	   my $colsBSymbol = "";
	   if ($cols[$colb1] =~ /\"{0,1}CDS\; ([^\;]+);/) {
	   		$colsBSymbol = $1;
	   }
	   else {
	   		#if ($numCols == ($colb1 +1)) {  ##CMS COMMENTED 11-6-14
			#	print"$line";
			#	print " please check this line\n";
			#	exit;
			#}  ##CMS END COMMENTS 11-6-14
			$cols[$colb1] =~ s/ //g;
			$colsBSymbol = $cols[$colb1];
	   }
	   if((exists ($genes2{$cols[$cola1]}) and $cols[$cola1] ne "N/A") or (exists ($genes2{$colsBSymbol}) and $colsBSymbol ne "N/A")  ) {
	        if (exists ($genes2{$cols[$cola1]})) {
	   		   print $OutFile "$selectedEntries"."\t".$genes2{$cols[$cola1]}."\n";
	   		}
	   		elsif (exists ($genes2{$colsBSymbol})) {
	   		   print $OutFile "$selectedEntries"."\t".$genes2{$colsBSymbol}."\n";
	   		}
	   		else {
	   		   print "WHOA, we've got a problem Here!!!!!\n";
	   		}     
	   }
	   elsif(exists ($genes4key{$colsBSymbol}) and $colsBSymbol ne "N/A" ) {
				foreach my $symbol (keys %{$genes4{$colsBSymbol}}){
					print $OutFile "$selectedEntries"."\t".$genes4{$colsBSymbol}->{$symbol}."\n";
				}
	   }
	   else {
			    print $OutFile "$selectedEntries"."\n";
	   }
}
exit;
