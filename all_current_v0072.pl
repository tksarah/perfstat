#!/usr/bin/perl
# 
# [Support]
#   Perfstat v7.38 , v7.39
#   7-Mode (8.0.2 , 8.1RC , 8.1.1 , 7.3.2)
#   
#   Linux
#
#   Iteration is larger than 1
#
# [Description]
# 	Iteration での sysstat から秒単位の情報をリストで出力します。 
# 
# [USAGE]
#  ----------------------
#        #./all_alpha.pl <perfstat.log> <iteration> 
#        Ex) ./all_alpha.pl hoge.log 1-10
#  ----------------------
#
# < MEMO >
 
### Release Information ### 
# 2014/02/08 v0.1   tk alpha Release
# 2014/02/14 v0.2   tk Add "Time" column
# 2014/02/15 v0.3   tk Multihost Support 
# 2014/02/19 v0.4   tk Add "Iteration" column, BugFix
# 2014/02/22 v0.5   tk Add "Progress STDOUT"
# 2014/02/24 v0.61  tk Multihost Bugfix 
# 2014/02/25 v0.7   tk Bugfix (range)
# 2014/02/25 v0.71  tk Add "CPtype"
# 2014/03/20 v0.72  tk Adjust output


use strict;
use POSIX;
use File::Basename qw/basename dirname/;
use Time::Local;

# Debug 
if (-f "./log.log"){ unlink "./log.log"; }
my $DEBUG=0;

my $file;
my $itre;
my $itres;
my $itree;
my $num_itre;
my $keta = 3;
my @hosts;
my $dot;
my $basename;
my @values;
my $cnt=0;
my $c_time;
my @gmt;
my @g_time;
my $i;
my $cptype;

$file = $ARGV[0];

# Check
if (($file eq "") || (! -f $file)){
	&error_out("Input File Error");
}elsif ($ARGV[1] !~ /\d+\-\d+/) {
	&error_out("Input Iteration Error -1");
}else{
        ($itres,$itree)=split(/-/,$ARGV[1]);
        if($itres > $itree){
		&error_out("Input Iteration Error -2");
        }
        $basename = basename $file;
}

#############
### Main ####
#############

# Get Hostname
@hosts = &mhost("$file");
# Select Header
my ($header,$f) = &getheader("$file","$hosts[0]");

