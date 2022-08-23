#!/bin/bash
rm -rf test_cases/ 2>&1 > /dev/null
mkdir test_cases 2>&1 > /dev/null
./reference/rc4hash -p ogwdyyvmacwxkltbgohznvrxfwhkhfutpcqkxwjcibanjvsnsshpvmmzctlrabgqjslpumzpjopwdiczfinfkxntwqvnpccjlziplfulniopvbjezoxefcnbemumftyhuaokkidllrbvchrbwvmoegqksvcvhhyakxnrebagacagteezqkrkpfhnetlggckagphwqaiecxtdvrhxkwynmxxxpdptsaalythhfwdhjwhlgbvcxbrzzlfiocjibjxq -d 0 -s 0x4030201 > test_cases/test_case1.txt
