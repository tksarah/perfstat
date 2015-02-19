#!/usr/bin/perl
# 
# [Support]
#   Perfstat v7.38 , v7.39
#     7-Mode
#   
#   Linux
#
#   Iteration is larger than 1
#  
# [USAGE]
#  ----------------------
#  # ./throughput.pl <perfstat.log> <iter_from>-<itre_to>
#  ex) ./throughput.pl hoge.log 1-10
#
#  ----------------------
### 
# 2014/03/03 v1.0  tk Initial Release
# 

use strict;
use POSIX;
use File::Basename qw/basename dirname/;

my $DEBUG=0;

my $file;
my $type;
my $itre;
my $itres;
my $itree;
my $num_itre;
my $keta = 3;
my @hosts;
my $basename;
my @array;
my $rw;
my $rec;

$file = $ARGV[0];

# Check
if ($file eq ""){
	&error_out(1);
}elsif ($ARGV[1] !~ /\d+\-\d+/) {
	&error_out(2);
}else{
        ($itres,$itree)=split(/-/,$ARGV[1]);
        if($itres > $itree){
		&error_out(3);
        }
        $basename = basename $file;
}


#############
### Main ####
#############

# Get Hostname
@hosts = &mhost("$file");

# Multihost start
foreach my $h (@hosts){

# Initialize for iteration start point
$num_itre = $itres;

print "\n --- Progress \"$h\" ... \n";

# Header
open(FILE,">>./$basename.throughput_$h");
print FILE "Type,Write-Throughput,Read-Throughput,Iteration\n";
close(FILE);

open(R,"<$file");
while(<R>){
        if( (/BEGIN\sIteration\s$itres\s/ ... /END\sIteration\s$itree\s/) && (/^=.*$h.*perfstat_(fcp|iscsi)$/ ... /^PERFSTAT_EPOCH.*\d+$/) ){
                # Debug
                #open(W,">>./debug.log"); print W "$_"; close(W);

		if(/^.*:(fcp|iscsi)_(read|write)_data:\d+b\/s$/){
			$type = $1;
			$rw = $2;
			# Get throughput (b/s)
			@array=split/:/,$_;
			$array[3] =~ s/b\/s//g;
			chomp($array[3]);

			# b/s -> kb/s
			$array[3] = int($array[3]/1024);

			# Create Iteration number
                        $itre = sprintf("Iteration-%0".$keta."d", $num_itre);
		
			if($rw eq "write"){
				$rec = "$type,$array[3]";
				#print "$type,$array[3]";
			}else{
				#print ",$array[3],$itre\n";
				$rec = ",$array[3],$itre\n";
			}
			open(FILE,">>./$basename.throughput_$h");
				print FILE $rec;
			close(FILE);

		}elsif( (/^PERFSTAT_EPOCH.*\d+$/) && ($type eq "iscsi") && ($rw eq "read") ){
			# Incremental Iteration
			$num_itre++;
		}

	}
}
close(R);


}
# Multihost end


##################
### Functions ####
##################

## Multihost
sub mhost{

        my $file = shift;
        my @lines;
        my @r_hosts;
        my $x;

        open(R,"<$file") || return 0;
        while(<R>){
                if( (1 ... 80) && (/^COMMAND_LINE\,.*$/) ){
                        @lines = split /\s+/, $_;
                        for ($x=1;$x<$#lines;$x++){
                                if ( $lines[$x] =~ /^.*-f$/ ) {
                                        @r_hosts = split(/,/, $lines[$x+1]);
                                }
                        }

                close(R);

                if($DEBUG){ foreach my $x (@r_hosts) { print "Hosts:\n";print "\t$x\n"; } }

                return(@r_hosts);
                }
        }
}

## Error
sub error_out{
	my $f = shift;

        print "\nFailed ($f)\n";
        print "--- USAGE ---\n";
        print "# ./output.pl <perfstat.log> <iteration> \n";
        print "Ex) ./output.pl hoge.log 1-10 \n";
	print "\n";
	exit(1);
}

exit 0;
