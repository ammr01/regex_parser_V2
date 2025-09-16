#!/usr/bin/env bash
# Author : Amr Alasmer
# Project Name : Amr Bash Library
# License: LGPLv3 or later

# Copyright (C) 2025 Amr Alasmer

# to check if the arrays.sh file is sourced before, if yes,
# then return 'not to complete the sourcing', to prevent
# multiple sourcing
[ -v __arrays_sourced_before ] && return
__arrays_sourced_before=1

if [ ! -v __out_sourced_before ]; then
    __lib_path="$(dirname "`realpath "${BASH_SOURCE[0]}"`")"
    { [ -f "$__lib_path/out.sh" ] &&  source "$__lib_path/out.sh"; } || {>&2 echo "Error : Missing File: $__lib_path/out.sh"; exit 99;}
fi  




# global list to store result of functions that process a list['s]
__LIST=()

readonly __FIRST_EQUALS_SECOND=0
readonly __SECOND_SUBSET_FIRST=1
readonly __FIRST_SUBSET_SECOND=2
readonly __FIRST_NOT_EQUALS_SUBSET_SECOND=3




# to pass a list to a function, use:     func_name list[@] 


# [TEST]: 
print_list(){
    # print a list, takes two arguments
    # 1. the list it self
    # 2. separator "use `echo -en` to print separator, which means if separator was '\n' it will take as a new line"

    # check arguments number
    validate_params $# 2 2  || return $?


    # receive first argument as a list
    local list=("${!1}") 

    # second argument is the elemnts seperator
    local seperator="$2" 

    local len="${#list[@]}"

    for ((i=0;i<len-1;i++)); do
        echo -n "${list[$i]}"
        echo -ne "$seperator"
    done
    if [ "$len" -gt 0 ]; then
        echo -n "${list[$len-1]}"
    fi
}


# [TEST]: 
convert_args_to_list(){

    # Takes any number of arguments, and convert them into array
    # store the result in global array "__LIST()"

    __LIST=()
    for i in "$@"; do 
        __LIST+=( "$i" )
    done

}

# [TEST]: 
print_list_escaped_chars(){

    # print a list, takes two arguments
    # 1. the list it self
    # 2. separator "use `echo -en` to print separator, which means if 
    # separator was '\n' it will take it as literal two characters '\' and 'n'"

    # check arguments number
    validate_params $# 2 2  || return $?
    
    # receive first argument as a list
    local list=("${!1}") 

    # second argument is the elemnts seperator
    local seperator="$2" 

    local len="${#list[@]}"

    for ((i=0;i<len-1;i++)); do
        printf "${list[$i]}$seperator"
    done
    if [ "$len" -gt 0 ]; then
        printf "${list[$len-1]}"
    fi
}



# [TEST]: 
compare_arrays(){ 
    
    # Takes two arrays as arguments
    # Returns 0 if two arrays are equal
    # Returns 1 if array2 is a subset of array1
    # Returns 2 if array1 is a subset of array2
    # Returns 3 if arrays are not a subset of each other
    # Returns 5 if provided arrays are less than 2 
    # the function DOES NOT require the arrays elements to be sorted or unique 


    ##
    ##  # Time complexity : O(2*n + 2*m), where n is array1's length, m is array2's length
    ##                      ^^^^^^^^^^^^
    ##               simplified to O(n+m)
    
    validate_params $# 2 2  || return $?

    declare -A hash_table1 #associative list
    declare -A hash_table2 #associative list

    local array1=("${!1}") 
    local array2=("${!2}")  
    for element in "${array1[@]}"; do
        if [ ! -z "$element" ] ; then
            hash_table1["$element"]=1 
        fi
    done
    for element in "${array2[@]}"; do
        if [ ! -z "$element" ] ; then
            hash_table2["$element"]=1 
        fi
    done

    local fsubs=true
    local ssubf=true

    for element in "${array2[@]}"; do 
        if [ ! -z "$element" ] ; then
            if [ -z "${hash_table1[$element]}" ]; then 
                ssubf=false
                break
            fi
        fi
    done

    for element in "${array1[@]}"; do
        if [ ! -z "$element" ] ; then
            if [ -z "${hash_table2[$element]}" ]; then 
                fsubs=false
                break
            fi
        fi
    done

    if [ "$fsubs" = true ] && [ "$ssubf" = true ]; then
        return $__FIRST_EQUALS_SECOND # first equals the second
    elif [ "$fsubs" = false ] && [ "$ssubf" = true ]; then
        return $__SECOND_SUBSET_FIRST # second is a subset of first
    elif [ "$fsubs" = true ] && [ "$ssubf" = false ]; then
        return $__FIRST_SUBSET_SECOND # first is a subset of second
    elif [ "$fsubs" = false ] && [ "$ssubf" = false ]; then
        return $__FIRST_NOT_EQUALS_SUBSET_SECOND # first and second are not equal or subset
    else
        return 4
    fi
}



