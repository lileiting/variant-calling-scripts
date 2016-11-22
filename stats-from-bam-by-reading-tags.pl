#!/usr/bin/env perl

use warnings;
use strict;
use FindBin;
our %flag_info;

sub main_usage {
    print <<"end_of_usage";

USAGE
    perl $FindBin::Script <in.bam|in.sam> [<in.bam|in.sam> ...]
    samtools view <in.bam|in.sam> | perl $FindBin::Script

end_of_usage
    exit
}

sub main{
    main_usage if scalar(@ARGV) == 0 and -t STDIN;
    _check_samtools();
    if(@ARGV){
        for my $file (@ARGV){
            open my $fh, "samtools view $file |" or die $!;
            process_sam_data($file, $fh);
            close $fh;
        }
    }
    else{
        my $fh = \*STDIN;
        process_sam_data('STDIN', $fh);
    }
}

main unless caller;

############################################################
# Subroutines
############################################################

sub _check_samtools{
    die "Could not locate samtools! Please install SAMtools first\n".
        "    URL: http://www.htslib.org/download/\n"
        unless `which samtools`;
}

sub _samtools_flags {
    my $flag = shift;
    unless (exists $flag_info{$flag}){
        my $out = `samtools flags $flag`;
        chomp $out;
        my @F = split /\t/, $out;
        my %tag = map{$_,1} (split /,/, $F[2]);
        my $read_num;
        if(exists $tag{READ1}){
            $read_num = 'READ1';
        }
        elsif(exists $tag{READ2}){
            $read_num = 'READ2';
        }
        else{
            die "CAUTION: Please check flag $flag ($out) for read number\n";
        }

        $flag_info{$flag}->{READ}  = $read_num;
        $flag_info{$flag}->{UNMAP} = exists $tag{UNMAP} ? 1 : 0;
    }
}

sub process_sam_data{
    my ($file, $fh) = @_;
    my %data;
    while(<$fh>){
        next if /^@/;
        my @F = split /\t/;
        my $read_name = $F[0];
        my $flag = $F[1];
        _samtools_flags($flag);
        my $read_num = $flag_info{$flag}->{READ};
        my $mapped = $flag_info{$flag}->{UNMAP} ? 'UNMAP' : 'mapped';
        $data{$read_name}->{$read_num}->{$mapped}++;
        die "CAUTION: $read_name both mapped and UNMAP???"
            if $data{$read_name}->{$read_num}->{UNMAP} and 
               $data{$read_name}->{$read_num}->{mapped};
    }
    #_print_data(%data);
    my $number_of_total_reads = keys %data;

    my @read1_mapped = grep {exists $data{$_}->{READ1}->{mapped}} keys %data;
    my $read1_mapped = @read1_mapped;
    my $read1_multi  = grep { $data{$_}->{READ1}->{mapped} > 1 } @read1_mapped;

    my @read2_mapped = grep {exists $data{$_}->{READ2}->{mapped}} keys %data;
    my $read2_mapped = @read2_mapped;
    my $read2_multi  = grep { $data{$_}->{READ2}->{mapped} > 1 } @read2_mapped;

    my @paired_mapped= grep { exists $data{$_}->{READ2}->{mapped} }  @read1_mapped;
    my $paired_mapped= @paired_mapped;
    my $paired_multi = grep { $data{$_}->{READ1}->{mapped} > 1 and
                              $data{$_}->{READ2}->{mapped} > 1 } @paired_mapped;

    print join("\t", $file, 
                     $number_of_total_reads, 
                     $read1_mapped, 
                     $read1_multi, 
                     $read2_mapped,
                     $read2_multi, 
                     $paired_mapped,
                     $paired_multi
              )."\n";
}

sub _print_data {
    my %data = @_;
    for my $read_name (keys %data){
        printf "%s\tREAD1\tUNMAP\t%d\tmapped\t%d\tREAD2\tUNMAP\t%d\tmapped\t%d\n",
            $read_name, 
            $data{$read_name}->{READ1}->{UNMAP}  // 0,
            $data{$read_name}->{READ1}->{mapped} // 0,
            $data{$read_name}->{READ2}->{UNMAP}  // 0,
            $data{$read_name}->{READ2}->{mapped} // 0
    }
}

__END__

