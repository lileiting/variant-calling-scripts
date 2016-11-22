#!/usr/bin/env perl

use warnings;
use strict;
use FindBin;

sub main_usage{
    print <<"end_of_usage";

Usage
    $FindBin::Script <in.bam> out.alninfo

Description
    Coverage statistics of BAM file and also
    print SAM format data to STDOUT

end_of_usage
    exit;
}

sub main{
    main_usage unless @ARGV == 2;
    my ($bam_file, $out_file) = @ARGV;
    if($out_file eq $bam_file){
        $out_file = "$out_file.alninfo";
    }
    system("samtools stats $bam_file > $out_file");
    system("samtools view -h $bam_file");
}

main unless caller;

__END__
