#!/usr/bin/perl 
use strict; 

# jellyfish-2.0 query P1_Cor1st_1k_m81.jf GTCGATTAAATACGCAAGTTTGCCACTAGCTGTAGCAGCACTGTCTACGAGTCACGAGATGATGTACAAATGACCGCATAGCGCAGTGGATTAGCGCCTCTGACTTCGGATCAGAAGGTTGTGGGTTTGACTCCCACTGTGGTCATCTGT
my $db_jf = 'P1_Cor1st_1k_m61.jf'; 
$db_jf = 'P1_Cor1st_3h5h1k_m61.jf'; 
my $exe_jf2 = '$HOEM/src/Assemble/MaSuRCA/MaSuRCA-2.2.2/bin/jellyfish-2.0'; 
my $min_2nd_dep = 1;
$min_2nd_dep = 4;


my $init_k = 'CATCTCGTGACTCGTAGACAGTGCTGCTACAGCTAGTGGCAAACTTGCGTATTTAATCGA'; 
my $kl = 60; 

$init_k = 'ACATGAAAATACATTTAAGTTCCATATGCATTTCATGACATGACTCGAGAATACTATGTGTATACATGGCATCAACCAAC'; 
$init_k = shift; 
$init_k = substr($init_k, 0, $kl); 
my $prev_k = $init_k; 

my $elong = $init_k; 

for (my $i=0; $i<1000; $i++) {
	my @qry_kc; 
	my $prev_k_rc = reverse($prev_k); 
	$prev_k_rc =~ tr/ATGC/TACG/; 
	for my $addBp (qw/A T G C/) {
		my $addBp_rc = $addBp; 
		$addBp_rc =~ tr/ATGC/TACG/; 
		my $qry_c = `$exe_jf2 query $db_jf ${prev_k}$addBp`; 
		chomp($qry_c); 
		$qry_c =~ m/^(\S+)\s+(\d+)$/ or die "fadsf\n"; 
		my ($res_seq, $res_c) = ($1, $2); 
		$res_c > 0 or next; 
		if ($res_seq =~ m/^${prev_k}$addBp$/) {
			push(@qry_kc, [$addBp, $res_c]); 
		}elsif ($res_seq =~ m/^${addBp_rc}${prev_k_rc}$/) {
			push(@qry_kc, [$addBp, $res_c]); 
		}else{
			die "Stop by noMatch: $exe_jf2 query $db_jf ${prev_k}$addBp\nk1=${prev_k}$addBp\nk2=${addBp_rc}${prev_k_rc}\n"; 
		}
	}
	# Find best addBp; 
	if (scalar(@qry_kc) == 0) {
		print STDOUT "LongestBefore=$elong\n"; 
		die "Stop. Cannot extend.\n"; 
	} elsif (scalar(@qry_kc) == 1) {
		$elong = "$elong$qry_kc[0][0]"; 
		$prev_k = substr("${prev_k}$qry_kc[0][0]", 1, $kl); 
	} else {
		@qry_kc = sort { $b->[1] <=> $a->[1] } @qry_kc; 
		if ($qry_kc[0][1]*0.8 <= $qry_kc[1][1] or $qry_kc[1][1] >= $min_2nd_dep) {
			my $ratio = sprintf("%.5f", $qry_kc[1][1]/$qry_kc[0][1]); 
			my $tmp_tag = '';
			$ratio >= 0.3 and $tmp_tag = '*'; 
			&tsmsg("[Err] Multiple selection at [$i+1: $qry_kc[0][0]:$qry_kc[0][1] $qry_kc[1][0]:$qry_kc[1][1] $ratio $tmp_tag] $elong\n"); 
		}
		$elong = "$elong$qry_kc[0][0]"; 
		$prev_k = substr("${prev_k}$qry_kc[0][0]", 1, $kl); 
	}
	&tsmsg("[Msg] At [$i+1: KD=$qry_kc[0][1]] Elong=$elong\n"); 
}

print STDOUT "Longest=$elong\n"; 

sub tsmsg {
	my $tt = scalar(localtime()); 
	print STDERR join('', "[$tt]", @_); 
}
