#!/usr/bin/env perl
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





use Getopt::Long;

($config_file, $data_file, $len, $nomatch,$real_len,$isheaderless) = ("",  "", 0, "N/A",0,0);

$alternate_regexes_max=25;
GetOptions(
    "c=s" => \$config_file,             # config file
    "i=s" => \$data_file,               # data file
    "n=s" => \$nomatch,                 # string for no match
    "headerless!" => \$isheaderless,    # headerless option    
) or die("Error in command line arguments\n");

# Validate required file
die("Missing required arguments: -c\n")
  unless $config_file ;

# Open config file
open( $config_fh, '<', $config_file)   or die "Cannot open $config_file: $!";


# Input source: file or STDIN
if ($data_file) {
    open($data_fh, '<', $data_file) or die "Cannot open $data_file: $!";
} else {
    $data_fh = *STDIN;
}



# extract fields/groups/regexes into lists
while ( $line=readline($config_fh)) {
    $len++;
    chomp $line;
    if ($line=~/^$/){
        next;
    }


    # regex: first group (handles escaped colons), second group (same), last = remainder
    if ($line =~ /^((?:\\:|[^:])*):((?:\\:|[^:])*):(.*)$/) {
        ($field, $group, $regex) = ($1, $2, $3);

        # unescape "\:" back to ":"
        s/\\:/:/g for ($field, $group);
    }




    if ($field=~/^$/){
        # if the line is empty, then name the field with "no name"
        push(@fields,"no name");
    } else {
        push(@fields,$field);
    }

    # wrapping/escaping special chars
    # default: wrap/ escape
    # *: no wrap/ no escape
    # ?: double wrap/ no escape
    # %: wrap/ no escape

    # matching special chars
    # digits: capture groups [allowed special chars */?/%]
    # word chars: named capture groups [allowed special chars */?/%]
    # $$$ word chars: replace the word after $$$ with the environment var [allowed special chars */?/%]
    # $$$$ word chars: replace the word after $$$$ with the literal word [allowed special chars */?/%]
    # $!$ word chars: if the regex matched, then the cell will be no match
    # $!! word chars: if the regex matched, then delete the whole row



    if ($group=~/^\d+$/){
        push(@groups,$group);
        push(@specialvars,"");
        push(@literals,"");
        push(@matches,"ewg");

    } elsif ($group=~/^\${3}\w+$/){
        push(@groups,"");
        push(@literals,"");
        $group=~s/^\$\$\$//g;
        push(@specialvars,$group);
        push(@matches,"ews");

    } elsif ($group=~/^\${4}.+/){
        push(@groups,"");
        push(@specialvars,"");
        $group=~s/^\$\$\$\$//g;
        push(@literals,$group);
        push(@matches,"ewl");

    } elsif ($group=~/^\$\!\$.+/){
        push(@groups,"");
        push(@specialvars,"");
        push(@literals,$nomatch);
        push(@matches,"ewl");

    } elsif ($group=~/^\$!!.*/){
        push(@groups,"");
        push(@specialvars,"");
        push(@literals,"");
        push(@matches,"d");

    } elsif ($group=~/^\w+/){
        push(@groups,$group);
        push(@specialvars,"");
        push(@literals,"");
        push(@matches,"ewn");

    } elsif ($group=~/^%\d+$/){
        $group=~s/^%//g;
        push(@groups,$group);
        push(@specialvars,"");
        push(@literals,"");
        push(@matches,"wg");

    } elsif ($group=~/^%\${3}\w+$/){
        push(@groups,"");
        push(@literals,"");
        $group=~s/^%\$\$\$//g;
        push(@specialvars,$group);
        push(@matches,"ws");

    } elsif ($group=~/^%\${4}.+/){
        push(@groups,"");
        push(@specialvars,"");
        $group=~s/^%\$\$\$\$//g;
        push(@literals,$group);
        push(@matches,"wl");

    } elsif ($group=~/^%$/){
        push(@groups,"&");
        push(@specialvars,"");
        push(@literals,"");
        push(@matches,"wg");

    } elsif ($group=~/^%\w+/){
        $group=~s/^%//g;
        push(@groups,$group);
        push(@specialvars,"");
        push(@literals,"");
        push(@matches,"wn");

    } elsif ($group=~/^\?\d+$/){
        $group=~s/^\?//g;
        push(@groups,$group);
        push(@specialvars,"");
        push(@literals,"");
        push(@matches,"wwg");

    } elsif ($group=~/^\?\${3}\w+$/){
        push(@groups,"");
        push(@literals,"");
        $group=~s/^\?\$\$\$//g;
        push(@specialvars,$group);
        push(@matches,"wws");

    } elsif ($group=~/^\?\${4}.+/){
        push(@groups,"");
        push(@specialvars,"");
        $group=~s/^\?\$\$\$\$//g;
        push(@literals,$group);
        push(@matches,"wwl");

    } elsif ($group=~/^\?$/){
        push(@groups,"&");
        push(@specialvars,"");
        push(@literals,"");
        push(@matches,"wwg");

    } elsif ($group=~/^\?\w+/){
        $group=~s/^\?//g;
        push(@groups,$group);
        push(@specialvars,"");
        push(@literals,"");
        push(@matches,"wwn");


    } elsif ($group=~/^\*\d+$/){
        $group=~s/^\*//g;
        push(@groups,$group);
        push(@specialvars,"");
        push(@literals,"");
        push(@matches,"g");

    } elsif ($group=~/^\*\${3}\w+$/){
        push(@groups,"");
        push(@literals,"");
        $group=~s/^\*\$\$\$//g;
        push(@specialvars,$group);
        push(@matches,"s");

    } elsif ($group=~/^\*\${4}.+/){
        push(@groups,"");
        push(@specialvars,"");
        $group=~s/^\*\$\$\$\$//g;
        push(@literals,$group);
        push(@matches,"l");

    } elsif ($group=~/^\*$/){
        push(@groups,"&");
        push(@specialvars,"");
        push(@literals,"");
        push(@matches,"g");

    } elsif ($group=~/^\*\w+/){
        $group=~s/^\*//g;
        push(@groups,$group);
        push(@specialvars,"");
        push(@literals,"");
        push(@matches,"n");



    } else {
        # if no group was specified, then use & "the whole capture"
        push(@groups,"&");
        push(@literals,"");
        push(@specialvars,"");
        push(@matches,"ewg");
    }


    if ($regex=~/^$/){
        push(@regexes,"");
    } else {
        push(@regexes,qr/$regex/);
    }
    
}





