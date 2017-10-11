#!/usr/bin/env python
# -*- coding: utf-8 -*-

import sys
import os
import argparse
import re
import time

def extract_lines(input_content, column_id, extraction_type, extraction_nb):
    conserved_lines = []
    for line in input_content:
        split_line = line[:-1].split('\t')
        value = float(split_line[column_id])

        if len(conserved_lines) < extraction_nb:
            conserved_lines.append(split_line)
        else:
            best_pos = None
            #print value
            #print conserved_lines
            for i in range(len(conserved_lines)-1,-1,-1):
                compared_value = float(conserved_lines[i][column_id])
                if extraction_type(value, compared_value) == value:
                    print value, compared_value, extraction_type(value, compared_value)
                    best_pos = i
                else:
                    break
            if best_pos != None:
                print best_pos
                tmp_conserved_lines = conserved_lines
                conserved_lines = tmp_conserved_lines[:best_pos]
                conserved_lines += [split_line]
                conserved_lines += tmp_conserved_lines[best_pos:-1]
                print conserved_lines
                print 
    return conserved_lines

def extract_min_max_lines(args):
    if args.extraction_type == 'max':
        extraction_type = max
    elif args.extraction_type == 'min':
        extraction_type = min

    with open(args.input_file, 'r') as input_file:
        input_content = input_file.readlines()
        conserved_lines = extract_lines(input_content, args.column_id - 1, 
            extraction_type, args.extraction_nb)

    with open(args.output_file, 'w') as output_file:
        for line in conserved_lines:
            output_file.write('\t'.join(line) + "\n")

if __name__ == '__main__':
    parser = argparse.ArgumentParser()
    parser.add_argument('--input_file', required=True)
    parser.add_argument('--output_file', required=True)
    parser.add_argument('--column_id', required=True, type=int)
    parser.add_argument('--extraction_type', required=True, choices = ['min','max'])
    parser.add_argument('--extraction_nb', required=True, type=int)
    args = parser.parse_args()

    extract_min_max_lines(args)