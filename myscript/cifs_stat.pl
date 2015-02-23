#!/usr/bin/perl
# 
# [Support]
#   Perfstat v7.38 , v7.39
#     7-Mode
#   
#   Linux
#
#   Iteration is larger than 1
#   Multihost is not supported
#  
# [USAGE]
#  ----------------------
#  # ./cifs_stat.pl <perfstat.log> <iter_from>-<itre_to>
#  ex) ./cifs_stat.pl hoge.log 1-10
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
my $itre;
my $itres;
my $itree;
my $num_itre;
my $keta = 3;
my @hosts;
my $basename;

my $vfiler;
my $type;
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

print " --- Progress \"$h\" ... \n";

# Header
open(FILE,">./cifs_$h");
print FILE "Vfiler,CIFS-Stats,Value,Iteration\n";
close(FILE);

open(R,"<$file");
while(<R>){
        if( (/BEGIN\sIteration\s$itres\s/ ... /END\sIteration\s$itree\s/) && (/^=.*$h.*perfstat_cifs_stats$/ ... /^PERFSTAT_EPOCH.*\d+$/) ){
                # Debug
                #open(W,">>./debug.log"); print W "$_"; close(W);

		# cifs_stats:vfiler0:curr_sess_cnt:364
		if(/^cifs_stats:(.*):(.*):(\d+)$/){
			$vfiler = $1;
			$type = $2;
			$value = $3;

			# Create Iteration number
                        $itre = sprintf("Iteration-%0".$keta."d", $num_itre);
		
			$rec = "$vfiler,$type,$value,$itre\n";

			open(FILE,">>./cifs_$h");
				print FILE $rec;
			close(FILE);

		}elsif( /^PERFSTAT_EPOCH.*\d+$/ ){
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
