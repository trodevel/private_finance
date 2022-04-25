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

sub get_integer($$$)
{
    my ( $tokens_ref, $offset, $size ) = @_;

    my @tokens = @{ $tokens_ref };

    if( $offset >= $size )
    {
        return ( 0, $offset, 0 );
    }

    my $val_raw = $tokens[ $offset ];

    if( $val_raw =~ /^[+-]?\d+$/ )
    {
        my $val = $val_raw + 0;

        return ( 1, $offset + 1, $val );
    }

    return ( 0, 0, 0 );
}

###############################################

sub extract_day($$$)
{
    my ( $tokens_ref, $offset, $size ) = @_;

    my ( $is_ok, $new_offset, $day ) = get_integer( $tokens_ref, $offset, $size );

    if( $is_ok eq 1 )
    {
        print "DEBUG: extracted day $day\n";

        return ( 1, $new_offset, $day );
    }

    return ( 0, $offset, 0 );
}

###############################################

sub process_line($$$)
{
    my ( $line, $line_num, $file_out ) = @_;

    print "DEBUG: processing line $line_num: $line\n";

    my @tokens = split( /\s+/, $line);

    my $size = scalar @tokens;

    my ( $is_ok, $new_offset, $day ) = extract_day( \@tokens, 0, $size );

    if( $is_ok eq 0 )
    {
        print "INFO: cannot extract date from line $line_num: $line\n";
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
