#!/usr/bin/perl 


use Getopt::Long;
use Pod::Usage;
use IO::File;
use Data::Dumper;

GetOptions(
    "join_file=s"             => \$data_in,
    "join_col=s"	     => \$coljoin,
    "time"                   => \$mTime,
    "q|quiet"                => \$quiet,
    "iteration=i"	     => \$I,
    "totalfiles=i"	     => \$N,
    "with_header=s"	     => \$header_yes,
    "input_name=s"	     => \$in_name,
    "resultsfile=s"	     => \$out_file,
#    "h|help"                 => \$help
) or pod2usage( -exitval => 2, -verbose => 2 );


#check parameters and options
my $debug = scalar(@ARGV);

$coljoin--;
#pod2usage(-msg => "To troubleshoot. ARGV should be @ARGV with $debug arguments in it.");
pod2usage(-msg => "Forward probability should be in [0, 1]!", -exitval => 2, -verbose => 2) if ($probF < 0 || $probF > 1);

$N++;

# #
use IO::Handle;
STDOUT->fdopen( \*OUTPUT, 'a' ) or die "cant open file $!\n";   # changing mode from 'w' to 'a' for multiple files in one run
STDERR->fdopen( \*ERROR,  'a' ) or die "cant open file $!\n";   # changing mode from 'w' to 'a' for multiple files in one run
# # #

my @options;

my $fileno = $I + 1; 

##Keeping track of the input files (one per iteration of this script) in an external file:
open $Filenames, '>>', "temp_filenames.txt" or die "cannot open the temporary file $!\n";
print $Filenames "$data_in\t";
print $Filenames "$coljoin\n";

if (($I==$N-1)&&($N>=2)) {
        ## At the end of the last iteration
	close($Filenames);
        

	##Read in file temp_filenames.txt
	open(my $tmpfile, "<", "temp_filenames.txt") or die "Cannot open temp file: $!";
	my @fileArray = <$tmpfile>;
	#unshift @fileArray,$conditions; ##don't need to do this since conditions aren't used here
	close($tmpfile) or die "ERROR: $!";

	
	##Need to send output file name to shell script:
	push @fileArray, $out_file;  ##adds out_file to the end of fileArray
	##Also need to send yes/no for keeping header:
	push @fileArray, $header_yes;


	##@fileArray has one file per line,output,header_yes, so $N+1 rows
	my $f=0;
	my @first;
	my @second;
	do {

		@first = split('\t',$fileArray[$f]);  ##was filename\tJoinCol

		##DEALING WITH HEADER OR NOT:
                if ($header_yes eq "no") {
			my $fh1;
                	$fh1 = IO::File->new("<$first[0]");
			my $line1file1 = $fh1->getline();
			$line1file1 =~ s/\s+$//;
			@cols = split "\t",$line1file1;
			my $numcols1 = @cols;
			my $head1;
			for (my $i=1; $i<$numcols1; $i++) {
				$head1.="C$i\t";
			}
			$head1.="C$numcols1\n";
			open(my $fh_sub, '>', './header1.txt') or die "ERROR: $!\n";
			print $fh_sub $head1;
			close $fh_sub;
			system("cat $first[0] >> ./header1.txt");  ##put header in front of file
			##now want to use ./header1.txt instead of what was in $first[0] earlier
			$first[0] = "./header1.txt";
		}
		


		@second = split('\t',$fileArray[$f+1]);

		if ($header_yes eq "no") {
                        my $fh2;
                        $fh2 = IO::File->new("<$second[0]");
                        my $line1file2 = $fh2->getline();
                        $line1file2 =~ s/\s+$//;
                        @cols = split "\t",$line1file2;
                        my $numcols2 = @cols;
                        my $head2;
                        for (my $i=1; $i<$numcols2; $i++) {
                                $head2.="C$i\t";
                        }
                        $head2.="C$numcols2\n";
                        open(my $fh_sub, '>', './header2.txt') or die "ERROR: $!\n";
			print $fh_sub $head2;
                        close $fh_sub;
			system("cat $second[0] >> ./header2.txt");
			$second[0]="./header2.txt";
                }

		system("./addColumnsFromFile2ToFile1.pl", "-File1=$first[0]", "-File2=$second[0]", "-cola1=$first[1]", "-cola2=$second[1]", "-colb1=$first[1]", "-colb2=$second[1]");
		$f+=2;
		system("mv file1_file2.txt joined.txt");
		if ($header_yes eq "no") {
			system("rm ./header2.txt");
			system("rm ./header1.txt");
		}
	} while ($f < 2);  ##FIRST TWO ONLY!!!
	
	for ($f; $f<$N; $f++) {
                my @current = split('\t',$fileArray[$f]);  ##was filename\tJoinCol

		if ($header_yes eq "no") {
                        my $fh;
                        $fh = IO::File->new("<$current[0]");
                        my $line1file = $fh->getline();
                        $line1file =~ s/\s+$//;
                        @cols = split "\t",$line1file;
                        my $numcols = @cols;
                        my $head;
                        for (my $i=1; $i<$numcols; $i++) {
                                $head.="C$i\t";
                        }
                        $head.="C$numcols\n";
                        open(my $fh_sub, '>', './header.txt') or die "ERROR: $!\n";
                        print $fh_sub $head;
                        close $fh_sub;
                        system("cat $current[0] >> ./header.txt");
                        $current[0]="./header.txt";
                }

                system("./addColumnsFromFile2ToFile1.pl","-File1=joined.txt", "-File2=$current[0]", "-cola1=$first[1]", "-cola2=$current[1]", "-colb1=$first[1]", "-colb2=$current[1]");
		system("mv file1_file2.txt joined.txt");
		if ($header_yes eq "no") {
			system("rm ./header.txt");
		}
        }
	
	system("mv joined.txt $fileArray[-2]");
	

	system("rm temp_filenames.txt");

}
elsif ($N<2) {  ##DO NOTHING
}



