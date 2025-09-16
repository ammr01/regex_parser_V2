#!/usr/bin/env bash
# Author : Amr Alasmer
# Project Name : Amr Bash Library
# License: LGPLv3 or later

# Copyright (C) 2025 Amr Alasmer


# to check if the out.sh file is sourced before, if yes,
# then return 'not to complete the sourcing', to prevent
# multiple sourcing
[ -v __out_sourced_before ] && return
__out_sourced_before=1


if [ ! -v __arrays_sourced_before ]; then 
    # source arrays.sh, to use print_list function
    __lib_path="$(dirname "`realpath "${BASH_SOURCE[0]}"`")"
    { [ -f "$__lib_path/arrays.sh" ] &&  source "$__lib_path/arrays.sh"; } || {>&2 echo "Error : Missing File: $__lib_path/arrays.sh"; exit 99;}
fi

if [ ! -v __files_sourced_before ]; then 
    # source files.sh, to use add_file function
    __lib_path="$(dirname "`realpath "${BASH_SOURCE[0]}"`")"
    { [ -f "$__lib_path/files.sh" ] &&  source "$__lib_path/files.sh"; } || {>&2 echo "Error : Missing File: $__lib_path/files.sh"; exit 99;}
fi




__debug_flag=0

# [TEST]: PASS
set_debug_on(){
    __debug_flag=1 #true
}


# [TEST]: PASS
set_debug_off(){
    __debug_flag=0 #false
}

# [TEST]: 
dbg(){
    local __text="$1"
    local __multiline=1
    if [ "$#" -gt 1 ]; then
        __multiline="${2-:1}"
    else
        if [ "`echo -e "$__text" | wc -l`" -gt 1 ];then
            __multiline=0
        else 
            __multiline=1
        fi
    fi

    if [ $__debug_flag -eq 0 ]; then 
        if [ $__multiline -eq 0 ]; then
            echo -e "[DEBUG:START]\n$__text\n[DEBUG:END]"
        else
            echo -e "[DEBUG] $__text"
        fi

    fi

}



## GENERAL ERRORS
# 100: called function is not implemented yet
# 99: file to read is not found, or unable to read
# 98: file to write is not found, or unable to write
# 97: file to execute is not found, or unable to execute
# 96: not supported option
# 95: option needs more parameters
# 94: selected options cannot be selected together, or no selected group
# 93: invalid number of parameters for function
# 92: function was not executed correctly
# 91: missing package/binary
# 90: cannot delete a file/directory
# 89: cannot create a file/directory
# 88: cannot change file/directory permissions
# 87: missing mandatory option
# 86: Input/Parameter contains special characters
# 85: file/directory is not found
# 84: Cannot change working directory

readonly __NOTE=1
readonly __WARN=2
readonly __WARNING=$__WARN
readonly __ERROR=3
readonly __EXIT=0
readonly __RETURN=1
readonly __NOTHING=2
readonly __STDOUT=1
readonly __STDERR=2
readonly __ERROR_MESSAGE_ENABLE=0
readonly __ERROR_MESSAGE_DISABLE=1
readonly __SUCESS=0
readonly default_error_code=1


error_flag=$__ERROR_MESSAGE_ENABLE

