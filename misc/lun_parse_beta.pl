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
#  # ./lun.pl <perfstat.log> <iter_from>-<itre_to>
#  ex) ./lun.pl hoge.log 1-10
#
#  ----------------------
### 
# 2014/03/03 v1.0  tk Initial Release
# 

use strict;
use POSIX;
use File::Basename qw/basename dirname/;
use Time::Local;

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
my $c_time;
my @gmt;
my @g_time;
my @array;
my $lun;
my $value;

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
open(FILE,">>./$basename.lun_$h");
print FILE "Time,lun-name,type,para,value,Iteration\n";
close(FILE);

open(R,"<$file");
while(<R>){
        if( (/BEGIN\sIteration\s$itres\s/ ... /END\sIteration\s$itree\s/) && (/^=.*$h.*perfstat_lun$/ ... /^PERFSTAT_EPOCH.*\d+$/) ){
                # Debug
                #open(W,">>./debug.log"); print W "$_"; close(W);

		if(/^lun:\/vol(\/.*)+:(read_ops|write_ops|other_ops|read_data|write_data|avg_read_latency|avg_write_latency):.*$/){

			@array = split/:/,$_;

			# Get Parameter , Values 
			$para = (split/:/,$_)[2];
			$value = (split/:/,$_)[3];
			$value =~ s/b\/s|ms|\/s//g;
			chomp($value);

			# Get parameter , type
			$lun = (split/\//,$array[1])[2];
			$type = (split/\//,$array[1])[3];

			# b/s -> kb/s
			if( $para =~ /read_data|write_data/ ){
				$value = int($value/1024);
			}

		
			# Create Iteration number
                        $itre = sprintf("Iteration-%0".$keta."d", $num_itre);

			# Create Record
			$rec = "$c_time,$lun,$type,$para,$value,$itre\n";
			#print $rec;


			open(FILE,">>./$basename.lun_$h");
				print FILE $rec;
			close(FILE);

		}elsif( /^TIME:.*\d$/ ){
			@gmt = split(/\s+/,$_);
			if($gmt[2] =~ /^[1-2]*[0-9]\D/) { $gmt[2] =~ s/\D//g; }
			@g_time = split(/:/,$gmt[4]);
			$c_time=&ch_time($g_time[2],$g_time[1],$g_time[0],$gmt[3],$gmt[2],$gmt[6],0);

			# DEBUG STDOUT
                        $itre = sprintf("Iteration-%0".$keta."d", $num_itre);
			print "\t$gmt[6] $gmt[2] $gmt[3] $gmt[4] ($c_time) ... $itre\n";

		}elsif( (/^PERFSTAT_EPOCH.*\d+$/) ){
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

## Time
sub ch_time{
        my ($sec,$min,$hh,$dd,$mm,$yy,$x) = @_;

        my $time_gmt;
        my $time_jst;
        my $t;
        my %num_of_mon = (
        Jan => 0, Feb => 1, Mar => 2, Apr => 3, May =>  4,  Jun =>  5,
        Jul => 6, Aug => 7, Sep => 8, Oct => 9, Nov => 10,  Dec => 11);

        if( $mm !~ /[A-Z][a-z][a-z]/ ) { $mm=$mm-1; }
        else{ $mm=$num_of_mon{$mm};}

        # Get unix time
        $time_gmt = timelocal($sec,$min,$hh,$dd,$mm,$yy);
        # From GMT to JST
        $time_jst = $time_gmt + 9*3600 + $x;

        # hour:min:sec
        #$t = strftime("%H:%M:%S", localtime($time_jst));
        # month-day hour:min:sec
        $t = strftime("%m-%d %H:%M:%S", localtime($time_jst));

        if($DEBUG){
                print "===========\n";
                print "Cnt\n\t$x\n";
                print "GMT\n\t$hh:$min:$sec\n";
                print "JST\n\t$t\n";
                print "===========\n";
        }

        return($t);
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
