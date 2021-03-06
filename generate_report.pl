#!/usr/bin/perl -w

use strict;
use warnings;

# $Id $
# SKV F814

# 1.3 - F816 - added calculation of statistics for sub-categories
# 1.4 - F816 - added calculation of statistics for owners
# 1.5 - F816 - minor: added create_key()
# 1.6 - F816 - minor: added print_report_all_months(), print_report_avg()
# 1.7 - F826 - used "?" for undefined subcategory, minor refinements in output
# 1.8 - FB08 - bugfix: category name may contain underscore, colon
# 1.9 - 18409 - fixed perl warnings
# 1.10 - 18409 - 1. added calculation of totals 2. added output of table headers
# 1.11 - 18426 - added output into file

my $VER="1.11";

###############################################

sub print_category
{
    my $OUTP            = shift;
my $categ = shift;
my $categ_mon_ref = shift;
my $must_calc_avg = shift;
my $max_month = shift;
my $must_calc_total = shift;

my $sum = 0;

print $OUTP "$categ;";

for( my $i = 0; $i < 12; $i = $i + 1 )
{
    my $map_categ_ref=$categ_mon_ref->[$i];

    my $val = 0;

    if( exists $map_categ_ref->{$categ} )
    {
        $val = $map_categ_ref->{$categ};
    }

    if( $must_calc_avg || $must_calc_total )
    {
        $sum += $val;
    }

    if( ! $must_calc_avg )
    {
        print $OUTP "$val;";
    }
}

if( $must_calc_avg )
{
    printf $OUTP "%.1f;", ( $sum / $max_month );
}

if( $must_calc_total )
{
    printf $OUTP "$sum;";
}

print $OUTP "\n";
}

###############################################

sub print_categories_kern
{
    my $OUTP            = shift;
my $list_uniq_categ_ref = shift;
my $categ_mon_ref = shift;
my $must_calc_avg = shift;
my $max_month = shift;
my $must_calc_total = shift;

foreach my $categ ( @{$list_uniq_categ_ref} )
{
    print_category( $OUTP, $categ, $categ_mon_ref, $must_calc_avg, $max_month, $must_calc_total );
}

}
###############################################

sub print_categories
{
    my $OUTP            = shift;
    my $list_uniq_categ_ref = shift;
    my $categ_mon_ref = shift;

    print_categories_kern( $OUTP, $list_uniq_categ_ref, $categ_mon_ref, 0, 0, 1 );
}

sub print_categories_avg
{
    my $OUTP            = shift;
    my $list_uniq_categ_ref = shift;
    my $categ_mon_ref = shift;
    my $max_month = shift;

    print_categories_kern( $OUTP, $list_uniq_categ_ref, $categ_mon_ref, 1, $max_month, 0 );
}

###############################################

sub update_categ
{
    my $categ_mon_ref   = shift;
    my $month           = shift;
    my $categ           = shift;
    my $val             = shift;

    my $map_categ_ref=$categ_mon_ref->[$month - 1];



    if( exists $map_categ_ref->{$categ} )
    {
#        print "DBG: $month, $categ, map before: " . $map_categ_ref->{$categ} . "\n";       # DBG
        $map_categ_ref->{$categ} += $val;
    }
    else
    {
#        print "DBG: not exist - $month, $categ\n";    # DBG
        $map_categ_ref->{$categ} = $val;
    }

#    print "DBG: $month, $categ, $val\n";       # DBG
#    print "DBG: $month, $categ, map: " . $map_categ_ref->{$categ} . "\n";       # DBG
}

###############################################

sub print_header_all_months
{
    my $OUTP            = shift;
    print $OUTP "category;1;2;3;4;5;6;7;8;9;10;11;12;total;\n";
}

###############################################

sub print_header_averages
{
    my $OUTP            = shift;
    print $OUTP "category;average;\n";
}

###############################################
sub print_report_all_months
{
    my $OUTP            = shift;
    my $title           = shift;
    my $list_categ_ref  = shift;
    my $monthly_exp_ref = shift;
    print $OUTP "\n";
    print $OUTP "$title\n";
    print $OUTP "\n";

    print_header_all_months( $OUTP );

    print_categories( $OUTP, $list_categ_ref, $monthly_exp_ref );
}

###############################################

sub print_report_avg
{
    my $OUTP            = shift;
    my $title           = shift;
    my $list_categ_ref  = shift;
    my $monthly_exp_ref = shift;
    my $num_months      = shift;

    print $OUTP "\n";
    printf $OUTP "%s - %.1f months\n", $title, $num_months;
    print $OUTP "\n";

    print_header_averages( $OUTP );

    print_categories_avg( $OUTP, $list_categ_ref, $monthly_exp_ref, $num_months );
}

###############################################


sub create_key
{
    my $first   = shift;
    my $second  = shift;
    my $res     = ( $second eq "" ) ? $first . "-?" : $first . "-" . $second;

    return $res;
}

###############################################

print "generate_report ver. $VER\n";