# [TEST]: PASS
err(){
    # err [message] <type> <isexit> <exit/return code>
    #
    #   I- message (mandatory): text to print
    #
    #  II- type (optional "default is (1/note)"): 
    #      1 : note (Default)
    #      2 : warning
    #      3 : error: the text is printed into stderr, and it needs two more arguments
    #
    #
    # III- isexit (optional "default is 1"):
    #      0 : exit after printing 
    #          (set exit code in the next
    #           arg, default error code
    #           is used if error code
    #           is not set).
    #      1 : return a status code after printing 
    #          (set return code in the next
    #           arg, default return code
    #           is used if return code
    #           is not set).
    #      2 : do not exit or return
    #
    #  IV- error/return code : 
    #      to set error/return code, must be numeric, 
    #      if not numeric or not set, the default 
    #      value will be used. 
    
    if [ $error_flag -ne $__ERROR_MESSAGE_ENABLE ]; then 
        return $__SUCESS
    fi

    local text="$1"
    local type="${2-1}"
    local isexit="${3-1}"
    local error_code="${4-$default_error_code}"
    local typestr=""
    local fd=1
    local line
    local function
    local file
    read -r line function file <<<"$(caller 0)"

    if ! [[ "$type" =~ ^[0-9]+$ ]]; then
        type=$__NOTE
    fi

    if ! [[ "$isexit" =~ ^[0-9]+$ ]]; then
        isexit=$__RETURN
    fi

    if ! [[ "$error_code" =~ ^[0-9]+$ ]]; then
        error_code=$default_error_code
    fi
    case $type in 
    $__NOTE)
        typestr="NOTE"
        fd=$__STDOUT
    ;;
    $__WARN)
        typestr="WARNING"
        fd=$__STDOUT
    ;; 
    $__ERROR)
        typestr="ERROR"
        fd=$__STDERR
    ;;
    *)
        typestr="NOTE"
        fd=$__STDOUT
    ;;
    esac
    
    >&$fd echo -e "[$typestr @ `basename ${file}`:${line} (${FUNCNAME[1]}())] : $text"
    if [ "$isexit" -eq $__EXIT ]; then
        exit "$error_code"
    elif [ "$isexit" -eq $__RETURN ]; then
        return "$error_code"
    fi

    
}


# [TEST]: PASS   
print_my_global_variables(){
    validate_params $# - 1 || return $?    
    check_bin_dependencies gawk || return $?
    local __output_file="$(/usr/bin/env realpath -m "$1" 2>/dev/null)"
    if [ -z "$__output_file" ]; then
        declare -p | gawk 'BEGIN{f=0} $0 ~ /^declare -- _=/{f=1; next} f==1{print $0}'
    else
        # to check file existance with at least write permission, if no create it, and any needed directories "even nested"
        add_file "$__output_file" || return $?  
        
        if [ -w "$__output_file" ]; then
            declare -p | gawk 'BEGIN{f=0} $0 ~ /^declare -- _=/{f=1; next} f==1{print $0} ' > "$__output_file" 
        else
            err "Cannot write to file: $__output_file" $__ERROR $__RETURN 98 ; return $?
        fi

    # elif  [ -w "$(dirname "$__output_file")" ] && [ ! -f "$__output_file" ] ; then
    #     declare -p | gawk 'BEGIN{f=0} $0 ~ /^declare -- _=/{f=1; next} f==1{print $0} ' > "$__output_file" 
    # elif  [ -f "$__output_file" ] && [ -w "$__output_file" ] ; then
    #     declare -p | gawk 'BEGIN{f=0} $0 ~ /^declare -- _=/{f=1; next} f==1{print $0} ' > "$__output_file" 
    # else
    fi
    return 0
}

# [TEST]: PASS   
print_all_global_variables(){
    validate_params $# - 1 || return $?    
    local __output_file="$(/usr/bin/env realpath -m "$1" 2>/dev/null)"
    if [ -z "$__output_file" ]; then
        declare -p 
    else
        # to check file existance with at least write permission, if no create it, and any needed directories "even nested"
        add_file "$__output_file" || return $?  
        
        if [ -w "$__output_file" ]; then
            declare -p > "$__output_file" 
        else
            err "Cannot write to file: $__output_file" $__ERROR $__RETURN 98 ; return $?
        fi

    # elif  [ -w "$(dirname "$__output_file")" ] && [ ! -f "$__output_file" ] ; then
    #     declare -p | gawk 'BEGIN{f=0} $0 ~ /^declare -- _=/{f=1; next} f==1{print $0} ' > "$__output_file" 
    # elif  [ -f "$__output_file" ] && [ -w "$__output_file" ] ; then
    #     declare -p | gawk 'BEGIN{f=0} $0 ~ /^declare -- _=/{f=1; next} f==1{print $0} ' > "$__output_file" 
    # else
    fi
    return 0
}



