#!/usr/bin/env bash
# Author : Amr Alasmer
# Project Name : regex_parser_V2
# License: GPLv3 or later


# Copyright (C) 2025 Amr Alasmer

# This file is part of regex_parser_V2.

# regex_parser_V2 is free software: you can redistribute it and/or modify it under
# the terms of the GNU General Public License as published by the Free Software
# Foundation, either version 3 of the License, or (at your option) any later 
# version.

# regex_parser_V2 is distributed in the hope that it will be useful, but WITHOUT 
# ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
# FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.

# You should have received a copy of the GNU General Public License along with
# this program. If not, see <https://www.gnu.org/licenses/>.






PROJECT_PATH="$(dirname "`realpath "${BASH_SOURCE[0]}"`")"
LIB_OUT="$PROJECT_PATH/lib/out.sh"
LIB_ARRAYS="$PROJECT_PATH/lib/arrays.sh"
LIB_FILES="$PROJECT_PATH/lib/files.sh"
IS_PERL_PARSER_STOPPED=0
IS_CLEANED=0

{ [ -r "$LIB_OUT" ] && source "$LIB_OUT"; } || {>&2 echo "Error : Missing dependency: $LIB_OUT"; exit 99;}
{ [ -r "$LIB_ARRAYS" ] && source "$LIB_ARRAYS"; } || {>&2 echo "Error : Missing dependency: $LIB_ARRAYS"; exit 99;}
{ [ -r "$LIB_FILES" ] && source "$LIB_FILES"; } || {>&2 echo "Error : Missing dependency: $LIB_FILES"; exit 99;}


handle_sighup(){
    if [ -n $PERL_PARSER_PID ] && [ $IS_PERL_PARSER_STOPPED -eq 0 ] ; then
        kill -SIGSTOP $PERL_PARSER_PID || err "Cannot send SIGSTOP for the regex parser core" $__WARN $__NOTHING 
        IS_PERL_PARSER_STOPPED=1
    elif [ -n $PERL_PARSER_PID ] && [ $IS_PERL_PARSER_STOPPED -eq 1 ] ; then
        kill -SIGCONT $PERL_PARSER_PID || err "Cannot send SIGCONT for the regex parser core" $__WARN $__NOTHING 
        IS_PERL_PARSER_STOPPED=0
    fi
    wait $PERL_PARSER_PID 2>/dev/null
    extract_multiple_files || err "Cannot complete parsing" $__ERROR $__EXIT $? 

}

handle_sigint(){
    if [ -n $PERL_PARSER_PID ]; then
        kill -SIGINT $PERL_PARSER_PID || err "Cannot kill regex parser core" $__ERROR $__EXIT $? 
        exit 
    fi

}


handle_sigterm(){
    if [ -n $PERL_PARSER_PID ]; then
        kill -SIGTERM $PERL_PARSER_PID || err "Cannot kill regex parser core" $__ERROR $__EXIT $?
        exit
    fi

}

trap handle_sighup SIGHUP
trap handle_sigterm SIGTERM
trap handle_sigint SIGINT

configs=()
inputs=()
nomatchset=0
isheaderless=0
output_file=""

show_help(){
    echo "Usage: ${BASH_SOURCE[0]} [OPTIONS]"

    echo "Options:"
    echo "  -h, --help                          Show help and exit"
    echo "  -i, --input-file <file>             Input data file"
    echo "  -o, --output-file <file>            Output data file 'output format is csv'"
    echo "  -c, --config-file <file>            Config file with parsing instructions"
    echo "  --headerless                        Set the output to be headerless"

    echo ""
    echo "Examples:"
    echo "  ${BASH_SOURCE[0]} -i input1.txt -i input2.csv -o output.csv -c config1.txt -c config3.conf"
    echo "  ${BASH_SOURCE[0]} -o output.csv -c config1.txt -c config3.conf < input1.csv"

}



prepare_configs(){
    CONFIG_FILE="$(/usr/bin/env mktemp)"

    for file in "${configs[@]}"; do
        if [ -r "$file" ];then 
            /usr/bin/env cat "$file" >> "$CONFIG_FILE" 
        else
            err "Config file is not found or not readable : $file" $__WARN $__NOTHING   
        fi 
    done
    
    /usr/bin/env dos2unix "$CONFIG_FILE" &>/dev/null || { err "cannot convert $CONFIG_FILE from dos to unix 'replace file endings from \\\r\\\n into \\\n'\\ndos2unix status: $?" $__ERROR $__RETURN 92; return $?; }

    # remove comments, empty lines, and leading spaces
    /usr/bin/env sed  -i '/^[[:space:]]*$/d' "$CONFIG_FILE" 
    /usr/bin/env sed  -i 's/^[[:space:]]*//' "$CONFIG_FILE"
    /usr/bin/env sed  -i '/^[[:space:]]*#/d' "$CONFIG_FILE" 
    # /usr/bin/env sed  -i 's/\\/\\\\/g'       "$CONFIG_FILE"
}

