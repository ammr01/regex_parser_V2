#!/usr/bin/env bash
# Author : Amr Alasmer
# Project Name : Amr Bash Library
# License: LGPLv3 or later

# Copyright (C) 2025 Amr Alasmer





# to check if the files.sh file is sourced before, if yes,
# then return 'not to complete the sourcing', to prevent
# multiple sourcing
[ -v __files_sourced_before ] && return
__files_sourced_before=1




if [ ! -v __out_sourced_before ]; then 
    __lib_path="$(dirname "`realpath "${BASH_SOURCE[0]}"`")"
    { [ -f "$__lib_path/out.sh" ] &&  source "$__lib_path/out.sh"; } || {>&2 echo "Error : Missing File: $__lib_path/out.sh"; exit 99;}
fi




# [TEST]: PASS 
delete_directory(){
    validate_params $# 1 1 || return $?    

    local __path="$(/usr/bin/env realpath -m "$1")" 
    if [ -d "$__path" ]; then
        /usr/bin/env rm -r "$__path" || { err "Cannot delete directory $__path, status code of rm is $?" $__ERROR $__RETURN 90 ; return $?; }
        return 0
    else
        err "Cannot find directory $__path" $__ERROR $__RETURN  85 ; return $?;
    fi    
    
}

# [TEST]: PASS
delete_file(){
    validate_params $# 1 1 || return $?    

    local __path="$(/usr/bin/env realpath -m "$1")" 
    if [ -f "$__path" ]; then
        /usr/bin/env rm -r "$__path" || { err "Cannot delete file $__path, status code of rm is $?" $__ERROR $__RETURN 90 ; return $?; }
        return 0
    else
        err "Cannot find file $__path" $__ERROR $__RETURN 85 ; return $?;
    fi    
}

# [TEST]: PASS
add_directory(){          
    validate_params $# 1 2 || return $?    

    local __path="$(/usr/bin/env realpath -m "$1")" 
    local __perms="$2"

    if [ -d "$__path" ]; then
        return 0
    fi    
    /usr/bin/env mkdir -p "$__path" || { err "Cannot create directory $__path" $__ERROR $__RETURN 89 ; return $?; }
    if [ -n "$__perms" ]; then    
        /usr/bin/env chmod "$__perms" "$__path" ||  { err "Cannot change permissions to  directory $__path, status code of chmod is $?" $__ERROR $__RETURN 88 ; return $?; }
    fi 
    return 0

}


# [TEST]: PASS
add_file(){
    validate_params $# 1 2 || return $?    

    local __path="$(/usr/bin/env realpath -m "$1")" 
    local __perms="$2"
    local __dir="$(/usr/bin/env dirname  "$__path")"

    if [ -f "$__path" ]; then
        return 0
    fi    



    if [ ! -d "$__dir" ]; then
        add_directory "$__dir" || return $?
    fi    

    /usr/bin/env touch "$__path" || { err "Cannot create file: $__path" $__ERROR $__RETURN 89 ; return $?; }
    

    if [ -n "$__perms" ]; then    
        /usr/bin/env chmod "$__perms" "$__path"  || { err "Cannot set $__path permissions to $__perms, chmod status code: $?." $__ERROR $__RETURN 88 ; return $?; }
    fi
    
}


# [TEST]: PASS 
copy_file(){
    validate_params $# 2 2 || return $?    

    local __source="$(/usr/bin/env realpath -m "$1")" 
    local __destination="$(/usr/bin/env realpath -m "$2")" 

    if [ ! -r "$__source" ]; then
        err "Cannot read/find $__source" $__ERROR $__RETURN 99 ; return $?
    fi
    local __destination_dir="$(/usr/bin/env dirname "$__destination" 2>/dev/null)"
    if [ ! -d "$__destination_dir" ]; then
        add_directory "$__destination_dir" || { err "Cannot add directory $__destination_dir" $__ERROR $__RETURN $? ; return $?; }
    fi

    /usr/bin/env cp -rp "$__source" "$__destination" ||  { err "Cannot copy $__source to $__destination" $__ERROR $__RETURN 98; return $?; }
    return 0
}


# [TEST]: PASS
edit_file_w_editor_options(){
    validate_params $# 2 - || return $?    

    local __editor="$1" 
    local __file="$(/usr/bin/env realpath -m "$2")" 
    shift 2


    if [ ! -f "$__file" ]; then
        add_file "$__file" ||  { err "Cannot add file $__file" $__ERROR $__RETURN $? ; return $?; }
    fi
    
    #check if editor exists
    check_bin_dependencies  "$__editor" || return $?
    /usr/bin/env "$__editor" "$__file" $@  || { err "Cannot open $__file using $__editor , status code of $__editor is $?" $__ERROR $__RETURN 98 ; return $?; }
    
}


# [TEST]: PASS
edit_file(){
    validate_params $# 2 2 || return $?    

    local __editor="$1" 
    local __file="$(/usr/bin/env realpath -m "$2")" 

    if [ ! -f "$__file" ]; then
        add_file "$__file" ||  return $?
    fi
    
    #check if editor exists
    check_bin_dependencies  "$__editor" || return $?
    /usr/bin/env "$__editor" "$__file"  || { err "Cannot open $__file using $__editor , status code of $__editor is $?" $__ERROR $__RETURN 98 ; return $?; }
    
}

cdmkdir(){
    validate_params $# 1 1 || return $?    
    add_directory "$1" || return $?
    cd "$1" || return 84
}


# TODO: test + handle errors
mktempfifo(){
    while true ; do
        pipe="`/usr/bin/env mktemp -u`"    
        if [ ! -p "$pipe"  ];  then
            /usr/bin/env mkfifo "$pipe"
            break
        fi
    done
    echo -n "$pipe" 
}
