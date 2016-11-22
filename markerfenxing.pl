#!/usr/bin/env perl

use warnings;
use strict;
use FindBin;
use Getopt::Long;
our $out_suffix = ".genotypeChecked.pop";


sub main_usage {
    print <<"end_of_usage";

Usage
    $FindBin::Script -i <in.geno.gz> -o out_prefix

Description
    Convert genotypes
    0/0 => AA,
    0/1 => AB, 1/1 => BB
    0/2 => AC, 1/2 => BC, 2/2 => CC
    0/3 => AD, 1/3 => BD, 2/3 => CD, 3/3 => DD

end_of_usage
    exit;
}


sub main {
    main_usage unless @ARGV;
    my ($in, $out);
    GetOptions(
        "in|i=s" => \$in,
        "out|o=s" => \$out
    );

    my ($in_fh, $out_fh) = make_filehandle($in, $out);

    my %genotype = qw(
        0/0 AA
        0/1 AB 1/1 BB
        0/2 AC 1/2 BC 2/2 CC
        0/3 AD 1/3 BD 2/3 CD 3/3 DD
    );
    while(<$in_fh>){
        next if /^\s*$/ or /^\s*#/;
        chomp;
        my @f = split /\t/;
        print join("\t", $f[0], map{$genotype{$_} // $_}@f[1..$#f])."\n";
    }

}

main unless caller;

############################################################

sub make_filehandle {
    my ($in, $out) = @_;
    my $in_fh;
    if($in =~ /\.gz/){
        open $in_fh, "gzip -dc $in |" or die $!;
    }
    else{
        open $in_fh, $in or die $!;
    }

    my $out_fh;
    if($out){
        open my $out_fh, "| gzip -c > $out$out_suffix" or die $!;
    }
    else{
        $out_fh = \*STDOUT;
    }
    return ($in_fh, $out_fh);
}

__END__
