package mathSunhh; 
#BEGIN {
#	push(@INC,'/usr/local/share/perl5/'); 
#}
# This is a package storing sub functions. 
# So there isn't objects created. 
use strict; 
use warnings; 
use Statistics::Descriptive; 
use Exporter qw(import);
our @EXPORT = qw(ins_calc);
our @EXPORT_OK = qw();


# Function: ins_avg ()
# Description: For calculating insert sizes. 
#              Following Heng Li's bwa method (Estimating Insert Size Distribution). 
#              But the max/min distance of INS are only using 6 * sigma values. 
#              http://linux.die.net/man/1/bwa
#              BWA estimates the insert size distribution per 256*1024 read pairs. It first collects pairs of reads with both ends mapped with a single-end quality 20 or higher and then calculates median (Q2), lower and higher quartile (Q1 and Q3). It estimates the mean and the variance of the insert size distribution from pairs whose insert sizes are within interval [Q1-2(Q3-Q1), Q3+2(Q3-Q1)]. The maximum distance x for a pair considered to be properly paired (SAM flag 0x2) is calculated by solving equation Phi((x-mu)/sigma)=x/L*p0, where mu is the mean, sigma is the standard error of the insert size distribution, L is the length of the genome, p0 is prior of anomalous pair and Phi() is the standard cumulative distribution function. For mapping Illumina short-insert reads to the human genome, x is about 6-7 sigma away from the mean. Quartiles, mean, variance and x will be printed to the standard error output.
# Input      : (\@ins_value_array)
# Output     : (\%hash_of_values) 
#              keys = qw(Q1 Q3 interval_low interval_high interval_mean interval_median interval_var interval_stdev limit_low limit_high)
sub ins_calc {
	my $r_arr = shift; 
	my %back; 
	my $stat = Statistics::Descriptive::Full->new();
	$stat->add_data(@$r_arr); 
	$back{'Q1'} = $stat->quantile(1); 
	$back{'Q3'} = $stat->quantile(3); 
	$back{'interval_low'}  = $back{'Q1'} - 2 * ($back{'Q3'}-$back{'Q1'}); 
	$back{'interval_high'} = $back{'Q3'} + 2 * ($back{'Q3'}-$back{'Q1'}); 
	
	$stat->clear(); 
	my @sub_arr; 
	for my $ta (@$r_arr) {
		$ta >= $back{'interval_low'} and $ta <= $back{'interval_high'} and push(@sub_arr, $ta); 
	}
	$stat->add_data(@sub_arr); 
	$back{'interval_mean'}  = $stat->mean(); 
	$back{'interval_median'} = $stat->median(); 
	$back{'interval_var'}   = $stat->variance(); 
	$back{'interval_stdev'} = $stat->standard_deviation(); 
	$back{'limit_low'}  = $back{'interval_mean'} - 6 * $back{'interval_stdev'}; 
	$back{'limit_high'} = $back{'interval_mean'} + 6 * $back{'interval_stdev'}; 
	$stat->clear(); 
	return \%back; 
}

1; 