foreach my $h (@hosts){

# Initialize for iteration start point
$num_itre = $itres;

print "Progress \"$h\"\n";

open(R,"<$file");
while(<R>){
	if( (/BEGIN\sIteration\s$itres\s/ ... /END\sIteration\s$itree\s/) && (/^=.*$h.*sysstat_1sec.out$/ ... /^--$|^=.*version.out$/) ){
                # Debug
                # open(W,">>./log.log"); print W "$_"; close(W);

		if( /^\s{1,3}\d{1,3}%.*\d+$/ ){
			@values = split(/\s+/,$_);
                        if($f){
                                $cptype = $values[17];
                        }else{
                                $cptype = $values[15];
                        }

			# Exclude non-numeric
			for ($i=1;$i<$#values;$i++){
				$values[$i] =~ s/\D$//;
			}

			$cnt++;
			# Get JST Time
			# $sec,$min,$hh,$dd,$mm,$yy,$cnt
			$c_time=&ch_time($g_time[2],$g_time[1],$g_time[0],$gmt[3],$gmt[2],$gmt[6],$cnt);
	
			open(FILE,">>./sysstat_$h");
			if(!-s "./sysstat_$h" ) { print FILE "$header\n"; }

			if($f){
				print FILE "$c_time,";
				print FILE "$values[1],";
				print FILE "$values[2],";
				print FILE "$values[3],";
				print FILE "$values[6],";
				print FILE "$values[7],";
				print FILE "$values[8],";
				print FILE "$values[9],";
				print FILE "$values[10],";
				print FILE "$values[11],";
				print FILE "$values[15],";
                                print FILE "$cptype,";
				print FILE "$values[18],";
				print FILE "$values[19],";
				print FILE "$values[20],";
				print FILE "$values[21],";
				print FILE "$values[22],";
				print FILE "$values[23],";
				print FILE "$values[24],";
				print FILE "$values[25],";
				print FILE "$values[26],";
				print FILE "$itre\n";
			}else{
				print FILE "$c_time,";
				print FILE "$values[1],";
				print FILE "$values[2],";
				print FILE "$values[3],";
				print FILE "$values[6],";
				print FILE "$values[7],";
				print FILE "$values[8],";
				print FILE "$values[9],";
				print FILE "$values[13],";
                                print FILE "$cptype,";
				print FILE "$values[16],";
				print FILE "$values[17],";
				print FILE "$values[18],";
				print FILE "$values[19],";
				print FILE "$values[20],";
				print FILE "$values[21],";
				print FILE "$values[22]";
				# For "OTHER"
				if($#values > 22){ print FILE ",$values[23],$itre\n"; }
				else{ print FILE ",$itre\n"; }
			}
			close(FILE);

		}elsif( /^Begin\:.*$/ ){
			# Get GMT
			@gmt = split(/\s+/,$_);
			if($gmt[2] =~ /^[1-2]*[0-9]\D/) { $gmt[2] =~ s/\D//g; }
			@g_time = split(/:/,$gmt[4]);
			# Incremental seconds between Iteration start and end
			$cnt=0;
			# Get JST 
			$c_time=&ch_time($g_time[2],$g_time[1],$g_time[0],$gmt[3],$gmt[2],$gmt[6],$cnt);

			$itre = sprintf("Iteration-%0".$keta."d", $num_itre);
			print "\t$gmt[6] $gmt[2] $gmt[3] $gmt[4] ($c_time) ... $itre\n";

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

## Header
sub getheader{
	# Sysstat Format
	# DOT 8.0 < x <= 8.1 : +OTHER
	# DOT 8.1.1 <= +OTHER,+HDD,+SSD
	
	my $file = shift;
	my $host = shift;
	my $header = "Time,CPU,NFS,CIFS,Net-In,Net-Out,DiskRead,DiskWrite,CacheHit,CPtype,DiskUtil,OTHER,FCP,iSCSI,FCP-In,FCP-Out,iSCSI-In,iSCSI-Out,Iteration";
	my $f = 0;

	open(R,"<$file") || return 0;
	while(<R>){
		if( (1 ... 100) &&  (/^FILEROS.*$/)){
			($dot) = $_ =~ m/^FILEROS\,\s+$host\,\s+ONTAP(.*)$/;
			chomp $dot;
			if($dot =~ /(^8\.[1]\.[123456789])|(^8\.[234].*)/ ){
				$header = "Time,CPU,NFS,CIFS,Net-In,Net-Out,HDDRead,HDDWrite,SSDRead,SSDWrite,CacheHit,CPtype,HDDUtil,SDDUtil,OTHER,FCP,iSCSI,FCP-In,FCP-Out,iSCSI-In,iSCSI-Out,Iteration";
				$f=1;
			}elsif($dot =~ /^7\.\d\.\d$/ ){
				$header = "Time,CPU,NFS,CIFS,Net-In,Net-Out,DiskRead,DiskWrite,CacheHit,CPtype,DiskUtil,FCP,iSCSI,FCP-In,FCP-Out,iSCSI-In,iSCSI-Out,Iteration";
			}
		close(R);
		
		if($DEBUG){
		print "DOT Version:\n";
		print "\t$dot\n";
		print "Header,Flag:\n";
		print "\tHEADER=$header\n";
		print "\tF=$f\n";
		}

		return($header,$f);
		}
	}
}

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
	my $str = shift;

        print STDERR "\nFailed ($str)\n";
        print STDERR "\t--- USAGE ---\n";
        print STDERR "\t#./all.pl <perfstat.log> <iteration> \n";
        print STDERR "\tEx) ./all.pl hoge.log 1-10 \n";
	print STDERR "\n";
	exit(1);
}

exit 0;

