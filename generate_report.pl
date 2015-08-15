#!/usr/bin/perl -w

# $Id $
# SKV F814

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

my @categ_mon;
my @categ_subcateg_mon=();
my @categ_owner_mon=();
#$#categ_mon=12;         # 12 months
#my @categ_mon=( 0 )x12;


my %uniq_categ;
#my %map_categ_subcateg;
#my %map_categ_owner;

for( $i = 0; $i < 12; $i = $i + 1 )
{
    my %map_categ;

    push( @categ_mon, \%map_categ );
#    push( @categ_subcateg_mon, %map_categ_subcateg );
#    push( @categ_subcateg_mon, %map_categ_subcateg );
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
        $warning++;
        print STDERR "WARNING: record $rec has empty price\n";
        next;
    }

    if( $month eq "" )
    {
        $warning++;
        print STDERR "WARNING: record $rec has empty month\n";
        next;
    }

    if( $day eq "" )
    {
        $warning++;
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

    $uniq_categ{$categ} += 1;

    my $map_categ_ref=$categ_mon[$month - 1];

    if( exists $map_categ_ref->{$categ} )
    {
#        print "DBG: $month: existing $categ\n";
        $map_categ_ref->{$categ} += $val;
    }
    else
    {
#        print "DBG: $month: new $categ\n";
        $map_categ_ref->{$categ} = $val;
    }
}

close RN;

#close OUTP;

##########################

my @list_uniq_categ = sort keys %uniq_categ;

my $compl_months = ( $max_month - 1 ) + ( $max_day / 30 );      # number of completed months

print "SUMMARY:\n";
print "unique categories : " . $#list_uniq_categ ."\n";
print "months, days      : " . ( 0 + $max_month ). ", $max_day, completed months $compl_months\n";
print "lines read        : $lines, $price_rec lines processed\n";
print "warnings          : $warnings\n";

print "\n";
print "monthly\n";
print "\n";

print_categories( \@list_uniq_categ, \@categ_mon );

print "\n";
printf "averages - %.1f months\n", $compl_months;
print "\n";

print_categories_avg( \@list_uniq_categ, \@categ_mon, $compl_months );

print "\n";

##########################