remove_leading_char(){
    
    validate_params $# 2 2  || return $?

    local array=("${!1}")
    local char="$2"

    __LIST=()
    for i in "${array[@]}";do
        __LIST+=( "${i#$char}" )
    done
}



remove_trailing_char(){
   
    validate_params $# 2 2  || return $?

    local array=("${!1}")
    local char="$2"
    __LIST=()
    for i in "${array[@]}";do
        __LIST+=( "${i%$char}" )
    done
}



# [TEST]: 
convert_to_array(){
    # Converts strings to array, elements are separated by separator
    # Stores the output in the global array $__LIST
    # Returns 0 if no errors occurred
    # $1 is the string, $2 is the separator
    # example : convert_to_array "AAA-BBSAAF-A-S" "-"
    # result : __LIST=("AAA" "BBSAAF" "A" "S") 
    
    validate_params $# 2 2  || return $?

    local input="$1"
    local separator="$2"
    __LIST=()
    
    local record_count=$(echo "$input" | awk -v sep="$separator" 'BEGIN{RS=sep}END{print NR}'  )
    local element=""
    for ((i = 1; i <= record_count; i++)); do
        element="$(echo "$input" | awk -v sep="$separator" -v i="$i" 'BEGIN{RS=sep} NR == i {print $0}')"
        if [ -z "$element" ]; then
            break
        fi
        __LIST+=( "$element" )
    done
}

# [TEST]: 
convert_file_to_arrayln(){
    # Convert file content to array 
    # each line is a element 
    # Stores the output in the global array $__LIST
    # Returns 0 if no errors occurred
    # $1 is the file path
    validate_params $# 1 1  || return $?

    local file="$1"
    if [ ! -r "$file" ]; then
        return 1
    fi
    __LIST=()

    # Temporarily change IFS to newline to handle spaces correctly
    while IFS=$'\n' read -r line; do
        __LIST+=( "$line" )
    done < "$file"
}

# [TEST]: 
convert_to_arrayln(){
    # Convert to arrayln 
    # Converts strings to array, each element is a line 
    # Stores the output in the global array $__LIST
    # Returns 0 if no errors occurred
    # $1 is the string
    validate_params $# 1 1  || return $?

    local input="$1"
    __LIST=()

    # Temporarily change IFS to newline to handle spaces correctly
    while IFS=$'\n' read -r line; do
        __LIST+=( "$line" )
    done <<< "$input"
}

# [TEST]: 
remove_forward_slash(){
    # takes list and remove leading forward slash (/) (fs) from all the elements
    
    validate_params $# 1 1  || return $?

    local array=("${!1}")
    __LIST=()
    for i in "${array[@]}";do
        __LIST+=( "${i#/}" )
    done
}

remove_leading_char(){
    
    validate_params $# 2 2  || return $?

    local array=("${!1}")
    local char="$2"

    __LIST=()
    for i in "${array[@]}";do
        __LIST+=( "${i#$char}" )
    done
}



remove_trailing_char(){
   
    validate_params $# 2 2  || return $?

    local array=("${!1}")
    local char="$2"
    __LIST=()
    for i in "${array[@]}";do
        __LIST+=( "${i%$char}" )
    done
}

# [TEST]: 
append_forward_slash(){
    # takes list and append forward slash (/) (fs), to elements that are valid directory
    
    validate_params $# 1 1  || return $?

    local array=("${!1}")
    __LIST=()
    for i in "${array[@]}";do
        local d="${i#/}" 
        local d="/$d"
        if [ -d "$d" ]; then
            __LIST+=( "${i%/}/" )
        else
            __LIST+=( "${i%/}" )
        fi
    done
}