# [TEST]: PASS 
# wrapper for print_my_global_variables
share_global_variables(){
    # create new file to hold all global variables
    local __vars_file="$(mktemp --suffix=.sh 2>/dev/null || mktemp)"
    local __tmpst=0
    #print all global variables of progtoolsv2.sh script into $__vars_file, to share it with run script
    print_my_global_variables "$__vars_file" || { __tmpst=$? ;  err "cannot pass global variables" $__ERROR $__RETURN $__tmpst; return $?; }

    #print file name
    echo -n "$__vars_file"
    return 0
 }
 
# [TEST]: PASS 
# wrapper for print_all_global_variables
share_all_global_variables(){
    # create new file to hold all global variables
    local __vars_file="$(mktemp --suffix=.sh 2>/dev/null || mktemp)"
    local __tmpst=0
    #print all global variables of progtoolsv2.sh script into $__vars_file, to share it with run script
    print_all_global_variables "$__vars_file" || { __tmpst=$? ;  err "cannot pass global variables" $__ERROR $__RETURN $__tmpst; return $?; }

    #print file name
    echo -n "$__vars_file"
    return 0
 }


declare_global_variables(){
    validate_params $# 1 1 || return $?
    local tmp="$(mktemp --suffix=.sh 2>/dev/null || mktemp)"
    local __old_ifs="$IFS"    
    while IFS=$'\n' read -r  __line; do
        local __buffer+="$__line"
        bash  -n <<< "$__buffer" 2>/dev/null || { __buffer+="
" ;continue; }

        # __regex="^declare -[a-zA-Z0-9_-] (\w+)"
        local __regex='^declare[[:space:]]+-[^[:space:]]+[[:space:]]+([[:alnum:]_]+)'
        if [[ "$__buffer" =~ $__regex  ]]; then
            local __variable="${BASH_REMATCH[1]}"
        fi

        if declare -p "$__variable" >/dev/null 2>&1; then
            true
        else 
            echo "$__buffer"
        fi  
        __buffer=""
    done < "$1" > "$tmp"
    IFS="$__old_ifs"
    echo -n "$tmp"
}



# [TEST]: PASS
check_bin_dependencies(){

    validate_params $# 1 - || return $?    

    local -a __missing
    # get the missing commands
    for i in "$@"; do 
        command -v "$i" &>/dev/null || __missing+=( "$i" )
    done
    if [ ${#__missing[@]} -lt 1 ]; then
        return 0
    fi
    local __distro=""
    local __pkg_manager=""
    local __install_cmd=""
        
    if command -v lsb_release &>/dev/null; then
        __distro="$(/usr/bin/env lsb_release -si | tr '[:upper:]' '[:lower:]')"

    elif [ -f /etc/os-release ]; then
        __distro="$( ( . /etc/os-release; echo "$ID" ) | tr '[:upper:]' '[:lower:]' )"
    else

        if [ -f /etc/alpine-release ]; then
            __distro="alpine"
            __pkg_manager="apk"
        elif [ -f /etc/debian_version ]; then
            __distro="debian"
            __pkg_manager="apt"
        elif [ -f /etc/SuSE-release ]; then
            __distro="suse"
            __pkg_manager="zypper"
        elif [ -f /etc/gentoo-release ]; then
            __distro="gentoo"
            __pkg_manager="emerge"
        elif [ -f /etc/redhat-release ]; then
            __distro="redhat"
            __pkg_manager="yum"  
        elif [ -f /etc/arch-release ]; then
            __distro="arch"
            __pkg_manager="pacman"
        fi


    fi


    # for testing only 
    # __distro=nixos 
    # __distro=nixosaa 
    # __distro=kali 
    # __distro=fedora 


    if [ -z "$__pkg_manager" ]; then
        case "$__distro" in
        ubuntu|debian|linuxmint|elementary|pop|neon|kali|parrot|zorin|peppermint)
            __pkg_manager="apt"
            ;;
        fedora|rhel|centos|rocky|almalinux|redhat)
            __pkg_manager="dnf"
            ;;
        arch|manjaro|garuda|endeavouros)
            __pkg_manager="pacman"
            ;;
        gentoo)
            __pkg_manager="emerge"
            ;;
        suse|opensuse|opensuse-leap|opensuse-tumbleweed)
            __pkg_manager="zypper"
            ;;
        alpine)
            __pkg_manager="apk"
            ;;
        void)
            __pkg_manager="xbps-install"
            ;;
        nixos)
            __pkg_manager="nix-env"
            ;;
        clear-linux)
            __pkg_manager="swupd"
            ;;
        solus)
            __pkg_manager="eopkg"
            ;;
        esac
    fi
    # get the OS type and the package manager


    # Build install command
    case "$__pkg_manager" in
        apt) __install_cmd="sudo apt install -y" ;;
        dnf) __install_cmd="sudo dnf install -y" ;;
        yum) __install_cmd="sudo yum install -y" ;;
        pacman) __install_cmd="sudo pacman -S --noconfirm" ;;
        zypper) __install_cmd="sudo zypper install -y" ;;
        apk) __install_cmd="sudo apk add" ;;
        emerge) __install_cmd="sudo emerge" ;;
        xbps-install) __install_cmd="sudo xbps-install -Sy" ;;
        nix-env) __install_cmd="nix-env -iA nixpkgs" ;; # Usage: nix-env -iA nixpkgs.pkgname
        swupd) __install_cmd="sudo swupd bundle-add" ;;
        eopkg) __install_cmd="sudo eopkg install -y" ;;
        *) __install_cmd="" ;;
    esac

    echo -en "Missing dependencies:\n\t"
    print_list  __missing[@] " , "
    echo ""

    if [ -z "$__install_cmd" ]; then
        return  91 
    elif [[ "$__install_cmd" =~ ^nix-env  ]];then 
        echo "use the following command to install: $__install_cmd.$(print_list __missing[@] " nixpkgs.")"    
    else 
        echo "use the following command to install: $__install_cmd ${__missing[*]}"
    fi
    return  91

}


