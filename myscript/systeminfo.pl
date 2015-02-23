#!/usr/bin/perl
# 
# [Support]
#   Perfstat v7.38 , v7.39
#   7-Mode (8.0.2 , 8.1RC , 8.1.1 , 7.3.2)
# [Non Support]
#   7.2.3   
#
#   Linux
#
#   Iteration is larger than 1
#
# [Description]
# 	System 情報のみ抽出
# 
# [USAGE]
#  ----------------------
#        #./systeminfo.pl <perfstat.log> 
#  ----------------------
#
# < MEMO >
 
### Release Information ### 
# 2014/00/00 v1.00  tk Initial Release


use strict;
use POSIX;
use File::Basename qw/basename dirname/;
use Time::Local;

my $DEBUG=0;

my $file;
my @hosts;
my $host;
my $flag=1;
my $dot;
my $serial;
my $systemid;
my $nodename;
my $model;
my $rec;

$file = $ARGV[0];

# Check
if (($file eq "") || (! -f $file)){
	&error_out("Input File Error");
}

#############
### Main ####
#############

# Get Hostname
@hosts = &mhost("$file");


foreach my $h (@hosts){

print " --- Progress \"$h\" ... \n";

# Header
open(FILE,">./systeminfo_$h");
print FILE "Model,ONTAP,SystemID,Serial,Nodename\n";
close(FILE);

open(R,"<$file");
while(<R>){
        if( (/BEGIN\sIteration\s1\s/ ... /END\sIteration\s1\s/) && (/^=.*$h.*perfstat_system$/ ... /^PERFSTAT_EPOCH.*\d+$/) ){
                # Debug
                #open(W,">>./debug.log"); print W "$_"; close(W);

		if(/^system:system:system_model:(.*)$/){
			$model = $1;
		}elsif(/^system:system:ontap_version:(.*):\s.*$/){
			$dot = $1;	
		}elsif(/^system:system:serial_no:(.*)$/){
			$serial = $1;	
		}elsif(/^system:system:system_id:(.*)$/){
			$systemid = $1;	
		}elsif(/^system:system:hostname:(.*)$/){
			$nodename = $1;
		}
        }
}
close(R);
$rec = "$model,$dot,$systemid,$serial,$nodename\n";
#print "$rec";

open(FILE,">>./systeminfo_$h");
print FILE $rec;
close(FILE);

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
	my $str = shift;

        print STDERR "\nFailed ($str)\n";
        print STDERR "\t--- USAGE ---\n";
        print STDERR "\t#./systeminfo.pl <perfstat.log> \n";
        print STDERR "\tEx) ./all.pl hoge.log\n";
	print STDERR "\n";
	exit(1);
}

exit 0;