my $num_args = $#ARGV + 1;
if( $num_args != 2 )
{
    print STDERR "\nUsage: generate_report.sh <source_file.csv> <output.csv>\n";
    exit;
}

my $inp = $ARGV[0];
my $outp = $ARGV[1];
shift( @ARGV );

print STDERR "DEBUG: inp = $inp outp=$outp\n";

unless( -e $inp )
{
    print STDERR "ERROR: input file $inp doesn't exist\n";
    exit;
}


print "processing $inp ...\n";

my @mon_categ;
my @mon_categ_subcateg=();
my @mon_categ_owner=();


my %uniq_categ;
my %uniq_categ_subcateg;
my %uniq_categ_owner;

for( my $i = 0; $i < 12; $i = $i + 1 )
{
    my %map_categ;
    my %map_categ_subcateg;
    my %map_categ_owner;

    push( @mon_categ, \%map_categ );
    push( @mon_categ_subcateg, \%map_categ_subcateg );
    push( @mon_categ_owner, \%map_categ_owner );
}


my $warnings    = 0;
my $lines       = 0;
my $price_rec   = 0;
my $max_month   = 0;
my $max_day     = 0;

print "Reading $inp...\n";
open RN, "<", $inp;

while( <RN> )
{
    chomp;
    $lines++;

# sample tick:
# N;Date;Sum;Category;Sub-Category;Owner;Descr;Quantity;Extra source;Comment
# 2;2015.01.02;4.86;food;office;S;jogurt;;;

    if( ! m#([0-9]+);([0-9]+\.)([0-9]+)\.([0-9]+);([0-9\.]*);([a-zA-Z0-9 \.,_:]+);([a-zA-Z0-9 _\.,]*);([A-Z]*);.*;([0-9]*);.*;# )
    {
        next;
    }
    $price_rec++;

    my $rec=$1;
    my $month=$3;
    my $day=$4;
    my $val=$5;
    my $categ=$6;
    my $subcateg=$7;
    my $owner=$8;

#    print "DBG: month = $month $categ $subcateg $val\n";

    if( $val eq "" )
    {
        $warnings++;
        print STDERR "WARNING: record $rec has empty price\n";
        next;
    }

    if( $month eq "" )
    {
        $warnings++;
        print STDERR "WARNING: record $rec has empty month\n";
        next;
    }

    if( $day eq "" )
    {
        $warnings++;
        print STDERR "WARNING: record $rec has empty day\n";
        next;
    }

    if( $month > $max_month )
    {
        $max_month = $month;
        $max_day   = $day;
    }
    elsif( $month == $max_month )
    {
        if( $day > $max_day )
        {
            $max_day = $day;
        }
    }

    my $categ_subcateg = create_key( $categ, $subcateg );
    my $categ_owner    = create_key( $categ, $owner );

    $uniq_categ{$categ} += 1;
    $uniq_categ_subcateg{$categ_subcateg} += 1;
    $uniq_categ_owner{$categ_owner} += 1;

    update_categ( \@mon_categ, $month, $categ, $val );
    update_categ( \@mon_categ_subcateg, $month, $categ_subcateg, $val );
    update_categ( \@mon_categ_owner, $month, $categ_owner, $val );
}

close RN;

##########################

my @list_uniq_categ = sort keys %uniq_categ;
my @list_uniq_categ_subcateg = sort keys %uniq_categ_subcateg;
my @list_uniq_categ_owner = sort keys %uniq_categ_owner;

my $compl_months = ( $max_month - 1 ) + ( $max_day / 30 );      # number of completed months

my $OUTP;

open( $OUTP, ">$outp" ) or die "Couldn't open file for writing: $!\n";

print $OUTP "\n";
print $OUTP "SUMMARY:\n";
print $OUTP "unique categories     : " . $#list_uniq_categ ."\n";
print $OUTP "unique categ/subcateg : " . $#list_uniq_categ .", ". $#list_uniq_categ_subcateg ."\n";
print $OUTP "unique categ/owner    : " . $#list_uniq_categ .", ". $#list_uniq_categ_owner ."\n";
printf $OUTP "months, days          : %d, %d, completed months %.1f\n", $max_month, $max_day, $compl_months;

print $OUTP "lines read/processed  : $lines, $price_rec\n";
print $OUTP "warnings              : $warnings\n";

print_report_all_months( $OUTP, "monthly",            \@list_uniq_categ,          \@mon_categ );
print_report_all_months( $OUTP, "monthly (subcateg)", \@list_uniq_categ_subcateg, \@mon_categ_subcateg );

print_report_avg( $OUTP, "averages",            \@list_uniq_categ,          \@mon_categ,          $compl_months );
print_report_avg( $OUTP, "averages (subcateg)", \@list_uniq_categ_subcateg, \@mon_categ_subcateg, $compl_months );
print_report_avg( $OUTP, "averages (owner)",    \@list_uniq_categ_owner,    \@mon_categ_owner,    $compl_months );

print $OUTP "\n";

close $OUTP;

##########################
