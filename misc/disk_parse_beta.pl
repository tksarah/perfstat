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
#  # ./disk.pl <perfstat.log> <iter_from>-<itre_to>
#  ex) ./disk.pl hoge.log 1-10
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
my $para;
my $itre;
my $itres;
my $itree;
my $num_itre;
my $keta = 3;
my @hosts;
my $basename;
my @array;
my $value;
my %hash;

my $flag=1;
my $aggr;
my $plex;
my $rg;

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

# Get Disk Type
%hash=&get_disk_type($h,$file);

# Initialize for iteration start point
$num_itre = $itres;

print "\n --- Progress \"$h\" ... \n";

# Header
open(FILE,">>./$basename.disk_$h");
print FILE "DriveID,Type,Util,ReadLatency,WriteLatency,Aggr,Rg,Iteration\n";
close(FILE);

open(R,"<$file");
while(<R>){
        if( (/BEGIN\sIteration\s$itres\s/ ... /END\sIteration\s$itree\s/) && (/^=.*$h.*\/statit.out$/ ... /^=.*\/stats.out$/) ){
                # Debug
                #open(W,">>./debug.log"); print W "$_"; close(W);

		# Only Active Disk on Controller
		if( (/^disk.*gwrites-chain-usecs$/ ... /^Aggregate\sstatistics:$/) &&  /^\d\D\.\d+.*$/ ){
			# array0->id , array1->ut, array5->readlatency , array8->writelatency
			@array = split/\s+/,$_;

			# Create Iteration number
			$itre = sprintf("Iteration-%0".$keta."d", $num_itre);

			# Create Record ->
			# DriveID,Type,Util,ReadLatency,WriteLatency,Rg,Aggr,Iteration
			# ReadLatency/WriteLatency = \d or "."
			$rec = "$array[0],$hash{$array[0]},$array[1],$array[5],$array[8],$aggr,$rg,$itre\n";

			# Debug
			#print "$rec";

			open(FILE,">>./$basename.disk_$h");
			print FILE $rec;
			close(FILE);
		
		# ex /<aggrN>/<plexN>/<rgN>:
		}elsif( /^\/(.*)\/(.*)\/(.*):$/ ){

			$aggr=$1;$plex=$2;$rg=$3;

                }elsif( /^=.*\/stats.out$/ ){
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

## Get Disk Type SAS or SATA
sub get_disk_type {

	my $host = shift;
	my $file = shift;
	my $disk_id;
	my $disk_type;
	my %dhash;

	open(R,"<$file") || return 0;
	while(<R>){

        	if( (/BEGIN\sIteration\s1\s/ ... /END\sIteration\s1\s/) && (/^=.*$host.*sysconfig\s-r$/ ... /^PERFSTAT_EPOCH.*\d+$/) ){
			# Debug
			#open(W,">>./debug.log"); print W "$_"; close(W);

			if (/^\s+(dparity|parity|data).*$/){
				#print "$_";
				$disk_id = (split/\s+/,$_)[2];
				$disk_type = (split/\s+/,$_)[8];
				$dhash{$disk_id}=$disk_type;	
			}
		}
	}
	close(R);
	return(%dhash);
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
