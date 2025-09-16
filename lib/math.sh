#!/usr/bin/env bash
# Author : Amr Alasmer
# Project Name : Amr Bash Library
# License: LGPLv3 or later

# Copyright (C) 2025 Amr Alasmer

add(){
    echo $(($1+$2))
}

sub(){
    echo $(($1-$2))
}

mul(){
    echo $(($1*$2))
}

div(){
    echo $(($1/$2))
}

pow(){
    echo $(($1**$2))
}

#
#   OTHER
#   MATHMATIC
#   FUNCTIONS
#
#



# log (base) (number)
log(){
    local base=$1
    local num=$2
    if [ -n "$base" ] && [ -n "$num" ]; then
        awk -v b=$base -v n=$num 'BEGIN{printf "%11.9f",(log(n)/log(b))}'
    fi
}



