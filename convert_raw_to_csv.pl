#!/usr/bin/perl -w

#
# Convert Raw to CSV.
#
# Copyright (C) 2022 Dr. Sergey Kolevatov
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program. If not, see <http://www.gnu.org/licenses/>.
#

# 1.0 - 22425 - initial commit

###############################################

use strict;
use warnings;
use 5.010;

###############################################

sub validate_integer($$$)
{
    my ( $val, $min, $max ) = @_;

    return 0 if( $val < $min );
    return 0 if( $val > $max );

    return 1;
}

###############################################

sub validate_day($)
{
    my ( $val ) = @_;

    return validate_integer( $val, 1, 31 );
}

###############################################

sub validate_month($)
{
    my ( $val ) = @_;

    return validate_integer( $val, 1, 12 );
}

###############################################

sub validate_year($)
{
    my ( $val ) = @_;

    return validate_integer( $val, 2015, 2030 );
}

###############################################

sub is_integer($)
{
    my ( $val ) = @_;

    return $val =~ /^[+-]?\d+$/;
}

###############################################

sub is_float($)
{
    my ( $val ) = @_;

    return $val =~ /^[+-]?\d+(\.\d+)?$/;
}

###############################################

sub is_id_connector($)
{
    my ( $val ) = @_;

    $val = lc $val;

    return $val =~ /^verbind[[:alpha:]]*$/;
}

###############################################

sub is_id_empty($)
{
    my ( $val ) = @_;

    $val = lc $val;

    return $val =~ /^nix$/ or $val =~ /^leer$/;
}

###############################################

sub does_start_with_number($)
{
    my ( $val ) = @_;

    return $val =~ /^[+-]?\d+[a-zA-Z\.]*$/;
}

###############################################

sub get_integer($$$)
{
    my ( $tokens_ref, $offset, $size ) = @_;

    my @tokens = @{ $tokens_ref };

    if( $offset >= $size )
    {
        return ( 0, $offset, 0 );
    }

    my $val_raw = $tokens[ $offset ];

    if( is_integer( $val_raw ) )
    {
        my $val = $val_raw + 0;

        return ( 1, $offset + 1, $val );
    }

    return ( 0, 0, 0 );
}

###############################################

sub get_string($$$)
{
    my ( $tokens_ref, $offset, $size ) = @_;

    my @tokens = @{ $tokens_ref };

    if( $offset >= $size )
    {
        return ( 0, $offset, 0 );
    }

    my $val = $tokens[ $offset ];

    return ( 1, $offset + 1, $val );
}

###############################################

sub extract_day($$$)
{
    my ( $tokens_ref, $offset, $size ) = @_;

    my ( $is_ok, $new_offset, $val ) = get_integer( $tokens_ref, $offset, $size );

    if( $is_ok == 1 )
    {
        print "DEBUG: extracted day $val\n";

        return ( 1, $new_offset, $val );
    }

    return ( 0, $offset, 0 );
}

###############################################

sub extract_month($$$)
{
    my ( $tokens_ref, $offset, $size ) = @_;

    my ( $is_ok, $new_offset, $val ) = get_integer( $tokens_ref, $offset, $size );

    if( $is_ok == 1 )
    {
        print "DEBUG: extracted month $val\n";

        return ( 1, $new_offset, $val );
    }

    return ( 0, $offset, 0 );
}

###############################################

sub extract_year($$$)
{
    my ( $tokens_ref, $offset, $size ) = @_;

    my ( $is_ok, $new_offset, $val ) = get_integer( $tokens_ref, $offset, $size );

    if( $is_ok == 1 )
    {
        print "DEBUG: extracted year $val\n";

        if( $val < 100 )
        {
            $val += 2000;

            print "DEBUG: corrected year $val\n";
        }

        return ( 1, $new_offset, $val );
    }

    return ( 0, $offset, 0 );
}

###############################################

sub extract_price_part($$$)
{
    my ( $tokens_ref, $offset, $size ) = @_;

    my ( $is_ok, $new_offset, $val ) = get_integer( $tokens_ref, $offset, $size );

    if( $is_ok == 1 )
    {
        print "DEBUG: extracted price part $val\n";

        return ( 1, $new_offset, $val );
    }

    return ( 0, $offset, 0 );
}

###############################################

sub extract_identifier($$$)
{
    my ( $tokens_ref, $offset, $size ) = @_;

    my $is_ok = 0;
    my $new_offset = 0;
    my $val;

    ( $is_ok, $new_offset, $val ) = get_string( $tokens_ref, $offset, $size );

    if( $is_ok == 0 )
    {
        return ( 0, $offset, 0 );
    }

    return ( 1, $new_offset, "" ) if( is_id_empty( $val ) );

    my $res = $val;

    while( 1 )
    {
        $offset = $new_offset;

        ( $is_ok, $new_offset, $val ) = get_string( $tokens_ref, $offset, $size );

        last if( $is_ok == 0 );

        last if( is_id_connector( $val ) == 0 );

        ( $is_ok, $new_offset, $val ) = get_string( $tokens_ref, $new_offset, $size );

        return ( 0, $offset, "" ) if( $is_ok == 0 );

        $res .= "_${val}";
    }

    $res = lc $res;

    print "DEBUG: extracted identifier $res\n";

    return ( 1, $offset, $res );
}

