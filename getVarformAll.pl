#!/usr/bin/env perl

use warnings;
use strict;
use FindBin;

sub main_usage{
    print <<"end_of_usage";

Usage
    $FindBin::Script <in.raw.vcf>

Description
    Remove redundant loci (ALT = <X> or .) for raw VCF file

end_of_usage
    exit;
}

sub main{
    main_usage unless @ARGV == 1;
    my $infile = shift @ARGV;
    open my $fh, $infile or die $!;
    while(<$fh>){
        if(/^#/){
            print;
            next;
        }
        my @f = split /\t/;
        my $alt = $f[4];
        next if $alt eq '<X>' or $alt eq '.';
        print;
    }
    close $fh;
}

main unless caller;

__END__
