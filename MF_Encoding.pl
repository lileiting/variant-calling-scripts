#!/usr/bin/env perl

use warnings;
use strict;
use FindBin;
use Getopt::Long;
our $out_suffix = ".encoding.txt";


sub main_usage {
    print <<"end_of_usage";

Usage
    $FindBin::Script -i <in.genotypeChecked.pop> -o out_prefix -c [F2|CP]

Description
    Convert genotypes
    F2:
        AA, BB, AB => a, b, h
    CP:
        AB x BB => lmxll
        AA x AB => nnxnp
        AB x AB => hkxhk
        AB x CD => abxcd
        AB x AC => egxeg

end_of_usage
    exit;
}

sub main {
    main_usage unless @ARGV;
    my ($in, $out, $pop_type);
    GetOptions(
        "in|i=s" => \$in,
        "out|o=s" => \$out,
        "c=s" => \$pop_type
    );
    die "Input file name is missing! -in is required" unless $in;
    die "Population type is missing! -c is required" unless $pop_type;

    my ($in_fh, $out_fh) = make_filehandle($in, $out);

    my %F2 = qw(AA a BB b AB h);
    my %CP_nnxnp = qw(AA nn AB np);
    my %CP_lmxll = qw(AB lm AA ll);
    my %CP_hkxhk = qw(AA hh AB hk BB kk);
    my %CP_efxeg = qw(AA ee AB ef AC eg BC fg);
    my %CP_abxcd = qw(AB ab CD cd AC ac BC bc AD ad BD bd);
    while(<$in_fh>){
        next if /^\s*$/ or /^\s*#/;
        chomp;
        my @f = split /\t/;
        if($pop_type eq 'F2'){
            print join("\t", $f[0], map{$F2{$_} // '-'}@f[1..$#f])."\n";
        }
        elsif($pop_type eq 'CP'){
            my $p1 = $f[1];
            my $p2 = $f[2];
            my %hash = do {
                if(   $p1 eq 'AA' and $p2 eq 'AB'){ %CP_nnxnp }
                elsif($p1 eq 'AB' and $p2 eq 'AA'){ %CP_lmxll }
                elsif($p1 eq 'AB' and $p2 eq 'AB'){ %CP_hkxhk }
                elsif($p1 eq 'AB' and $p2 eq 'AC'){ %CP_efxeg }
                elsif($p1 eq 'AB' and $p2 eq 'CD'){ %CP_abxcd }
                else{ next; 1 }
            };
            print join("\t", $f[0], map{ $F2{$_} // '--' } @f[1..$#f] )."\n";
        }
        else{
            die "Unsupported populatin type: $pop_type!\n";
        }
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
        open my $out_fh, "$out$out_suffix" or die $!;
    }
    else{
        $out_fh = \*STDOUT;
    }
    return ($in_fh, $out_fh);
}

__END__
