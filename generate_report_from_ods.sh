#!/bin/bash

<<'COMMENT'

Wrapper for generate_report.pl

Copyright (C) 2018 Sergey Kolevatov

This program is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program. If not, see <http://www.gnu.org/licenses/>.

COMMENT

# SKV
# 18426 - 1.0 - initial version

#<hb>***************************************************************************
#
# generate_report_from_ods.sh <ods_file> <output.csv>
#
# wrapper for generate_report.pl
#
# Example: generate_report_from_ods.sh example.ods output.csv
#
#<he>***************************************************************************

show_help()
{
    sed -e '1,/^#<hb>/d' -e '/^#<he>/,$d' $0 | cut -c 3-
}

INPUT_FILE=$1
OUTPUT_FILE=$2

[ -z "$INPUT_FILE" ]    && echo "ERROR: INPUT_FILE is not defined" && show_help && exit
[ ! -f "$INPUT_FILE" ]  && echo "ERROR: INPUT_FILE doesn't exist" && show_help && exit

INPUT_CSV=$( echo "$INPUT_FILE" | sed "s/\.ods$/\.csv/" )

echo "DEBUG: INPUT_FILE     = $INPUT_FILE"
echo "DEBUG: INPUT_CSV      = $INPUT_CSV"
echo "DEBUG: OUTPUT_FILE    = $OUTPUT_FILE"

export PATH=$PATH:.

ods_to_csv.sh $INPUT_FILE

generate_report.pl $INPUT_CSV $OUTPUT_FILE
