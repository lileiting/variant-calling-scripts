#!/usr/bin/env perl

use warnings;
use strict;
use FindBin;
use Getopt::Long;

sub main_usage {
    print <<"end_of_usage";

Usage
    $FindBin::Script [OPTIONS]

Description
    Extract the genotype tag from VCF file

OPTIONS
    -in  <in.vcf.gz>  input VCF file (support gzipped file)
    -out out_prefix   output prefix
    -tq  NUM          threshold of quality    [default: 0]

end_of_usage

#    -pmd NUM          parent minimum depth    [default: 0]
#    -omd NUM          offspring minimum depth [default: 0]
#    -mxd NUM          maximum depth           [default: disable]


    exit;
}

sub main {
    main_usage unless @ARGV;
    my ($in, $out, $pmd, $omd, $tq, $mxd);
    GetOptions(
        "in=s"  => \$in,
        "out=s" => \$out,
#        "pmd=i" => \$pmd,
#        "omd=i" => \$omd,
        "tq=i"  => \$tq,
#        "mxd=i" => \$mxd
    );

    main_usage unless $in;
#    $pmd //= 0;
#    $omd //= 0;
    $tq  //= 0;
#    $mxd //= 0;

    my ($in_fh, $out_fh) = make_filehandle($in, $out);

    LOCUS: while(<$in_fh>){
        next if /^\s*#/ or /^\s*$/;
        chomp;
        my @f = split /\t/;
        die "The script assume there were at least 11 columns",
            " (two parents, >= 0 offspring)"
            if @f < 11;
        my $quality = $f[5];
        next unless $quality >= $tq;

        my @marker;
        push @marker, join("-", @f[0,1,3,4]);

        my @format = split /:/, $f[8];
        my @parents = @f[9,10];
        my @offsprings = @f[11..$#f];

        for my $data (@parents, @offsprings){
            my %hash = data2hash(\@format, $data);
            push @marker, $hash{GT};
#            #die "Could not find DP tag in parents" unless exists $hash{DP};
#            if($hash{DP} < 2) {
#                push @marker, "./.";
#            }
#            elsif($mxd > 0 and $hash{DP} <= $mxd or $mxd == 0) {
#                if($hash{PL}){
#                    #my $genotype = determine_genotype_from_PL($hash{PL});
#                    my $genotype = $hash{GT};
#                    push @marker, $genotype;
#                }
#                else{
#                    die "PL tag is missing: $_";
#                }
#            }
#            else{
#                next LOCUS;
#            }
        }

        print join("\t", @marker)."\n";
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
        open my $out_fh, "| gzip -c > $out.geno.gz" or die $!;
    }
    else{
        $out_fh = \*STDOUT;
    }
    return ($in_fh, $out_fh);
}

sub data2hash {
    my $format = shift;
    my @format = @$format;
    my $data = shift;
    my %hash;
    my @data = split /:/, $data;
    for(my $i = 0; $i <= $#format; $i++){
        $hash{$format[$i]} = $data[$i];
    }
    die "Could not find GT tag: @format" unless exists $hash{GT};
    return %hash;
}


sub determine_genotype_from_PL {
    my $PL = shift;
    my @PL = split /,/, $PL;
    my @genotypes = qw(0/0 0/1 1/1
                       0/2 1/2 2/2
                       0/3 1/3 2/3 3/3
                      );
    for(my $i = 0; $i <= $#PL; $i++){
        if($PL[$i] == 0){
            return $genotypes[$i];
        }
    }
    die "WARNING: PL\t$PL\n";
}

__END__
