#!/usr/bin/env perl

use warnings;
use strict;
use FindBin;

sub main_usage{
    print <<"end_of_usage";

USAGE
    $FindBin::Script <*.samtools-flagstat.out>

end_of_usage
    exit;
}

sub main{
    main_usage unless @ARGV;
    for my $file (@ARGV){
        my($supp, $mapped, $paired);

        open my $fh, $file or die $!;
        while(<$fh>){
            if(/(\d+).*supplementary/){
                $supp = $1;
            }
            elsif(/(\d+).*mapped \(/){
                $mapped = $1;
            }
            elsif(/(\d+).*paired in sequencing/){
                $paired = $1;
            }
        }
        close $fh;

        die unless $supp and $mapped and $paired;
        print join("\t", $file, $mapped, $supp, $paired, ($mapped - $supp) / $paired)."\n";
    }
}

main unless caller;
 
__END__