# [TEST]: 
check_pkg_dependencies(){

    validate_params $# 1 - || return $?    

    local -a __missing
    # get the missing commands
    convert_args_to_list "$@" || return $?
    

   
    local __distro=""
    local __pkg_manager=""
    local __install_cmd=""
        
    if command -v lsb_release &>/dev/null; then
        __distro="$(/usr/bin/env lsb_release -si | tr '[:upper:]' '[:lower:]')"

    elif [ -f /etc/os-release ]; then
        __distro="$( ( . /etc/os-release; echo "$ID" ) | tr '[:upper:]' '[:lower:]' )"
    else

        if [ -f /etc/alpine-release ]; then
            __distro="alpine"
            __pkg_manager="apk"
        elif [ -f /etc/debian_version ]; then
            __distro="debian"
            __pkg_manager="apt"
        elif [ -f /etc/SuSE-release ]; then
            __distro="suse"
            __pkg_manager="zypper"
        elif [ -f /etc/gentoo-release ]; then
            __distro="gentoo"
            __pkg_manager="emerge"
        elif [ -f /etc/redhat-release ]; then
            __distro="redhat"
            __pkg_manager="yum"  
        elif [ -f /etc/arch-release ]; then
            __distro="arch"
            __pkg_manager="pacman"
        fi


    fi


    # for testing only 
    # __distro=nixos 
    # __distro=nixosaa 
    # __distro=kali 
    # __distro=fedora 


    if [ -z "$__pkg_manager" ]; then
        case "$__distro" in
        ubuntu|debian|linuxmint|elementary|pop|neon|kali|parrot|zorin|peppermint)
            __pkg_manager="apt"
            ;;
        fedora|rhel|centos|rocky|almalinux|redhat)
            __pkg_manager="dnf"
            ;;
        arch|manjaro|garuda|endeavouros)
            __pkg_manager="pacman"
            ;;
        gentoo)
            __pkg_manager="emerge"
            ;;
        suse|opensuse|opensuse-leap|opensuse-tumbleweed)
            __pkg_manager="zypper"
            ;;
        alpine)
            __pkg_manager="apk"
            ;;
        void)
            __pkg_manager="xbps-install"
            ;;
        nixos)
            __pkg_manager="nix-env"
            ;;
        clear-linux)
            __pkg_manager="swupd"
            ;;
        solus)
            __pkg_manager="eopkg"
            ;;
        esac
    fi
    # get the OS type and the package manager


    # Build install command
    case "$__pkg_manager" in
        apt) __install_cmd="sudo apt install -y" ;;
        dnf) __install_cmd="sudo dnf install -y" ;;
        yum) __install_cmd="sudo yum install -y" ;;
        pacman) __install_cmd="sudo pacman -S --noconfirm" ;;
        zypper) __install_cmd="sudo zypper install -y" ;;
        apk) __install_cmd="sudo apk add" ;;
        emerge) __install_cmd="sudo emerge" ;;
        xbps-install) __install_cmd="sudo xbps-install -Sy" ;;
        nix-env) __install_cmd="nix-env -iA nixpkgs" ;; # Usage: nix-env -iA nixpkgs.pkgname
        swupd) __install_cmd="sudo swupd bundle-add" ;;
        eopkg) __install_cmd="sudo eopkg install -y" ;;
        *) __install_cmd="" ;;
    esac

    echo -en "Missing dependencies:\n\t"
    print_list  __missing[@] " , "
    echo ""

    if [ -z "$__install_cmd" ]; then
        return  91 
    elif [[ "$__install_cmd" =~ ^nix-env  ]];then 
        echo "use the following command to install: $__install_cmd.$(print_list __missing[@] " nixpkgs.")"    
    else 
        echo "use the following command to install: $__install_cmd ${__missing[*]}"
    fi
    return  91

}