###############################################

sub validate($$$$$$$)
{
    my ( $day, $month, $year, $price_int, $price_frac, $categ, $subcateg ) = @_;

    return ( 0, "invalid day" )   if validate_day( $day ) == 0;
    return ( 0, "invalid month" ) if validate_month( $month ) == 0;
    return ( 0, "invalid year" )  if validate_year( $year ) == 0;
    return ( 0, "invalid price_int" )  if validate_integer( $price_int, -2000, 2000 ) == 0;
    return ( 0, "invalid price_frac" ) if validate_integer( $price_frac, 0, 99 ) == 0;

    return ( 1, "" );
}

###############################################

sub process_line($$$)
{
    my ( $line, $line_num, $file_out ) = @_;

    print "DEBUG: processing line $line_num: $line\n";

    my @tokens = split( /[\s\.]+/, $line);

    my $size = scalar @tokens;

    if( $size == 0 )
    {
        print "ERROR: empty line $line_num\n";

        return;
    }

    if( is_integer( $tokens[0] ) == 0 )
    {
        print "WARNING: ignoring line $line_num: $line\n";

        return;
    }

    my $is_ok = 0;
    my $offset = 0;
    my $day = 0;
    my $month = 0;
    my $year = 0;
    my $price_int = 0;
    my $price_frac = 0;
    my $category = "";

    ( $is_ok, $offset, $day ) = extract_day( \@tokens, 0, $size );

    if( $is_ok == 0 )
    {
        print "INFO: cannot extract date from line $line_num: $line\n";

        return;
    }

    ( $is_ok, $offset, $month ) = extract_month( \@tokens, $offset, $size );

    if( $is_ok == 0 )
    {
        print "INFO: cannot extract month from line $line_num: $line\n";

        return;
    }

    ( $is_ok, $offset, $year ) = extract_year( \@tokens, $offset, $size );

    if( $is_ok == 0 )
    {
        print "INFO: cannot extract year from line $line_num: $line\n";

        return;
    }

    ( $is_ok, $offset, $price_int ) = extract_price_part( \@tokens, $offset, $size );

    if( $is_ok == 0 )
    {
        print "INFO: cannot extract price int from line $line_num: $line\n";

        return;
    }

    ( $is_ok, $offset, $price_frac ) = extract_price_part( \@tokens, $offset, $size );

    if( $is_ok == 0 )
    {
        print "INFO: cannot extract price int from line $line_num: $line\n";

        return;
    }

    ( $is_ok, $offset, $category ) = extract_identifier( \@tokens, $offset, $size );

    if( $is_ok == 0 )
    {
        print "INFO: cannot extract category from line $line_num: $line\n";

        return;
    }

    my ( $is_valid, $error_msg ) = validate( $day, $month, $year, $price_int, $price_frac, $category, "" );

    if( $is_valid == 0 )
    {
        print "ERROR: line not valid $line_num: $error_msg: $line\n";

        return;
    }
}

###############################################

sub process($$)
{
    my ( $filename_in, $filename_out ) = @_;

    my $num_lines = 0;
    my $except_lines=0;
    my $resrc_lines=0;

    print "INFO: reading file $filename_in ...\n";

    open( my $file_in, '<:encoding(utf8)', $filename_in ) or die "Could not open '$filename_in' $!\n";

    open( my $file_out, "> $filename_out" ) or die "Couldn't open file for writing: $!\n";

    binmode( $file_out, "encoding(UTF-8)" );

    while( my $line = <$file_in> )
    {
        chomp $line;
        $num_lines++;

        # skip empty lines
        $line =~ s/^\s+//g; # no leading white spaces
        next unless length( $line );

        # skip comments
        next if $line =~ /^#/;

        process_line( $line, $num_lines, $file_out );
    }

    print "INFO: read $num_lines line(s) from file $filename_in\n";

    close $file_in;
    close $file_out;

}
###############################################

my $ARGC = $#ARGV + 1;
if( $ARGC < 2 || $ARGC > 2 )
{
    print STDERR "\nUsage: convert_raw_to_csv.pl <input.dat> <output.csv>\n";
    exit;
}

my $filename_in = $ARGV[0] or die "Need to get CSV file on the command line\n";
my $filename_out = $ARGV[1] or die "Need to get CSV file on the command line\n";

process( $filename_in, $filename_out );
