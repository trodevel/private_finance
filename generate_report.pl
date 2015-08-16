#!/usr/bin/perl -w

# $Id $
# SKV F814

# 1.3 - F816 - added calculation of statistics for sub-categories

my $VER="1.2";

###############################################

sub print_category
{
my $categ = shift;
my $categ_mon_ref = shift;
my $must_calc_avg = shift;
my $max_month = shift;

my $sum = 0;

print "$categ;";

for( $i = 0; $i < 12; $i = $i + 1 )
{
    my $map_categ_ref=$categ_mon_ref->[$i];

    my $val = 0;

    if( exists $map_categ_ref->{$categ} )
    {
        $val = $map_categ_ref->{$categ};
    }

    if( $must_calc_avg )
    {
        $sum += $val;
    }
    else
    {
        print "$val;";
    }
}

if( $must_calc_avg )
{
    printf "%.1f;", ( $sum / $max_month );
}

print "\n";
}

###############################################

sub print_categories_kern
{
my $list_uniq_categ_ref = shift;
my $categ_mon_ref = shift;
my $must_calc_avg = shift;
my $max_month = shift;

foreach $categ ( @{$list_uniq_categ_ref} )
{
    print_category( $categ, $categ_mon_ref, $must_calc_avg, $max_month );
}

}
###############################################

sub print_categories
{
    my $list_uniq_categ_ref = shift;
    my $categ_mon_ref = shift;

    print_categories_kern( $list_uniq_categ_ref, $categ_mon_ref, 0, 0 );
}

sub print_categories_avg
{
    my $list_uniq_categ_ref = shift;
    my $categ_mon_ref = shift;
    my $max_month = shift;

    print_categories_kern( $list_uniq_categ_ref, $categ_mon_ref, 1, $max_month );
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

$num_args = $#ARGV + 1;
if( $num_args != 1 )
{
    print STDERR "\nUsage: generate_report.sh <source_file.csv>\n";
    exit;
}

$inp = $ARGV[0];
shift( @ARGV );

#print STDERR "DEBUG: inp = $inp\n";

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
#my %map_categ_owner;

for( $i = 0; $i < 12; $i = $i + 1 )
{
    my %map_categ;
    my %map_categ_subcateg;

    push( @mon_categ, \%map_categ );
    push( @mon_categ_subcateg, \%map_categ_subcateg );
#    push( @mon_categ_subcateg, %map_categ_subcateg );
}


my $warnings    = 0;
my $lines       = 0;
my $price_rec   = 0;
my $max_month   = 0;
my $max_day     = 0;

#open OUTP, ">$outp";

print "Reading $inp...\n";
open RN, "<", $inp;

while( <RN> )
{
    chomp;
    $lines++;

# sample tick:
# N;Date;Sum;Category;Sub-Category;Owner;Descr;Quantity;Extra source;Comment
# 2;2015.01.02;4.86;food;office;S;jogurt;;;

    if( ! m#([0-9]+);([0-9]+\.)([0-9]+)\.([0-9]+);([0-9\.]*);([a-zA-Z0-9 \.,]+);([a-zA-Z0-9 \.,]*);([A-Z]*);.*;([0-9]*);.*;# )
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

    my $categ_subcateg = ( $subcateg eq "" ) ? $categ : $categ . "-" . $subcateg;

    $uniq_categ{$categ} += 1;
    $uniq_categ_subcateg{$categ_subcateg} += 1;

    update_categ( \@mon_categ, $month, $categ, $val );
    update_categ( \@mon_categ_subcateg, $month, $categ_subcateg, $val );
}

close RN;

#close OUTP;

##########################

my @list_uniq_categ = sort keys %uniq_categ;
my @list_uniq_categ_subcateg = sort keys %uniq_categ_subcateg;

my $compl_months = ( $max_month - 1 ) + ( $max_day / 30 );      # number of completed months

print "SUMMARY:\n";
print "unique categories     : " . $#list_uniq_categ ."\n";
print "unique categ/subcateg : " . $#list_uniq_categ .", ". $#list_uniq_categ_subcateg ."\n";
print "months, days          : " . ( 0 + $max_month ). ", $max_day, completed months $compl_months\n";
print "lines read            : $lines, $price_rec lines processed\n";
print "warnings              : $warnings\n";

print "\n";
print "monthly\n";
print "\n";

print_categories( \@list_uniq_categ, \@mon_categ );

print "\n";
print "monthly (subcateg)\n";
print "\n";

print_categories( \@list_uniq_categ_subcateg, \@mon_categ_subcateg );

print "\n";
printf "averages - %.1f months\n", $compl_months;
print "\n";

print_categories_avg( \@list_uniq_categ, \@mon_categ, $compl_months );

print "\n";
printf "averages (subcateg) - %.1f months\n", $compl_months;
print "\n";

print_categories_avg( \@list_uniq_categ_subcateg, \@mon_categ_subcateg, $compl_months );

print "\n";

##########################
