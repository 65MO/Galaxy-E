#!/usr/bin/env python
"""
#
#------------------------------------------------------------------------------
#                                                 University of Minnesota
#                 Copyright 2016, Regents of the University of Minnesota
#------------------------------------------------------------------------------
# Author:
#
#    James E Johnson
#
#------------------------------------------------------------------------------
"""

"""
Split selected columns on pattern
and print a line for each item split

For example:
split_tabular_columns.py -c 3 -c 4 -s '; '
with input line:
1	1.3	id1; id2	desc1; desc2	AMDLID
will be output as:
1	1.3	id1	desc1	AMDLID
1	1.3	id2	desc2	AMDLID
"""

import sys
import os.path
import optparse
from optparse import OptionParser


def __main__():
    # Parse Command Line
    parser = optparse.OptionParser()
    parser.add_option('-i', '--input', dest='input', default=None, help='Tabular input file')
    parser.add_option('-o', '--output', dest='output', default=None, help='Tabular output file')
    parser.add_option('-c', '--column', type='int', action='append', dest='column', default=[], help='column ordinal to split')
    parser.add_option('-s', '--split_on', dest='split_on', default=' ', help='String on which to split columns')
    parser.add_option('-d', '--debug', dest='debug', action='store_true', default=False, help='Turn on wrapper debugging to stderr')
    (options, args) = parser.parse_args()
    # Input file
    if options.input is not None:
        try:
            inputPath = os.path.abspath(options.input)
            inputFile = open(inputPath, 'r')
        except Exception, e:
            print >> sys.stderr, "failed: %s" % e
            exit(2)
    else:
        inputFile = sys.stdin
    # Output file
    if options.output is not None:
        try:
            outputPath = os.path.abspath(options.output)
            outputFile = open(outputPath, 'w')
        except Exception, e:
            print >> sys.stderr, "failed: %s" % e
            exit(3)
    else:
        outputFile = sys.stdout
    split_cols = [x - 1 for x in options.column]
    split_on = options.split_on
    try:
        for i, line in enumerate(inputFile):
            fields = line.rstrip('\r\n').split('\t')
            split_fields = dict()
            cnt = 0
            for c in split_cols:
                if c < len(fields):
                    split_fields[c] = fields[c].split(split_on)
                    cnt = max(cnt, len(split_fields[c]))
            if cnt == 0:
                print >> outputFile, "%s" % '\t'.join(fields)
            else:
                for n in range(0, cnt):
                    flds = [x if c not in split_cols else split_fields[c][n] for (c, x) in enumerate(fields)]
                    print >> outputFile, "%s" % '\t'.join(flds)
    except Exception, e:
        print >> sys.stderr, "failed: Error reading %s - %s" % (options.input if options.input else 'stdin', e)
        exit(1)

if __name__ == "__main__":
    __main__()
