#!/usr/bin/perl

# usage: compile-et input.et

# The contents of this file are subject to the Netscape Public License
# Version 1.0 (the "NPL"); you may not use this file except in
# compliance with the NPL.  You may obtain a copy of the NPL at
# http://www.mozilla.org/NPL/
# 
# Software distributed under the NPL is distributed on an "AS IS" basis,
# WITHOUT WARRANTY OF ANY KIND, either express or implied. See the NPL
# for the specific language governing rights and limitations under the
# NPL.
# 
# The Initial Developer of this code under the NPL is Netscape
# Communications Corporation.  Portions created by Netscape are
# Copyright (C) 1998 Netscape Communications Corporation.  All Rights
# Reserved.

sub header
{
    local($filename, $comment) = @_;

<<EOF
$comment
$comment $filename
$comment This file is automatically generated; please do not edit it.
EOF
}

sub table_base
{
    local($name) = @_;
    local($base) = 0;

    for ($i = 0; $i < length($name); $i++) {
	$base *= 64;
	$base += index("ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789_", substr($name, $i, 1)) + 1;
    }
    $base -= 0x1000000 if ($base > 0x7fffff);
    $base*256;
}

sub code {
    local($macro, $text) = @_;
    $code = $table_base + $table_item_count;

    printf H "#define %-40s (%dL)\n", $macro, $code;

    print C "\t{\"", $macro, "\",    \"", $text, "\"},\n";

    print PROPERTIES $macro, "=", $text, "\n";

    $table_item_count++;
}


$filename = $ARGV[0];
open(INPUT, "< $filename") || die "Can't read $filename: $!\n";

$base = "$filename";
$base =~ s/\.et$//;
$base =~ s#.*/##;

open(H, "> ${base}.h") || die "Can't write ${base}.h\n";
open(C, "> ${base}.c") || die "Can't write ${base}.c\n";
open(PROPERTIES, "> ${base}.properties") || die "Can't write ${base}.properties\n";

print H "/*\n", &header("${base}.h", " *"), " */\n";
print C "/*\n", &header("${base}.c", " *"), " */\n";
print PROPERTIES &header("${base}.properties", "#");

$skipone = 0;

while ($_ = <INPUT>) {
    next if /^#/;

    if (/^[ \t]*(error_table|et)[ \t]+([a-zA-Z][a-zA-Z0-9_]+) *(-?[0-9]*)/) {
	$table_name = $2;
	if ($3) {
	    $table_base = $3;
	}
	else {
	    $table_base = &table_base($table_name);
	}
	$table_item_count = 0;

	print C "#include \"prerrorplugin.h\"\n";
	print C "static const struct PRErrorMessage text[] = {\n";
    }
    elsif (/^[ \t]*(error_code|ec)[ \t]+([A-Z_0-9]+),[ \t]*$/) {
	$skipone = 1;
	$macro = $2;
    }
    elsif (/^[ \t]*(error_code|ec)[ \t]+([A-Z_0-9]+),[ \t]*"(.*)"[ \t]*$/) {
	&code($2, $3);
    }
    elsif ($skipone && /^[ \t]*"(.*)"[ \t]*$/) {
	&code($macro, $1);
    }
}

print H "extern void ", $table_name, "_InitializePRErrorTable","(void);\n";
printf H "#define ERROR_TABLE_BASE_%s (%dL)\n", $table_name, $table_base;

print C "\t{0, 0}\n";
print C "};\n\n";
printf C "static const struct PRErrorTable et = { text, \"%s\", %dL, %d };\n",
    $base, $table_base, $table_item_count;
print C "\n";
print C "void ", $table_name, "_InitializePRErrorTable", "() {\n";
print C "    PR_ErrorInstallTable(&et);\n";
print C "}\n";

0;
