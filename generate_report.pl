#!/usr/bin/perl -w

# $Id $
# SKV F814

###############################################

sub print_category
{
my $categ = shift;
my $categ_mon_ref = shift;

print "$categ;";

for( $i = 0; $i < 12; $i = $i + 1 )
{
    my $map_categ_ref=$categ_mon_ref->[$i];

    if( exists $map_categ_ref->{$categ} )
    {
        print $map_categ_ref->{$categ} . ";";
    }
    else
    {
        print "0;";
    }

}

print "\n";
}

###############################################

sub print_categories
{
my $list_uniq_categ_ref = shift;
my $categ_mon_ref = shift;

foreach $categ ( @{$list_uniq_categ_ref} )
{
    print_category( $categ, $categ_mon_ref );
}

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


my $lines       = 0;
my $price_rec   = 0;

#open OUTP, ">$outp";

print "Reading $inp...\r";
open RN, "<", $inp;

while( <RN> )
{
    chomp;
    $lines++;

# sample tick:
# N;Date;Sum;Category;Sub-Category;Owner;Descr;Quantity;Extra source;Comment
# 2;2015.01.02;4.86;food;office;S;jogurt;;;

    if( ! m#([0-9]+);([0-9]+\.)([0-9]+)(\.[0-9]+);([0-9\.]*);([a-zA-Z0-9 \.,]+);([a-zA-Z0-9 \.,]*);([A-Z]*);.*;([0-9]*);.*;# )
    {
        next;
    }
    $price_rec++;

    my $rec=$1;
    my $month=$3;
    my $val=$5;
    my $categ=$6;
    my $subcateg=$7;
    my $owner=$8;

#    print "DBG: month = $month $categ $subcateg $val\n";

    if( $val eq "" )
    {
        print STDERR "WARNING: record $rec has empty price\n";
        next;
    }

    if( $month eq "" )
    {
        print STDERR "WARNING: record $rec has empty month\n";
        next;
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

print "SUMMARY: " . $#list_uniq_categ . " unique categories, $lines lines read, $price_rec lines processed\n";

print "\n";

print_categories( \@list_uniq_categ, \@categ_mon );

print "\n";

##########################
