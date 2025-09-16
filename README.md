# regex_parser_V2

## Overview
`regex_parser_V2` is a bash script designed to extract and parse data using regex from raw data, and build CSV tables from the input data. It is a lightweight and efficient tool for parsing fields defined by configuration files.

---

## What's new in V2
  - better control over output data "matching methods"
  - add alternate regexes "regexes to match if the previous regexes are not matching"
  - accept input from stdin for realtime parsing
  - allow for simple data enrichment
  - add headerless mode to add csv header in output file
  - general performance enhancments
  - add signal handling "handle sighup by sending sigstop/sigcont to the core 'perl' parser"
      
---


## Requirements
- **Dependencies:**
  - Perl
  - dos2unix
  - sed
### Installing Dependencies
To install the required dependencies on Debian-based systems, run:
```bash
sudo apt update && sudo apt install perl dos2unix sed -y
```

---

## Usage

### Syntax
```bash
./regex_parser_V2.sh [OPTIONS]
```

### Options
- `-h`, `--help` : Show help and exit.
- `-i`, `--input-file <file>` : Specify input data file(s). Multiple files can be specified.
- `-o`, `--output-file <file>` : Specify the output CSV file.
- `-c`, `--config-file <file>` : Specify configuration file(s) with parsing instructions.
- `-n`, `--no-match-string <string>` : Specify the string to replace in cells with no mathces. 
- `--headerless` : Set the headerless mode, which will not include CSV header in the output.


### Example
```bash
./regex_parser_V2.sh -i input1.txt -i input2.csv -o output.csv -c config1.txt -c config2.conf
```
```bash
./regex_parser_V2.sh  -o output.csv -c config1.txt -c config2.conf -n N/A --headerless < input.csv
```

---




## Configuration File Format

The configuration file defines the fields to extract, along with their regex and matching method. Each line should follow this format:

```plaintext
<field_name>:<matching_method>:<regex>
```
- **field_name**: The name of the field to extract.
- **matching_method**: (Optional) the method of matching.
- **regex**: (Optional) The regex pattern to use for parsing.
- **comments**: Use `#` at the start of the line, to make it a comment.

### Matching Methods


For matching method, you can specify the method:

* `digits`: capture groups.
* `word chars`: named capture groups.
* `$$$ word`: if the regex matched, fill the cell with the value of environment variable called 'word'.  
* `$$$$ word`: if the regex matched, fill the cell with the literal string 'word'.      
* `$!$`: if the regex matches, fill the cell with no match string, default is N/A.
* `$!!`: if the regex matches, delete the whole row.

Also you can specify the output formatting

* nothing (default): double-quote wrap + CSV escape: replace inner " with ""
* `*`: no double-quote wrap + no CSV escape
* `?`: double-quote wrap twice + no CSV escape
* `%`: double-quote wrap + no CSV escape



### Example Configuration

```plaintext
# This will print the whole match because no matching method was specified
email::[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}

# This will capture the phone number using capture group 1, and CSV escape the cell + wrap the cell with double-quote
phone:1:(\d{3}-\d{3}-\d{4})

# This will capture the phone number, incase of the previous regex not mathced, the capture will be done using named capture group 'phone'
phone:*phone:(?<phone>\d{3} \d{3} \d{4})

# This will put YES in the 'Phone Included' column, if the regex matched
Phone Included:$$$$YES:(?<phone>\d{3}[ -]\d{3}[ -]\d{4})


# This will put NO in the 'Phone Included' column, if the previous regex not matched
Phone Included:$$$$NO:

```

---


## Where To Use
- It could be used for log parsing, data extraction, and many more use cases.

---



## License
This project is licensed under the GPLV3 License

---

## Author
**Amr Alasmar**
