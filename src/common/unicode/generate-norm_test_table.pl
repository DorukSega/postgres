#!/usr/bin/perl
#
# Read Unicode consortium's normalization test suite, NormalizationTest.txt,
# and generate a C array from it, for norm_test.c.
#
# NormalizationTest.txt is part of the Unicode Character Database.
#
# Copyright (c) 2000-2024, PostgreSQL Global Development Group

use strict;
use warnings FATAL => 'all';

use File::Basename;

die "Usage: $0 INPUT_FILE OUTPUT_FILE\n" if @ARGV != 2;
my $input_file = $ARGV[0];
my $output_file = $ARGV[1];
my $output_base = basename($output_file);

# Open the input and output files
open my $INPUT, '<', $input_file
  or die "Could not open input file $input_file: $!";
open my $OUTPUT, '>', $output_file
  or die "Could not open output file $output_file: $!\n";

# Print header of output file.
print $OUTPUT <<HEADER;
/*-------------------------------------------------------------------------
 *
 * norm_test_table.h
 *	  Test strings for Unicode normalization.
 *
 * Portions Copyright (c) 1996-2024, PostgreSQL Global Development Group
 * Portions Copyright (c) 1994, Regents of the University of California
 *
 * src/common/unicode/norm_test_table.h
 *
 *-------------------------------------------------------------------------
 */

/*
 * File auto-generated by src/common/unicode/generate-norm_test_table.pl, do
 * not edit. There is deliberately not an #ifndef PG_NORM_TEST_TABLE_H
 * here.
 */

typedef struct
{
	int			linenum;
	pg_wchar	input[50];
	pg_wchar	output[4][50];
} pg_unicode_test;

/* test table */
HEADER
print $OUTPUT
  "static const pg_unicode_test UnicodeNormalizationTests[] =\n{\n";

# Helper routine to convert a space-separated list of Unicode characters to
# hexadecimal list format, suitable for outputting in a C array.
sub codepoint_string_to_hex
{
	my $codepoint_string = shift;

	my $result;

	foreach (split(' ', $codepoint_string))
	{
		my $cp = $_;
		my $utf8 = "0x$cp, ";
		$result .= $utf8;
	}
	$result .= '0';    # null-terminated the array
	return $result;
}

# Process the input file line by line
my $linenum = 0;
while (my $line = <$INPUT>)
{
	$linenum = $linenum + 1;
	if ($line =~ /^\s*#/) { next; }    # ignore comments

	if ($line =~ /^@/) { next; }       # ignore @Part0 like headers

	# Split the line wanted and get the fields needed:
	#
	# source; NFC; NFD; NFKC; NFKD
	my ($source, $nfc, $nfd, $nfkc, $nfkd) = split(';', $line);

	my $source_utf8 = codepoint_string_to_hex($source);
	my $nfc_utf8 = codepoint_string_to_hex($nfc);
	my $nfd_utf8 = codepoint_string_to_hex($nfd);
	my $nfkc_utf8 = codepoint_string_to_hex($nfkc);
	my $nfkd_utf8 = codepoint_string_to_hex($nfkd);

	print $OUTPUT
	  "\t{ $linenum, { $source_utf8 }, { { $nfc_utf8 }, { $nfd_utf8 }, { $nfkc_utf8 }, { $nfkd_utf8 } } },\n";
}

# Output terminator entry
print $OUTPUT "\t{ 0, { 0 }, { { 0 }, { 0 }, { 0 }, { 0 } } }";
print $OUTPUT "\n};\n";

close $OUTPUT;
close $INPUT;