# [TEST]: 
sets_symmetric_difference(){ 
    ####    A △ B
    # Takes two arrays as arguments
    # the function exclude the similar elements in the both arrays, the  
    # function logic is to treat arrays as sets
    # the result array is global array "__LIST"

    validate_params $# 2 2  || return $?


    declare -A hash_table1 #associative list
    declare -A hash_table2 #associative list

    local array1=("${!1}") 
    local array2=("${!2}")  


    __LIST=()

    for element in "${array1[@]}"; do
        if [ ! -z "$element" ] ; then
            hash_table1["$element"]=1 
        fi
    done
    for element in "${array2[@]}"; do
        if [ ! -z "$element" ] ; then
            hash_table2["$element"]=1 
        fi
    done

    for element in "${array1[@]}"; do
        if [ ! -z "$element" ] ; then
            if [ -z "${hash_table2[$element]}" ]; then 
                __LIST+=( "$element" )
            fi
        fi
    done


    for element in "${array2[@]}"; do  
        if [ ! -z "$element" ] ; then
            if [ -z "${hash_table1[$element]}" ]; then 
                __LIST+=( "$element" )
            fi
        fi
    done


    remove_duplicates __LIST[@] || return $?
}

# [TEST]: 
# list2=( "${list[@]}" )
sets_difference(){ 
    
    # Takes two arrays as arguments
    # the function exclude the similar elements in the both arrays, the  
    # function logic is to treat arrays as sets
    # the result array is global array "__LIST"

    
    validate_params $# 2 2  || return $?

    declare -A hash_table1 #associative list
    declare -A hash_table2 #associative list

    local array1=("${!1}") 
    local array2=("${!2}")  


    __LIST=()

    for element in "${array1[@]}"; do
        if [ ! -z "$element" ] ; then
            hash_table1["$element"]=1 
        fi
    done
    for element in "${array2[@]}"; do
        if [ ! -z "$element" ] ; then
            hash_table2["$element"]=1 
        fi
    done

    for element in "${array1[@]}"; do
        if [ ! -z "$element" ] ; then
            if [ -z "${hash_table2[$element]}" ]; then 
                __LIST+=( "$element" )
            fi
        fi
    done


    for element in "${array2[@]}"; do  
        if [ ! -z "$element" ] ; then
            if [ -z "${hash_table1[$element]}" ]; then 
                __LIST+=( "$element" )
            fi
        fi
    done


    remove_duplicates __LIST[@] || return $?
}


# [TEST]: 
sets_intersection(){ 
    ####    A ∩ B
    # Takes two arrays as arguments
    # the function exclude the similar elements in the both arrays, the  
    # function logic is to treat arrays as sets
    # the result array is global array "__LIST"

    validate_params $# 2 2  || return $?

    declare -A hash_table1 #associative list
    declare -A hash_table2 #associative list

    local array1=("${!1}") 
    local array2=("${!2}")  


    __LIST=()

    for element in "${array1[@]}"; do
        if [ ! -z "$element" ] ; then
            hash_table1["$element"]=1 
        fi
    done
    for element in "${array2[@]}"; do
        if [ ! -z "$element" ] ; then
            hash_table2["$element"]=1 
        fi
    done

    for element in "${array1[@]}"; do
        if [ ! -z "$element" ] ; then
            if [ ! -z "${hash_table2[$element]}" ]; then 
                __LIST+=( "$element" )
            fi
        fi
    done

    for element in "${array2[@]}"; do  
        if [ ! -z "$element" ] ; then
            if [ ! -z "${hash_table1[$element]}" ]; then 
                __LIST+=( "$element" )
            fi
        fi
    done


    remove_duplicates __LIST[@] || return $?
}


# [TEST]: 
sets_union(){ 
    ####    A ∪ B
    # Takes two arrays as arguments
    # the function unions the elements in the both arrays, the  
    # function logic is to treat arrays as sets
    # the result array is global array "__LIST"

    
    validate_params $# 2 2  || return $?

    local array1=("${!1}") 
    local array2=("${!2}")  
    __LIST=()


    __LIST+=( "${array1[@]}" )
    __LIST+=( "${array2[@]}" )
    remove_duplicates __LIST[@] || return $?
}


# [TEST]: 
remove_duplicates(){
    # Takes a list as an argument and removes duplicates

    validate_params $# 2 2  || return $?

    declare -A seen
    local array=("${!1}")
    __LIST=()

    for element in "${array[@]}"; do
        if [ -n "$element" ] && [ -z "${seen[$element]}" ]; then
            __LIST+=("$element")
            seen["$element"]=1
        fi
    done

}

