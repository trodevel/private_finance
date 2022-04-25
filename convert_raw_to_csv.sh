#!/bin/bash

INP=$1
OUTP=$2

[[ -z $INP ]]   && echo "ERROR: INP is not given" && exit 1
[[ -z $OUTP ]]  && echo "ERROR: OUTP is not given" && exit 1

[[ ! -f $INP ]] && echo "ERROR: file $INP not found" && exit 1

# Sample:
# 30 03 20-22 02. 71 essen nix familie hit
# 19 02 2022 139. 99 kleidung nix vater sportschuhe wichtig
# 16.04 2022 7. 20 urlaub verbinder Paris trennung Eis kinder

process()
{
    local INP=$1
    local OUTP=$2

    grep "^[0-9]\{2\}[ \.]" $INP > $OUTP
}

process $INP $OUTP