headerless(){
    if [  $isheaderless -eq 1 ]; then
        echo -n "--headerless"
    fi
}

clean_tmp(){
    /usr/bin/env rm "$CONFIG_FILE" ||   err "cannot remove TMP files" $__WARNING $__NOTHING 
    IS_CLEANED=1
}



extract(){
    if [  "$nomatchset" -eq 0 ]; then
        nomatch="N/A"
    fi
    
    
    if [ "${#inputs[@]}" -eq 0 ];  then
        if [  -n "$output_file" ]; then
            /usr/bin/env perl "$PROJECT_PATH/parser.pl"  -c "$CONFIG_FILE"  -n "$nomatch" `headerless` >> "$output_file" <&0  &
        else
            /usr/bin/env  perl  "$PROJECT_PATH/parser.pl"  -c "$CONFIG_FILE"  -n "$nomatch"  `headerless` <&0 &
        fi
        PERL_PARSER_PID=$!
        wait $PERL_PARSER_PID
        PERL_PARSER_PID=""
    else 
        extract_multiple_files
    fi

    
}

extract_multiple_files(){

    for file in "${inputs[@]}"; do
        if [  -n "$output_file" ]; then
            /usr/bin/env perl "$PROJECT_PATH/parser.pl" -i "$file" -c "$CONFIG_FILE"  -n "$nomatch" `headerless` >> "$output_file" &
            PERL_PARSER_PID=$!
            inputs=("${inputs[@]:1}") 
            wait $PERL_PARSER_PID
            PERL_PARSER_PID=""
        else
            /usr/bin/env  perl  "$PROJECT_PATH/parser.pl" -i "$file" -c "$CONFIG_FILE"  -n "$nomatch"  `headerless` &
            PERL_PARSER_PID=$!
            inputs=("${inputs[@]:1}") 
            wait $PERL_PARSER_PID
            PERL_PARSER_PID=""
        fi
        clean_tmp
    done

}

run_app(){

    if [ $# -lt 1 ]; then
        show_help ;exit 93
    fi

    check_bin_dependencies sed  perl dos2unix  || return $?
    
    
    while [ $# -gt 0 ]; do
        case $1 in 
    
        -h|--help)
            show_help; exit 0
        ;;
        
        
        -i|--input-file)
            if [ -n "$2" ]; then        
                if [ ! -r "$2" ]; then
                    err "input file is not found or not readable : $2" $__WARN $__NOTHING   
                else 
                    inputs+=( "$(/usr/bin/env realpath -m "$2" )")
                fi
                shift 2
            else
                err "-i|--input-file option requires argument." $__ERROR $__EXIT 95
            fi
        ;;

        -o|--output-file)
            if [ -n "$2" ]; then        
                output_file="$(/usr/bin/env realpath -m "$2" )"
                shift 2
            else
                err "-o|--output-file option requires argument." $__ERROR $__EXIT  95
            fi
        ;;

        -c|--config-file)
            if [ -n "$2" ]; then        
                
                if [ ! -r "$2" ]; then
                    err "Config file is not found or not readable : $2" $__WARN $__NOTHING   
                else 
                    configs+=("$(/usr/bin/env realpath -m "$2" )")
                fi
                shift 2
            else
                err "-c|--config-file option requires argument." $__ERROR $__EXIT  95
            fi
        ;;

        -n|--no-match-string)
            if [ -n "$2" ]; then        
                nomatch="$2"
                nomatchset=1
                shift 2
            else
                err "-n|--no-match-string option requires argument." $__ERROR $__EXIT  95
            fi
        ;;        
        
        --headerless)
            isheaderless=1
            shift
        ;;

        *)
            show_help;exit 1
        ;;
        esac
    done

    prepare_configs || return $? 
    
    extract ||  return $?
    if [ $IS_CLEANED -eq 0 ];then
        clean_tmp 
    fi
}





if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    run_app "$@" || exit $?
fi 



