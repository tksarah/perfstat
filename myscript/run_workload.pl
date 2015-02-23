#!/usr/bin/perl
# 

use strict;
use POSIX;
use File::Basename qw/basename dirname/;

my $DEBUG=0;

my $file;
my $type;
my $itres;
my $itree;
my $basename;
my @hosts;
my $num_hosts;
my @array;

my $flag=1;

$file = $ARGV[0];
$type = $ARGV[1];

# Check
if ($file eq ""){
	&error_out(1);
}elsif ($type !~ /nfsv3|nfsv4|cifs|fcp|iscsi/) {
	&error_out(2);
}elsif ($ARGV[2] !~ /\d+\-\d+/) {
	&error_out(3);
}else{
        ($itres,$itree)=split(/-/,$ARGV[2]);
        if($itres > $itree){
		&error_out(4);
        }
        $basename = basename $file;
}


my @workload_r = ($type . "_read_size_histo.0-511",
                $type . "_read_size_histo.512-1023",
                $type . "_read_size_histo.1K-2047",
                $type . "_read_size_histo.2K-4095",
                $type . "_read_size_histo.4K-8191",
                $type . "_read_size_histo.8K-16383",
                $type . "_read_size_histo.16K-32767",
                $type . "_read_size_histo.32K-65535",
                $type . "_read_size_histo.64K-131071",
                $type . "_read_size_histo.> 131071",
                );

my @workload_w = ($type . "_write_size_histo.0-511",
                $type . "_write_size_histo.512-1023",
                $type . "_write_size_histo.1K-2047",
                $type . "_write_size_histo.2K-4095",
                $type . "_write_size_histo.4K-8191",
                $type . "_write_size_histo.8K-16383",
                $type . "_write_size_histo.16K-32767",
                $type . "_write_size_histo.32K-65535",
                $type . "_write_size_histo.64K-131071",
                $type . "_write_size_histo.> 131071",
                );

if ($type eq "nfsv3" ){ $type="nfs"; }

#############
### Main ####
#############

# Get Hostname
@hosts = &mhost("$file");
$num_hosts = @hosts;

# Multihost start
foreach my $h (@hosts){

my @rioc=();
my @wioc=();

my $total=0;
my $rtotal=0;
my $wtotal=0;

my $sr=0;
my $sw=0;
my $rr=0;
my $rw=0;
my $seq_r=0;
my $seq_w=0;
my $rnd_r=0;
my $rnd_w=0;

#print "\n --- Progress \"$h\" ... \n";

open(R,"<$file");
while(<R>){
        if( (/BEGIN\sIteration\s$itres\s/ ... /END\sIteration\s$itree\s/) && (/^=.*$h.*perfstat_$type$/ ... /^PERFSTAT_EPOCH.*\d+$/) ){
                # Debug
                #open(W,">>./debug.log"); print W "$_"; close(W);

		if(/(nfsv3|cifs|fcp|iscsi|nfsv4)_(read|write)_size_histo\./){
			@array=split/:/,$_;

			# Read Histo
                        if($array[2] eq "$workload_r[0]"){
				$rioc[0] += $array[3];
			}elsif($array[2] eq "$workload_r[1]"){
				$rioc[1] += $array[3];
			}elsif($array[2] eq "$workload_r[2]"){
				$rioc[2] += $array[3];
			}elsif($array[2] eq "$workload_r[3]"){
				$rioc[3] += $array[3];
			}elsif($array[2] eq "$workload_r[4]"){
				$rioc[4] += $array[3];
			}elsif($array[2] eq "$workload_r[5]"){
				$rioc[5] += $array[3];
			}elsif($array[2] eq "$workload_r[6]"){
				$rioc[6] += $array[3];
			}elsif($array[2] eq "$workload_r[7]"){
				$rioc[7] += $array[3];
			}elsif($array[2] eq "$workload_r[8]"){
				$rioc[8] += $array[3];
			}elsif($array[2] eq "$workload_r[9]"){
				$rioc[9] += $array[3];
			# Write Histo
			}elsif($array[2] eq "$workload_w[0]"){
				$wioc[0] += $array[3];
			}elsif($array[2] eq "$workload_w[1]"){
				$wioc[1] += $array[3];
			}elsif($array[2] eq "$workload_w[2]"){
				$wioc[2] += $array[3];
			}elsif($array[2] eq "$workload_w[3]"){
				$wioc[3] += $array[3];
			}elsif($array[2] eq "$workload_w[4]"){
				$wioc[4] += $array[3];
			}elsif($array[2] eq "$workload_w[5]"){
				$wioc[5] += $array[3];
			}elsif($array[2] eq "$workload_w[6]"){
				$wioc[6] += $array[3];
			}elsif($array[2] eq "$workload_w[7]"){
				$wioc[7] += $array[3];
			}elsif($array[2] eq "$workload_w[8]"){
				$wioc[8] += $array[3];
			}elsif($array[2] eq "$workload_w[9]"){
				$wioc[9] += $array[3];
			}
		}
	}
}
close(R);

foreach (@rioc){$rtotal += $_;}
foreach (@wioc){$wtotal += $_;}
$total = $rtotal + $wtotal;
if ($total == 0 && $num_hosts == 1){
	print STDERR "$type : Workload is nothing. \n";
	print "0,0,0,0,NA,NA,NA,NA,";
	exit 1;
}elsif($total == 0 && $num_hosts == 2 , ){
	$flag=0;
}

if ($flag) {
$sr = ($rioc[6] + $rioc[7] + $rioc[8] + $rioc[9])*100/$total;
$sw = ($wioc[6] + $wioc[7] + $wioc[8] + $wioc[9])*100/$total;
$rr = ($rioc[0] + $rioc[1] + $rioc[2] + $rioc[3] + $rioc[4] + $rioc[5])*100/$total;
$rw = ($wioc[0] + $wioc[1] + $wioc[2] + $wioc[3] + $wioc[4] + $wioc[5])*100/$total;

$seq_r = floor($sr);
$seq_w = floor($sw);
$rnd_r = floor($rr);
$rnd_w = 100 - $seq_r - $seq_w - $rnd_r;
}

# Debug Output
#my $str="$h/$type";
#printf (" %-31s\t%5s\t%5s\t%5s\t%5s\n","Host/Type","RndR%","RndW%","SeqR%","SeqW%");
#printf (" %-31s\t%5d\t%5d\t%5d\t%5d\n",$str,$rnd_r,$rnd_w,$seq_r,$seq_w);

if( $num_hosts > 1 ){
	print "$rnd_r,$rnd_w,$seq_r,$seq_w,";
}else{
	print "$rnd_r,$rnd_w,$seq_r,$seq_w,NA,NA,NA,NA,";
}

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
        print "# ./output.pl <perfstat.log> <type> <iteration> \n";
        print "Type is nfsv3|nfsv4|cifs|fcp|iscsi \n\n";
        print "Ex) ./output.pl hoge.log nfsv4 1-10 \n";
	print "\n";
	exit(1);
}

exit 0;