# [TEST]: PASS
not_implemented(){
    err "${FUNCNAME[1]}() function is not implemnted yet!" $__ERROR $__EXIT 100
}


# [TEST]: PASS, but cannot handle non numeric values
validate_params(){

    if [ "$#" != "3" ]; then
        err  "Invalid arguments number to validate_params() function." $__ERROR $__RETURN 93; return $?
    fi
    local __number_of_params="$1"
    local __min_params="$2"
    local __max_params="$3"
    local __function_name="${FUNCNAME[1]}"    
    if [ "$__min_params" != "-" ] && [ "$__number_of_params" -lt "$__min_params" ]; then
        err  "Few arguments to $__function_name() function." $__ERROR $__RETURN 93; return $?
    elif [ "$__max_params" != "-" ] &&  [ "$__number_of_params" -gt "$__max_params" ]; then
        err  "Many arguments to $__function_name() function." $__ERROR $__RETURN 93; return $?
    fi

    
}




# [TEST]: PASS 
# function to print colorful result of a function/executable
# if status code is 0, then the output will be green, else
# it will be red
print_result(){
    validate_params $# 1 -  || return $?
    local __status_code="$1"
    if ! [[ "$__status_code" =~ ^[0-9]+$ ]]; then
        return
    fi

    # get the number of columns in the terminal
    local __cols="$(/usr/bin/env tput cols 2>/dev/null || echo -n "30")"

    # construct the pattern
    local __pattern=""

    local __color=""
    
    for ((i = 0; i < __cols; i++)); do
        __pattern+="═"
    done

    if [ "$__status_code" -eq 0 ]; then
	    __color="32m" #green
    else
	    __color="31m" #red
    fi
    
    # print the pattern
    echo "" >&2
    echo -e "\033[$__color$__pattern\033[m" >&2
    echo -e "status code: \033[1;$__color $__status_code\033[m " >&2
    shift 1
    for i in "$@";do
        echo -e "$i" >&2
    done    

    echo -e "\033[$__color$__pattern\033[m" >&2
    return 0
}


urldecode() { : "${*//+/ }"; echo -e "${_//%/\\x}"; }