%alternate_fields=();
%alternate_regexes=();
%alternate_groups=();
%alternate_literals=();
%alternate_specialvars=();
%alternate_matches=();


for($i=0;$i<$len;$i++){
    $count=0;
    $field_name=$fields[$i];
    if($alternate_fields{"$field_name"}==1) {
        next;
    } else {
        push(@unique_fields,$field_name);
        $real_len++;
    }
    for($j=$i;$j<$len;$j++){
        if ("$field_name" eq "$fields[$j]"){

            $alternate_fields{"$field_name"}=1;
            $alternate_regexes{"$field_name.$count"}=$regexes[$j];
            $alternate_groups{"$field_name.$count"}=$groups[$j];
            $alternate_literals{"$field_name.$count"}=$literals[$j];
            $alternate_specialvars{"$field_name.$count"}=$specialvars[$j];
            $alternate_matches{"$field_name.$count"}=$matches[$j];

            $count++;
            
        }
    }
}



close($config_fh);


if ($isheaderless == 0) {
    $header=join("\",\"",@unique_fields);
    print ("\"$header\"\n");
}
@row=();
OUTER:
while ($line = readline($data_fh)) {
    chomp $line;
    for ($i=0;$i<$real_len;$i++) {
        for ($j=0;$j<$alternate_regexes_max;$j++){
            $index="$unique_fields[$i].$j";
            $regex=$alternate_regexes{$index};
       
            $match=$alternate_matches{$index};
       
            if (length $regex > 0 ) {
                if ($line =~ $regex) {                
                    if ($match eq "ewg") { 
                        $group=$alternate_groups{$index};

                        $cell=$$group;
                        $cell =~ s/"/""/g;
                        push(@row,"\"$cell\"");
                        last;
                    } elsif ($match eq "ews") {
                        $specialvar=$alternate_specialvars{$index};
                        $cell=$ENV{$specialvar};
                        $cell=~s/"/""/g;
                        push(@row,"\"$cell\"");
                        last;
                    } elsif ($match eq "ewl") {
                        $literal=$alternate_literals{$index};
                        $cell=$literal;
                        $cell=~s/"/""/g;

                        push(@row,"\"$cell\"");
                        last;
                    } elsif ($match eq "d") { 
                        @row=();
                        next OUTER;
                    } elsif ($match eq "ewn") { 
                        $group=$alternate_groups{$index};
                        $cell=$+{$group};
                        $cell=~s/"/""/g;
                        push(@row,"\"$cell\"");
                        last;
                    } elsif ($match eq "wg") { 
 
                        $group=$alternate_groups{$index};
                        $cell=$$group;

                        push(@row,"\"$cell\"");
                        last;
                    } elsif ($match eq "ws") {
                        $specialvar=$alternate_specialvars{$index};
                        $cell=$ENV{$specialvar};
                        push(@row,"\"$cell\"");
                        last;
                    } elsif ($match eq "wl") {
                        $literal=$alternate_literals{$index};
                        $cell=$literal;
                        push(@row,"\"$cell\"");
                        last;
                    } elsif ($match eq "wn") { 
                        $group=$alternate_groups{$index};
                        $cell=$+{$group};
                        push(@row,"\"$cell\"");
                        last;
          


                    } elsif ($match eq "g") { 
                        $group=$alternate_groups{$index};
                        $cell=$$group;
                        push(@row,$cell);
                        last;
                    } elsif ($match eq "s") {
                        $specialvar=$alternate_specialvars{$index};
                        $cell=$ENV{$specialvar};
                        push(@row,$cell);
                        last;
                    } elsif ($match eq "l") {
                        $literal=$alternate_literals{$index};
                        $cell=$literal;
                        push(@row,$cell);
                        last;
                    } elsif ($match eq "n") { 
                        $group=$alternate_groups{$index};
                        $cell=$+{$group};
                        push(@row,$cell);
                        last;
          


                    } elsif ($match eq "wwg") { 
                        $group=$alternate_groups{$index};
                        $cell=$$group;
                        push(@row,"\"\"$cell\"\"");
                        last;
                    } elsif ($match eq "wws") {
                        $specialvar=$alternate_specialvars{$index};
                        $cell=$ENV{$specialvar};
                        push(@row,"\"\"$cell\"\"");
                        last;
                    } elsif ($match eq "wwl") {
                        $literal=$alternate_literals{$index};
                        $cell=$literal;
                        push(@row,"\"\"$cell\"\"");
                        last;
                    } elsif ($match eq "wwn") { 
                        $group=$alternate_groups{$index};
                        $cell=$+{$group};
                        push(@row,"\"\"$cell\"\"");
                        last;
          


                    } else {
                        push(@row,"\"$nomatch\"");
                        last;
                    }
                } else {
                    next;
                }
                            
            
            } else {
                if ($match eq 'ews') {
                    $specialvar=$alternate_specialvars{$index};
                    $cell=$ENV{$specialvar};
                    $cell=~s/"/""/g;
                    push(@row,"\"$cell\"");
                    last;
                } elsif ($match eq 'ewl') {
                    $literal=$alternate_literals{$index};
                    $cell=$literal;
                    $cell=~s/"/""/g;
                    push(@row,"\"$cell\"");
                    last;

                } elsif ($match eq 'ws') {
                    $specialvar=$alternate_specialvars{$index};
                    $cell=$ENV{$specialvar};
                    push(@row,"\"$cell\"");
                    last;
                } elsif ($match eq 'wl') {
                    $literal=$alternate_literals{$index};
                    $cell=$literal;
                    push(@row,"\"$cell\"");
                    last;



                } elsif ($match eq 'wws') {
                    $specialvar=$alternate_specialvars{$index};
                    $cell=$ENV{$specialvar};
                    push(@row,"\"\"$cell\"\"");
                    last;
                } elsif ($match eq 'wwl') {
                    $literal=$alternate_literals{$index};
                    $cell=$literal;
                    push(@row,"\"\"$cell\"\"");
                    last;


                } elsif ($match eq 's') {
                    $specialvar=$alternate_specialvars{$index};
                    $cell=$ENV{$specialvar};
                    push(@row,$cell);
                    last;
                } elsif ($match eq 'l') {
                    $literal=$alternate_literals{$index};
                    $cell=$literal;
                    push(@row,$cell);
                    last;
                } elsif ($match eq "d") { 
                    @row=();
                    next OUTER;
                } else {
                    push(@row,"\"$nomatch\"");
                    last;
                }
            }
            if ($j >= $alternate_regexes-1) {
                push(@row,"\"$nomatch\"");
                last;
            }
        }
    }       
    print join(",",@row) . "\n";
    $#row = -1;
}

close($data_fh);



